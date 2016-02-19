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
    var articleDescription: String?
    var url: String?
    var imageURL: String?
    weak var source: Source?
    var differentWebsiteFromSource: Bool?
    var content: ArticleContent?
    override func importJson(json: [String : AnyObject]) {
        super.importJson(json)
        self.title = json["title"] as? String ?? self.title
        self.url = json["url"] as? String ?? self.url
        if let content = json["content"] as? [String: AnyObject] {
            self.text = content["article_text"] as? String ?? self.text
        }
        self.imageURL = json["top_image"] as? String ?? self.imageURL
        self.articleDescription = json["description"] as? String ?? self.articleDescription
        if let articleJson = json["article_json"] as? [String: AnyObject] {
            content = ArticleContent(json: articleJson)
        }
    }
    
    override func jsonPath() -> (String, [String : String]?)? {
        if let id = self.id {
            return ("/article", ["id": id, "article_json": "1"])
        } else {
            return nil
        }
    }
    
    override class func typeName() -> String {
        return "article"
    }
}
