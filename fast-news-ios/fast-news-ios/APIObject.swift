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
        _ObjectsLock.lock()
        let objectForID = {
            (id: String) -> APIObject in
            let fullID = typeName() + " " + id
            if let ref = _Objects[fullID], let existing = ref.obj {
                return existing
            } else {
                let obj = self.init(id: id)
                _Objects[fullID] = _WeakRef(obj: obj)
                return obj
            }
        }
        let objects = ids.map(objectForID)
        _ObjectsLock.unlock()
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
    
    // MARK: Internal initializiers
    
    required init(id: String?) {
        self.id = id
        super.init()
        if supportsRelevantTransactions {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "_transactionStarted:", name: Transaction.StartedNotification, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "_transactionFinished:", name: Transaction.FinishedNotification, object: nil)
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
    
    static var apiRoot = FN_USE_PRODUCTION ? "https://fast-news.appspot.com" : "http://localhost:15080"
    
    // MARK: For subclasses
    func importJson(json: [String: AnyObject]) {
        if let newID = json["id"] as? String where id == nil {
            // promote optimistic object to real object:
            id = newID
        }
    }
    
    func jsonPath() -> (String, [String: String]?)? {
        return nil // ("/articles", ["id": "aihrwfpier"])
    }
    
    // MARK: Loading
    enum LoadingState {
        case None
        case Loading(CFAbsoluteTime) // time started
        case Error(NSError?)
        case Loaded(CFAbsoluteTime)
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
        case .Loaded(let loadedAt) where loadedAt >= CFAbsoluteTimeGetCurrent() - recency:
            () // recent enough
        default:
            // load now:
            _loadNow()
        }
    }
    
    func reloadImmediately() {
        switch loadingState {
        case .Loading(_):
            _needsLoadAgain = true
        default:
            // load now:
            _loadNow()
        }
    }

    func _loadNow() {
        let startTime = CFAbsoluteTimeGetCurrent()
        loadingState = .Loading(startTime)
        
        let t = Transaction()
        let (endpoint, argsOpt) = jsonPath()!
        t.endpoint = endpoint
        for (k,v) in argsOpt ?? [String: String]() {
            t.args[k] = v
        }
        t.start { (json, error, transaction) -> () in
            if let dict = json as? [String: AnyObject] {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.importJson(dict)
                    self._loadFinished(true, startTime: startTime, err: nil)
                })
            } else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self._loadFinished(false, startTime: startTime, err: error)
                })
            }
        }
    }
    
    func _loadFinished(success: Bool, startTime: CFAbsoluteTime, err: NSError?) {
        _relevantTransactionsFinished.removeAll()
        updated()
        loadingState = success ? .Loaded(startTime) : .Error(err)
        if _needsLoadAgain {
            _needsLoadAgain = false
            _loadNow()
        }
    }
    
    func updated() {
        mainThread { () -> Void in
            self.onUpdate.push(self)
        }
    }
    let onUpdate = Pusher<APIObject>()
    
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
            return _relevantTransactionsInProgress + _relevantTransactionsFinished
        }
    }
    func transactionIsRelevant(t: Transaction) -> Bool {
        return false
    }
    func _transactionStarted(notif: NSNotification) {
        if transactionIsRelevant(notif.object as! Transaction) {
            _relevantTransactionsInProgress.insert(notif.object as! Transaction, atIndex: 0)
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
                _relevantTransactionsFinished.insert(t, atIndex: 0)
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
    
    var finished = false
    var failed = false
    
    func start(callback: ((json: AnyObject?, error: NSError?, transaction: Transaction) -> ())?) {
        self.dynamicType._StartedInProgressTransaction(self)
        let urlString = pathWithArgs(endpoint, args: args)
        let req = NSMutableURLRequest(URL: NSURL(string: urlString)!)
        req.HTTPMethod = method
        print("\(req.HTTPMethod) \(req.URL!.absoluteString): START")
        let task = NSURLSession.sharedSession().dataTaskWithRequest(req) { (let dataOpt, let responseOpt, let errorOpt) -> Void in
            
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
