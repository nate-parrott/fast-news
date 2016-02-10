//
//  Article.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/4/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation

class Article: APIObject {
    var title: String?
    var text: String?
    override func importJson(json: [String : AnyObject]) {
        super.importJson(json)
        self.title = json["title"] as? String ?? self.title
        self.text = json["article_text"] as? String ?? self.text
    }
    
    override func jsonPath() -> (String, [String : String]?)? {
        if let id = self.id {
            return ("/artices", ["id": id])
        } else {
            return nil
        }
    }
    
    override class func typeName() -> String {
        return "article"
    }
}
