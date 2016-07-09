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
    var fetchFailed: Bool?
    var imageURL: String?
    var topImageTinyJson: [String: AnyObject]?
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
        if let tinyJson = json["top_image_tiny_json"] as? [String: AnyObject] {
            topImageTinyJson = tinyJson
        }
        
        self.articleDescription = json["description"] as? String ?? self.articleDescription
        if let articleJson = json["article_json"] as? [String: AnyObject] {
            content = ArticleContent(json: articleJson)
        }
        fetchFailed = (json["fetch_failed"] as? Bool) ?? fetchFailed
    }
    
    var imagePlaceholder: UIImage? {
        get {
            if let j = topImageTinyJson {
                return UIImage.fromTinyJson(j)
            }
            return nil
        }
    }
    
    override func jsonPath() -> (String, [String : String]?)? {
        if let id = self.id {
            return ("/article", ["id": id])
        } else if let url = self.url {
            return ("/article", ["url": url])
        } else {
            return nil
        }
    }
    
    override class func typeName() -> String {
        return "article"
    }
}
