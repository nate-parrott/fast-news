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
    
    override class func typeName() -> String! {
        return "SubscriptionsList"
    }
    
    var subscriptionsIncludingOptimistic: [SourceSubscription] {
        get {
            var subs = subscriptions ?? []
            for t in relevantTransactions {
                if let dt = t as? DeleteSubscriptionTransaction {
                    subs = subs.filter({ $0.source?.url != dt.url })
                } else if let at = t as? AddSubscriptionTransaction {
                    subs.insert(at.optimisticSub, atIndex: 0)
                }
            }
            return subs
        }
    }
    
    // MARK: Relevant transactions
    override var supportsRelevantTransactions: Bool {
        get {
            return true
        }
    }
    override func transactionIsRelevant(t: Transaction) -> Bool {
        return (t as? AddSubscriptionTransaction) != nil || (t as? DeleteSubscriptionTransaction) != nil
    }
}

class AddSubscriptionTransaction: Transaction {
    init(url: String) {
        // add optimistic data models:
        optimisticSource = Source.optimisticObject() as! Source
        optimisticSource.title = url
        optimisticSource.url = url
        optimisticSub = SourceSubscription(id: nil)
        optimisticSub.source = optimisticSource
        
        statusItem = StatusItem(title: "Subscribing to \(url)")
        statusItem.add()
        
        super.init()
        
        args["url"] = url
        method = "POST"
        endpoint = "/subscriptions/add"
    }
    let optimisticSub: SourceSubscription
    let optimisticSource: Source
    let statusItem: StatusItem
    
    func start(callback: (success: Bool) -> ()) {
        start { (json, error, transaction) -> () in
            self.statusItem.remove()
            if let resp = json as? [String: AnyObject], let sub = resp["subscription"] as? [String: AnyObject], let source = resp["source"] as? [String: AnyObject] {
                self.optimisticSub.importJson(sub)
                self.optimisticSub.updated()
                self.optimisticSource.importJson(source)
                self.optimisticSource.updated()
                callback(success: true)
                let feed = Feed.objectsForIDs(["shared"]).first! as! Feed
                feed.reloadImmediately()
            } else {
                self.failed = true
                callback(success: false)
            }
        }
    }
}

class DeleteSubscriptionTransaction: Transaction {
    init(url: String) {
        self.url = url
        
        super.init()
        
        method = "DELETE"
        args["url"] = url
        endpoint = "/subscriptions/delete"
    }
    var url: String
    func start(callback: (success: Bool) -> ()) {
        start { (json, error, transaction) -> () in
            callback(success: json?["success"] as? Bool ?? false)
        }
    }
}
