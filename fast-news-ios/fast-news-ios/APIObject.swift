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
    
    // MARK: Internal initializiers
    
    required init(id: String?) {
        self.id = id
        super.init()
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
    class func typeName() -> String {
        return "<null>"
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
    
    static var apiRoot = "http://localhost:15080"
    
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
    
    // MARK: Convenience
    
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
        updated()
        loadingState = success ? .Loaded(startTime) : .Error(err)
        if _needsLoadAgain {
            _needsLoadAgain = false
            _loadNow()
        }
    }
    
    func updated() {
        onUpdate.push(self)
    }
    let onUpdate = Pusher<APIObject>()
}

class Transaction {
    init() {
        args["uid"] = "nate"
    }
    var endpoint: String!
    var method = "GET"
    var args = [String: String]()
    
    func start(callback: ((json: AnyObject?, error: NSError?, transaction: Transaction) -> ())?) {
        let urlString = pathWithArgs(endpoint, args: args)
        let req = NSMutableURLRequest(URL: NSURL(string: urlString)!)
        req.HTTPMethod = method
        print("\(req.HTTPMethod) \(req.URL!.absoluteString)")
        let task = NSURLSession.sharedSession().dataTaskWithRequest(req) { (let dataOpt, let responseOpt, let errorOpt) -> Void in
            if let cb = callback {
                if let data = dataOpt, let json = try? NSJSONSerialization.JSONObjectWithData(data, options: []) {
                    cb(json: json, error: nil, transaction: self)
                } else {
                    cb(json: nil, error: errorOpt, transaction: self)
                }
            }
        }
        task.resume()
    }
    
    // MARK: Convenience
    func pathWithArgs(path: String, args: [String: String]) -> String {
        let comps = NSURLComponents(string: APIObject.apiRoot + endpoint)!
        comps.queryItems = args.map({ NSURLQueryItem(name: $0.0, value: $0.1) })
        return comps.string!
    }
}
