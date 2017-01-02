//
//  OfflineBookmarksFetcher.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 1/2/17.
//  Copyright © 2017 Nate Parrott. All rights reserved.
//

import Foundation

class OfflineBookmarksFetcher {
    static let Shared = OfflineBookmarksFetcher()
    
    init() {
        queue.maxConcurrentOperationCount = 1
        self.log("Offline bookmarks cache is at \(cache._cacheURL)")
    }
    
    let queue = NSOperationQueue()
    let cache = Cache(name: "OfflineBookmarkContents")
    var bookmarksFetchQueue = [Bookmark]()
    
    func cacheBookmarksOffline(bookmarks: [Bookmark]) {
        queue.addOperationWithBlock {
            let alreadyEnqueued = Set(self.bookmarksFetchQueue.map({$0.id ?? ""}))
            self.bookmarksFetchQueue += bookmarks.filter({ self.shouldDownloadBookmark($0) && !alreadyEnqueued.contains($0.id ?? "") })
            self.processFetchQueue()
        }
    }
    
    func loadBookmarkContentFromOfflineCache(bookmark: Bookmark) {
        if let article = bookmark.article where article.content == nil && article.id != nil {
            if let key = bookmark.offlineCacheKey {
                if let content = cache.get(key) {
                    article.importJson(content)
                }
            }
        }
    }
    
    var _processingFetchQueue = false
    func processFetchQueue() {
        queue.addOperationWithBlock { 
            if self._processingFetchQueue {
                return
            }
            
            if self.bookmarksFetchQueue.count == 0 {
                self.log("Done fetching bookmarks")
                return
            }
            
            self._processingFetchQueue = true
            
            let batchSize = min(self.bookmarksFetchQueue.count, 5)
            let bookmarksToFetch = Array(self.bookmarksFetchQueue[0..<batchSize])
            self.bookmarksFetchQueue.removeFirst(batchSize)
            
            let ids = bookmarksToFetch.map({ $0.article!.id! })
            self.log("Trying to download articles: \(ids)")
            
            self.tryDownloadingBatch(bookmarksToFetch, successCallback: { (let success) in
                // this callback should already come on the right queue
                self._processingFetchQueue = false
                if (success) {
                    self.log("Successfully downloaded articles")
                    self.processFetchQueue()
                } else {
                    self.log("Failed to download articles")
                }

            })
        }
    }
    
    func shouldDownloadBookmark(bookmark: Bookmark) -> Bool {
        let bookmarkShouldBeDownloaded = bookmark.article != nil && bookmark.article!.fetchFailed == false
        if bookmarkShouldBeDownloaded, let cacheKey = bookmark.offlineCacheKey {
            let bookmarkWasAlreadyDownloaded = cache.exists(cacheKey)
            if !bookmarkWasAlreadyDownloaded {
                return true
            }
        }
        return false
    }
    
    func tryDownloadingBatch(bookmarks: [Bookmark], successCallback: (Bool) -> ()) {
        let t = Transaction()
        let ids = bookmarks.map({ $0.article!.id! })
        t.endpoint = "/bulk_articles"
        t.args["ids"] = String.fromJson(ids)!
        t.start { (let json, let error, let transaction) in
            self.queue.addOperationWithBlock({ 
                if let results = json as? [String: AnyObject] {
                    for bookmark in bookmarks {
                        if let id = bookmark.article?.id, let key = bookmark.offlineCacheKey {
                            if let content = results[id] as? [String: AnyObject] {
                                self.log("Got content for \(bookmark.article!.id!)")
                                self.cache.set(key, item: content)
                            } else {
                                self.log("Got no content for \(bookmark.article!.id!)")
                                self.cache.set(key, item: [String: AnyObject]())
                            }
                        }
                    }
                    successCallback(true)
                } else {
                    successCallback(false)
                }
            })
        }
    }
    
    func log(text: String) {
        print(text)
    }
}
