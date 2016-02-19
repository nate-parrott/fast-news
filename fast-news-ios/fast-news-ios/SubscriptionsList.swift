//
//  Subscriptions.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/6/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation

class SubscriptionsList: APIObject {
    var subscriptions: [SourceSubscription]?
    override func importJson(json: [String : AnyObject]) {
        super.importJson(json)
        if let subs = json["subscriptions"] as? [[String: AnyObject]] {
            self.subscriptions = APIObjectsFromDictionaries(subs)
        }
    }
    
    override func jsonPath() -> (String, [String : String]?)? {
        return ("/subscriptions", nil)
    }
    
    override class func typeName() -> String {
        return "subscriptionsList"
    }
}

class AddSubscriptionTransaction: Transaction {
    init(url: String, list: SubscriptionsList?, feed: Feed?) {
        // add optimistic data models:
        optimisticSource = Source.optimisticObject() as! Source
        optimisticSource.title = url
        optimisticSource.url = url
        optimisticSub = SourceSubscription(id: nil)
        optimisticSub.source = optimisticSource
        if let f = feed {
            f.sources = [optimisticSource] + (f.sources ?? [])
            f.updated()
        }
        if let l = list {
            l.subscriptions = [optimisticSub] + (l.subscriptions ?? [])
            l.updated()
        }
        
        super.init()
        
        args["url"] = url
        method = "POST"
        endpoint = "/subscriptions/add"
    }
    let optimisticSub: SourceSubscription
    let optimisticSource: Source
    
    func start(callback: (success: Bool) -> ()) {
        start { (json, error, transaction) -> () in
            if let resp = json as? [String: AnyObject], let sub = resp["subscription"] as? [String: AnyObject], let source = resp["source"] as? [String: AnyObject] {
                self.optimisticSub.importJson(sub)
                self.optimisticSub.updated()
                self.optimisticSource.importJson(source)
                self.optimisticSource.updated()
                callback(success: true)
            } else {
                callback(success: false)
            }
        }
    }
}

class DeleteSubscriptionTransaction: Transaction {
    init(url: String, list: SubscriptionsList?, feed: Feed?) {
        if let l = list, let subs = l.subscriptions {
            l.subscriptions = subs.filter({ $0.source?.url != url })
            l.updated()
        }
        
        if let f = feed, let sources = f.sources {
            f.sources = sources.filter({ $0.url != url })
            f.updated()
        }
        
        super.init()
        
        method = "DELETE"
        args["url"] = url
        endpoint = "/subscriptions/delete"
    }
    func start(callback: (success: Bool) -> ()) {
        start { (json, error, transaction) -> () in
            callback(success: json?["success"] as? Bool ?? false)
        }
    }
}
