//
//  Models.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/4/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation

func APIObjectsFromDictionaries<T:APIObject>(dicts: [[String: AnyObject]]) -> [T] {
    let dictsWithIDs = dicts.filter({ $0["id"] as? String != nil })
    let IDs = dictsWithIDs.map({ $0["id"] as! String })
    let objects = T.objectsForIDs(IDs) as! [T]
    for (json, object) in zip(dictsWithIDs, objects) {
        object.importJson(json)
    }
    return objects
}

class APIObject: NSObject {
    // MARK: External initializers
    class func objectsForIDs(ids: [String]) -> [APIObject] {
        var objectsNeedingSetup = [APIObject]()
        _ObjectsLock.lock()
        let objectForID = {
            (id: String) -> APIObject in
            let fullID = typeName() + " " + id
            if let ref = _Objects[fullID], let existing = ref.obj {
                return existing
            } else {
                let obj = self.init(id: id)
                objectsNeedingSetup.append(obj)
                _Objects[fullID] = _WeakRef(obj: obj)
                return obj
            }
        }
        let objects = ids.map(objectForID)
        _ObjectsLock.unlock()
        for obj in objectsNeedingSetup { obj.setup() }
        return objects
    }
    
    class func objectForID(id: String) -> APIObject {
        return objectsForIDs([id]).first!
    }
    
    class func optimisticObject() -> APIObject {
        return self.init(id: nil)
    }
    
    class func typeName() -> String! {
        return nil
    }
    
    // MARK: Cursors
    
    var cursorClass: LoadCursor.Type {
        get {
            return LoadCursor.self
        }
    }
    
    // MARK: Internal initializiers
    
    required init(id: String?) {
        self.id = id
        super.init()
        if supportsRelevantTransactions {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(APIObject._transactionStarted(_:)), name: Transaction.StartedNotification, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(APIObject._transactionFinished(_:)), name: Transaction.FinishedNotification, object: nil)
        }
    }
    private(set) var id: String? {
        didSet {
            if let fid = _fullID {
                APIObject._ObjectsLock.lock()
                APIObject._Objects[fid] = _WeakRef(obj: self)
                APIObject._ObjectsLock.unlock()
            }
        }
    }
    
    func setup() {
        // use the setup() function for initializing other associated APIObjects;
        // this can't happen inside the constructor itself because a global lock
        // is being held (see objectsForIDs...)
    }
    
    var _fullID: _FullID? {
        get {
            if let id = self.id {
                return self.dynamicType.typeName() + " " + id
            } else {
                return nil
            }
        }
    }
    deinit {
        if let fid = _fullID {
            APIObject._ObjectsLock.lock()
            APIObject._Objects.removeValueForKey(fid)
            APIObject._ObjectsLock.unlock()
        }
    }
    struct _WeakRef {
        weak var obj: APIObject?
    }
    
    typealias _FullID = String
    static var _Objects = [_FullID: _WeakRef]()
    static var _ObjectsLock = NSLock()
    
    static var apiRoot = FN_USE_PRODUCTION ? "https://fast-news.appspot.com" : "http://localhost:8080"
    
    // MARK: For subclasses
    func importJson(json: [String: AnyObject]) {
        if let newID = json["id"] as? String where id == nil {
            // promote optimistic object to real object:
            id = newID
        }
    }
    
    func appendJson(json: [String: AnyObject], cursor: LoadCursor) {
        fatalError("Attempted to append json to an object that doesn't support it (\(self))")
    }
    
    func jsonPath() -> (String, [String: String]?)? {
        return nil // ("/articles", ["id": "aihrwfpier"])
    }
    
    func toJson() -> [String: AnyObject]! {
        return nil
    }
    
    // MARK: Loading
    enum LoadingState {
        case None
        case Loading(CFAbsoluteTime) // time started
        case Error(NSError?)
        case Loaded(CFAbsoluteTime, LoadCursor)
    }
    var _needsLoadAgain = false
    var loadingState = LoadingState.None {
        didSet(val) {
            updated()
        }
    }
    
    func ensureRecency(recency: CFAbsoluteTime) {
        switch loadingState {
        case .Loading(let started):
            if started < CFAbsoluteTimeGetCurrent() - recency {
                _needsLoadAgain = true
            }
        case .Loaded(let loadedAt, _) where loadedAt >= CFAbsoluteTimeGetCurrent() - recency:
            () // recent enough
        default:
            // load now:
            _loadNow(cursorClass.Initial(), append: false)
        }
    }
    
    func reloadImmediately() {
        switch loadingState {
        case .Loading(_):
            _needsLoadAgain = true
        default:
            // load now:
            _loadNow(cursorClass.Initial(), append: false)
        }
    }
    
    func nextPage() {
        switch loadingState {
        case .Loaded(_, let cursor):
            if let newCursor = cursor.advance() {
                _loadNow(newCursor, append: true)
            }
        default: ()
        }
    }

    func _loadNow(cursor: LoadCursor, append: Bool) {
        
        let startTime = CFAbsoluteTimeGetCurrent()
        loadingState = .Loading(startTime)
        
        let t = Transaction()
        t.timeout = requestTimeout
        let (endpoint, argsOpt) = jsonPath()!
        t.endpoint = endpoint
        for (k,v) in argsOpt ?? [String: String]() {
            t.args[k] = v
        }
        for (k,v) in cursor.URLParams() {
            t.args[k] = v
        }
        t.start { (json, error, transaction) -> () in
            if let dict = json as? [String: AnyObject] {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    cursor.receiveTransactionResult(dict)
                    if append {
                        self.appendJson(dict, cursor: cursor)
                    } else {
                        self.importJson(dict)
                    }
                    self._loadFinished(true, cursor: cursor, startTime: startTime, err: nil)
                })
            } else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self._loadFinished(false, cursor: cursor, startTime: startTime, err: error)
                })
            }
        }
    }
    
    func _loadFinished(success: Bool, cursor: LoadCursor, startTime: CFAbsoluteTime, err: NSError?) {
        _relevantTransactionsFinished.removeAll()
        updated()
        loadingState = success ? .Loaded(startTime, cursor) : .Error(err)
        if _needsLoadAgain {
            _needsLoadAgain = false
            _loadNow(cursorClass.Initial(), append: false)
        }
    }
    
    func updated() {
        mainThread { () -> Void in
            self.onUpdate.push(self)
        }
    }
    let onUpdate = Pusher<APIObject>()
    
    var requestTimeout: NSTimeInterval {
        get {
            return 20
        }
    }
    
    // MARK: Relevant Transactions
    var supportsRelevantTransactions: Bool {
        get {
            return false
        }
    }
    var _relevantTransactionsInProgress = [Transaction]()
    var _relevantTransactionsFinished = [Transaction]()
    var relevantTransactions: [Transaction] {
        get {
            return _relevantTransactionsFinished + _relevantTransactionsInProgress
        }
    }
    func transactionIsRelevant(t: Transaction) -> Bool {
        return false
    }
    func _transactionStarted(notif: NSNotification) {
        if transactionIsRelevant(notif.object as! Transaction) {
            _relevantTransactionsInProgress.append(notif.object as! Transaction)
            updated()
        }
    }
    func _transactionFinished(notif: NSNotification) {
        let t = notif.object as! Transaction
        if transactionIsRelevant(t) {
            if let i = _relevantTransactionsInProgress.indexOf({ $0 === t }) {
                _relevantTransactionsInProgress.removeAtIndex(i)
            }
            if !t.failed {
                _relevantTransactionsFinished.append(t)
            }
            updated()
        }
    }
}

