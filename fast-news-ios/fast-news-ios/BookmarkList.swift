//
//  BookmarkList.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 3/4/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation

class BookmarkList: APIObject {
    class var Shared: BookmarkList {
        get {
            return BookmarkList.objectForID("bookmarks") as! BookmarkList
        }
    }
    
    override func jsonPath() -> (String, [String : String]?)? {
        return ("/bookmarks", nil)
    }
    
    override class func typeName() -> String! {
        return "BookmarkList"
    }
    
    override func importJson(json: [String : AnyObject]) {
        super.importJson(json)
        if let bookmarksJson = json["bookmarks"] as? [[String: AnyObject]] {
            bookmarks = APIObjectsFromDictionaries(bookmarksJson)
        }
    }
    
    var bookmarks: [Bookmark]?
    
    override var supportsRelevantTransactions: Bool {
        get {
            return true
        }
    }
    
    override func transactionIsRelevant(t: Transaction) -> Bool {
        return (t as? UpdateBookmarkTransaction) != nil
    }
    
    var bookmarksIncludingOptimistic: [Bookmark] {
        get {
            var bookmarks = self.bookmarks ?? []
            for t in relevantTransactions as! [UpdateBookmarkTransaction] {
                if t.delete {
                    bookmarks = bookmarks.filter({ $0.article?.id != t.article?.id })
                } else if let bookmark = t.bookmark {
                    if bookmarks.indexOf(bookmark) == nil {
                        bookmarks.insert(bookmark, atIndex: 0)
                    }
                }
            }
            let now = NSDate()
            return bookmarks.sort({ ($0.modified ?? now).compare($1.modified ?? now) == .OrderedDescending })
        }
    }
}

class Bookmark: APIObject {
    var article: Article?
    var readingPosition: AnyObject?
    var modified: NSDate?
    
    override func importJson(json: [String : AnyObject]) {
        super.importJson(json)
        if let pos = json["reading_position"] {
            readingPosition = pos
        }
        if let lastModified = json["last_modified"] as? Double {
            modified = NSDate(timeIntervalSince1970: lastModified)
        }
        if let articleJson = json["article"] as? [String: AnyObject],
           let articleID = articleJson["id"] as? String {
            article = (Article.objectForID(articleID) as! Article)
            article!.importJson(articleJson)
        } else if let articleID = json["article_id"] as? String {
            article = (Article.objectForID(articleID) as! Article)
        }
    }
    
    override class func typeName() -> String! {
        return "Bookmark"
    }
}

class UpdateBookmarkTransaction: Transaction {
    var article: Article?
    var articleURL: NSURL?
    var readingPosition: AnyObject?
    var delete = false
    var bookmark: Bookmark? // will be CREATED if necessary
    
    func start() {
        if let a = article {
            args["article_id"] = a.id
        } else if let url = articleURL {
            args["article_url"] = url.absoluteString
        }
        method = delete ? "DELETE" : "POST"
        endpoint = "/bookmarks"
        if let p = readingPosition {
            args["reading_position"] = NSString(data: try! NSJSONSerialization.dataWithJSONObject(p, options: []), encoding: NSUTF8StringEncoding)! as String
        }
        
        if !delete {
            let b = bookmark ?? Bookmark(id: nil)
            b.article = article
            b.modified = NSDate()
            b.readingPosition = readingPosition
            bookmark = b
        }
        
        start { (json, error, transaction) -> () in
            if self.delete {
                self.failed = (json == nil)
            } else {
                if let bookmarkJson = json?["bookmark"] as? [String: AnyObject] {
                    self.bookmark?.importJson(bookmarkJson)
                } else {
                    self.failed = true
                }
            }
        }
    }
}
