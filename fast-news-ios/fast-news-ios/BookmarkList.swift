//
//  BookmarkList.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 3/4/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation

class BookmarkList: APIObject, Cacheable {
    class var Shared: BookmarkList {
        get {
            return BookmarkList.objectForID("bookmarks") as! BookmarkList
        }
    }
    
    override func setup() {
        super.setup()
        Cache.Shared.registerObjectAsCacheable(self)
    }
    
    override func jsonPath() -> (String, [String : String]?)? {
        var args = [String: String]()
        if let s = since { args["since"] = "\(s)" }
        return ("/bookmarks", args)
    }
    
    override class func typeName() -> String! {
        return "BookmarkList"
    }
    
    override func importJson(json: [String : AnyObject]) {
        super.importJson(json)
        var newBookmarks = [Bookmark]()
        if let bookmarksJson = json["bookmarks"] as? [[String: AnyObject]] {
            newBookmarks = APIObjectsFromDictionaries(bookmarksJson)
        }
        let partial = json["partial"] as? Bool ?? false
        if partial {
            var allBookmarks = [Bookmark]()
            var seenBookmarkIDs = Set<String>()
            // keep only the most recent copy of each bookmark:
            for bk in newBookmarks + (bookmarks ?? []) {
                if let id = bk.id where !seenBookmarkIDs.contains(id) {
                    allBookmarks.append(bk)
                    seenBookmarkIDs.insert(id)
                }
            }
            bookmarks = allBookmarks.filter({ !$0.deleted })
            print("fetched \(newBookmarks.count) new bookmarks, storing total \(bookmarks!.count)")
        } else {
            bookmarks = newBookmarks
            print("did not do a partial bookmark transaction")
        }
        since = json["since"] as? Double
    }
    
    var bookmarks: [Bookmark]?
    var since: Double?
    
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
    
    override func toJson() -> [String : AnyObject]! {
        return ["since": since ?? NSNull(), "bookmarks": bookmarks?.map({ $0.toJson() }) ?? NSNull()]
    }
    
    // MARK: Caching
    func cacheJson() -> [String: AnyObject] {
        return toJson()
    }
    func importCacheJson(json: [String: AnyObject]) {
        importJson(json)
        print("Loaded \(bookmarks?.count ?? 0) articles from the cache")
    }
    var cacheKey: String? { return "BookmarkList" }
    var versionKey: String? { return nil }
}

class Bookmark: APIObject {
    var article: Article?
    var readingPosition: AnyObject?
    var modified: NSDate?
    var deleted = false
    
    override func importJson(json: [String : AnyObject]) {
        super.importJson(json)
        if let pos = json["reading_position"] {
            readingPosition = pos
        }
        if let lastModified = json["last_modified"] as? Double {
            modified = NSDate(timeIntervalSince1970: lastModified)
        }
        if let d = json["deleted"] as? Bool {
            deleted = d
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
    
    override func toJson() -> [String : AnyObject]! {
        return ["article": article?.toJson() ?? NSNull(), "reading_position": readingPosition ?? NSNull(), "last_modified": modified?.timeIntervalSince1970 ?? NSNull(), "deleted": deleted, "id": self.id ?? NSNull()]
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
