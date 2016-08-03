//
//  SourceSearch.swift
//  fast-news-ios
//
//  Created by n8 on 8/3/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation

class SourceSearch: APIObject {
    override func jsonPath() -> (String, [String : String]?)? {
        return ("/sources/featured", nil)
    }
    
    override class func typeName() -> String {
        return "featuredSources"
    }
    
    override func _mockRequest(t: Transaction) -> [String: AnyObject]? {
        return _loadMockJson("SourceSearch")
    }
}