class Transaction {
    init() {
        args["uid"] = APIIdentity.Shared.id
    }
    var endpoint: String!
    var method = "GET"
    var args = [String: String]()
    var timeout: NSTimeInterval?
    
    var finished = false
    var failed = false
    
    func start(callback: ((json: AnyObject?, error: NSError?, transaction: Transaction) -> ())?) {
        self.dynamicType._StartedInProgressTransaction(self)
        let urlString = pathWithArgs(endpoint, args: args)
        let req = NSMutableURLRequest(URL: NSURL(string: urlString)!)
        req.HTTPMethod = method
        print("\(req.HTTPMethod) \(req.URL!.absoluteString): START")
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        if let t = timeout {
            configuration.timeoutIntervalForRequest = t
        }
        let session = NSURLSession(configuration: configuration)
        
        let task = session.dataTaskWithRequest(req) { (let dataOpt, let responseOpt, let errorOpt) -> Void in
            
            var info = dataOpt?.description ?? responseOpt?.description ?? "nothing"
            if let data = dataOpt {
                info = "\(data.length) bytes"
            }
            print("\(req.HTTPMethod) \(req.URL!.absoluteString): \(info)")
            
            if let cb = callback {
                if let data = dataOpt, let json = try? NSJSONSerialization.JSONObjectWithData(data, options: []) {
                    mainThread({ () -> Void in
                        cb(json: json, error: nil, transaction: self)
                    })
                } else {
                    self.failed = true
                    mainThread({ () -> Void in
                        cb(json: nil, error: errorOpt, transaction: self)
                    })
                }
            }
            
            self.finished = true
            self.dynamicType._FinishedInProgressTransaction(self)
        }
        task.resume()
    }
    
    // MARK: Convenience
    func pathWithArgs(path: String, args: [String: String]) -> String {
        let comps = NSURLComponents(string: APIObject.apiRoot + endpoint)!
        comps.queryItems = args.map({ NSURLQueryItem(name: $0.0, value: $0.1) })
        return comps.string!
    }
    
    // MARK: In-progress tracking
    static let StartedNotification = "APIObject.TransactionStartedNotification"
    static let FinishedNotification = "APIObject.TransactionFinishedNotification"
    
    class func _StartedInProgressTransaction(t: Transaction) {
        mainThread { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName(StartedNotification, object: t)
        }
    }
    
    class func _FinishedInProgressTransaction(t: Transaction) {
        mainThread { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName(FinishedNotification, object: t)
        }
    }
}

class LoadCursor {
    class func Initial() -> LoadCursor {
        return LoadCursor()
    }
    func advance() -> LoadCursor? {
        return nil
    }
    func URLParams() -> [String: String] {
        return [String: String]()
    }
    func receiveTransactionResult(result: [String: AnyObject]) {
        
    }
}

class PagingCursor: LoadCursor {
    class override func Initial() -> LoadCursor {
        return PagingCursor(offset: 0)
    }
    init(offset: Int) {
        self.offset = offset
    }
    let offset: Int
    var pagesRemaining = true
    var limit: Int {
        get {
            return 20
        }
    }
    override func advance() -> LoadCursor? {
        return PagingCursor(offset: offset + limit)
    }
    override func URLParams() -> [String : String] {
        var p = super.URLParams()
        p["offset"] = "\(offset)"
        p["limit"] = "\(limit)"
        return p
    }
    override func receiveTransactionResult(result: [String: AnyObject]) {
        super.receiveTransactionResult(result)
        if let rem = result["pagesRemaining"] as? Bool {
            pagesRemaining = rem
        }
    }
}
