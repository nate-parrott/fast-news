//
//  FeaturedSources.swift
//  fast-news-ios
//
//  Created by n8 on 8/3/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation

class FeaturedSources: APIObject {
    var categories: [FeaturedSourcesCategory]?
    
    override func importJson(json: [String : AnyObject]) {
        super.importJson(json)
        if let categories = json["categories"] as? [[String: AnyObject]] {
            self.categories = APIObjectsFromDictionaries(categories)
        }
    }
    
    override func jsonPath() -> (String, [String : String]?)? {
        return ("/sources/featured", nil)
    }
    
    override class func typeName() -> String {
        return "featuredSources"
    }
    
    override func _mockRequest(t: Transaction) -> [String: AnyObject]? {
        return _loadMockJson("FeaturedSources")
    }
}

class FeaturedSourcesCategory: APIObject {
    var name: String?
    var sources: [Source]?
    
    override func jsonPath() -> (String, [String : String]?)? {
        if let id = self.id {
            return ("/sources/featured", ["category": id])
        } else {
            return nil
        }
    }
    
    override class func typeName() -> String {
        return "featuredSourcesCategory"
    }
    
    override func importJson(json: [String : AnyObject]) {
        super.importJson(json)
        if let name = json["name"] as? String {
            self.name = name
        }
        if let sources = json["sources"] as? [[String: AnyObject]] {
            self.sources = APIObjectsFromDictionaries(sources)
        }
    }
}
