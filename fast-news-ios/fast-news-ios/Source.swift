//
//  Source.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/4/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation

class Source: APIObject {
    var title: String?
    var url: String?
    var articles: [Article]?
    var textColor: UIColor?
    var backgroundColor: UIColor?
    override func importJson(json: [String : AnyObject]) {
        super.importJson(json)
        self.title = json["title"] as? String ?? self.title
        self.url = json["url"] as? String ?? self.url
        if let articles = json["articles"] as? [[String: AnyObject]] {
            self.articles = APIObjectsFromDictionaries(articles)
        }
        if let brand = json["brand"] as? [String: AnyObject], let colors = brand["colors"] as? [String: AnyObject] {
            if let hex = colors["text"] as? String, let color = UIColor(hexString: hex) {
                textColor = color
            }
            if let hex = colors["background"] as? String, let color = UIColor(hexString: hex) {
                backgroundColor = color
            }
        }
    }
    
    override func jsonPath() -> (String, [String : String]?)? {
        if let id = self.id {
            return ("/source", ["id": id])
        } else {
            return nil
        }
    }
    
    override class func typeName() -> String {
        return "source"
    }
    
    var highlightedArticle: Article? {
        get {
            return articles?.first
        }
    }
}
