//
//  ContentPreview.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 12/14/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

extension ArticleContent {
    static func createPreviewForArticle(article: Article) -> ArticleContent? {
        var segments = [[String: AnyObject]]()
        if let imageURL = article.imageURL, let tinyJson = article.topImageTinyJson {
            let size = tinyJson["real_size"]!
            segments.append(["src": imageURL, "tiny": tinyJson, "size": size, "type": "image", "is_part_of_title": true])
        }
        if let title = article.title {
            let content = [[String: AnyObject](), title]
            segments.append(["kind": "title", "is_part_of_title": true, "type": "text", "content": content])
        }
        if segments.count > 0 {
            let json: [String: AnyObject] = ["is_low_quality_parse": false, "segments": segments]
            return ArticleContent(json: json)
        } else {
            return nil
        }
    }
}
