//
//  SourceSearch.swift
//  fast-news-ios
//
//  Created by n8 on 8/3/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation

class SourceSearch: APIObject {
    var sources: [Source]?
    
    override func jsonPath() -> (String, [String : String]?)? {
        if let id = self.id {
            return ("/sources/search", ["query": id])
        } else {
            return nil
        }
    }
    
    override func importJson(json: [String : AnyObject]) {
        super.importJson(json)
        if let results = json["results"] as? [String: AnyObject],
           let sources = results["sources"] as? [[String: AnyObject]] {
            self.sources = APIObjectsFromDictionaries(sources)
        }
    }
    
    override class func typeName() -> String {
        return "featuredSources"
    }
    
    override func _mockRequest(t: Transaction) -> [String: AnyObject]? {
        return nil
        // return _loadMockJson("SourceSearch")
    }
}

class SourceSearchManager {
    let sources = Observable<[Source]>(val: [])
    var query = "" {
        didSet(old) {
            if query != old {
                if _currentQuery == nil {
                    _search(query)
                }
            }
        }
    }
    
    var _currentQuery: String?
    var _currentSearch: SourceSearch?
    var _currentSearchSub: Subscription?
    func _search(query: String) {
        _currentQuery = query
        let s = SourceSearch(id: query)
        _currentSearch = s
        _currentSearchSub = s.onUpdate.subscribe { (_) in
            var done: Bool
            switch s.loadingState {
            case .Error(_): done = true
            case .Loaded(_, _): done = true
            default: done = false
            }
            if done {
                self._currentSearch = nil
                self._currentSearchSub = nil
                self._currentQuery = nil
                self.sources.val = s.sources ?? []
                if query != self.query {
                    self._search(self.query)
                }
            }
        }
        s.reloadImmediately()
    }
}
