//
//  BookmarkList.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 3/4/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation

class BookmarkList: APIObject {
    required init(id: String?) {
        super.init(id: id)
    }
    var _bookmarkTransactionSub: Subscription?
    var _bookmarkTransactionCompletedSub: Subscription?
    
    override func jsonPath() -> (String, [String : String]?)? {
        return ("/bookmarks", nil)
    }
    
    override class func typeName() -> String {
        return "bookmarkList"
    }
    
    override func importJson(json: [String : AnyObject]) {
        super.importJson(json)
        if let bookmarksJson = json["bookmarks"] as? [[String: AnyObject]] {
            bookmarks = APIObjectsFromDictionaries(bookmarksJson)
        }
        _optimisticDeletedBookmarkURLs.removeAll()
        _optimisticAddedBookmarks.removeAll()
    }
    
    var bookmarks: [Bookmark]?
    
    var _optimisticDeletedBookmarkURLs = Set<String>()
    var _optimisticAddedBookmarks = [Bookmark]()
    
    var optimisticBookmarks: [Bookmark] {
        var bookmarks = self.bookmarks ?? []
        var deleted = _optimisticDeletedBookmarkURLs
        var added = _optimisticAddedBookmarks
        for t in UpdateBookmarkTransaction.InProgress().val {
            
        }
    }
}

class Bookmark: APIObject {
    var article: Article?
    var readingPosition: AnyObject?
    var modified: NSDate?
    
    override func importJson(json: [String : AnyObject]) {
        super.importJson(json)
        if let pos = json["readingPosition"] {
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
    
    override class func typeName() -> String {
        return "bookmark"
    }
}

class UpdateBookmarkTransaction: Transaction {
    var article: Article?
    var articleURL: NSURL?
    var readingPosition: AnyObject?
    var delete = false
    var optimisticBookmark: Bookmark?
    
    func start() {
        if let a = article {
            args["article_id"] = a.id
        } else if let url = articleURL {
            args["article_url"] = url.absoluteString
        }
        method = delete ? "DELETE" : "POST"
        endpoint = "/bookmarks"
        
        if !delete {
            let opt = Bookmark(id: nil)
            opt.article = article
            opt.readingPosition = readingPosition
            optimisticBookmark = opt
        }
        
        start { (json, error, transaction) -> () in
            if self.delete {
                self.failed = (json == nil)
            } else {
                if let bookmarkJson = json?["bookmark"] as? [String: AnyObject] {
                    self.optimisticBookmark?.importJson(bookmarkJson)
                } else {
                    self.failed = true
                }
            }
        }
    }
}
