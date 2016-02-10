//
//  Feed.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/4/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation

class Feed: APIObject {
    var sources: [Source]?
    override func importJson(json: [String : AnyObject]) {
        super.importJson(json)
        if let sources = json["sources"] as? [[String: AnyObject]] {
            self.sources = APIObjectsFromDictionaries(sources)
        }
    }
    
    override func jsonPath() -> (String, [String : String]?)? {
        return ("/feed", nil)
    }
    
    override class func typeName() -> String {
        return "feed"
    }
}
