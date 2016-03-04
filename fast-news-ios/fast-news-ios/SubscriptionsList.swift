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
    init(url: String) {
        // add optimistic data models:
        optimisticSource = Source.optimisticObject() as! Source
        optimisticSource.title = url
        optimisticSource.url = url
        optimisticSub = SourceSubscription(id: nil)
        optimisticSub.source = optimisticSource
        
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
    
    override class func Name() -> String {
        return "AddSubscriptionTransaction"
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
    override class func Name() -> String {
        return "DeleteSubscriptionTransaction"
    }
}
