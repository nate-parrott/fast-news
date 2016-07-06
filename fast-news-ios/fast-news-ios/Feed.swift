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
    
    override func appendJson(json: [String : AnyObject], cursor: LoadCursor) {
        if (cursor as! FeedCursor).offset == 0 {
            importJson(json)
        } else {
            if let sources = json["sources"] as? [[String: AnyObject]] {
                self.sources = (self.sources ?? []) + APIObjectsFromDictionaries(sources)
            }
        }
    }
    
    override func jsonPath() -> (String, [String : String]?)? {
        return ("/feed", nil)
    }
    
    override class func typeName() -> String {
        return "feed"
    }
    
    override var cursorClass: LoadCursor.Type {
        get {
            return FeedCursor.self
        }
    }
}

class FeedCursor: PagingCursor {
    var articleLimit = 10
    class override func Initial() -> LoadCursor {
        let c = FeedCursor(offset: 0)
        c.articleLimit = 1
        return c
    }
    override func advance() -> LoadCursor? {
        if articleLimit == 1 {
            return FeedCursor(offset: 0)
        } else {
            return super.advance()
        }
    }
    override func URLParams() -> [String : String] {
        var p = super.URLParams()
        p["article_limit"] = "\(articleLimit)"
        return p
    }
}
