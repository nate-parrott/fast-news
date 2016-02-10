//
//  Subscription.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/6/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation

class SourceSubscription: APIObject {
    var source: Source?
    override func importJson(json: [String : AnyObject]) {
        super.importJson(json)
        if let sourceJson = json["source"] as? [String: AnyObject], let id = sourceJson["id"] as? String {
            let sourceObj = Source.objectsForIDs([id]).first! as! Source
            sourceObj.importJson(sourceJson)
            self.source = sourceObj
        }
    }
    
    override class func typeName() -> String {
        return "subscription"
    }
}
