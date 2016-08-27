//
//  Source.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/4/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class Source: APIObject {
    var title: String?
    var shortTitle: String?
    var url: String?
    var articles: [Article]?
    var textColor: UIColor?
    var backgroundColor: UIColor?
    var color: UIColor?
    var iconUrl: String?
    var sharedHostname: String?
    override func importJson(json: [String : AnyObject]) {
        super.importJson(json)
        
        self.title = json["title"] as? String ?? self.title
        self.url = json["url"] as? String ?? self.url
        self.shortTitle = json["short_title"] as? String ?? self.shortTitle
        self.iconUrl = json["icon_url"] as? String ?? self.iconUrl
        if let c = json["color"] as? String {
            let colorStr = c.containsString("#") ? c : "#" + c
            self.color = UIColor(hex: colorStr)
        }
        self.sharedHostname = json["shared_hostname"] as? String ?? self.sharedHostname
        
        let sourceHost = sharedHostname ?? (url != nil ? Utils.HostFromURLString(url!) : nil)
        
        if let articles = json["articles"] as? [[String: AnyObject]] {
            self.articles = APIObjectsFromDictionaries(articles)
            for a in self.articles ?? [] {
                a.source = self
                let articleHost = a.url != nil ? Utils.HostFromURLString(a.url!) : nil
                if let host1 = articleHost, let host2 = sourceHost {
                    a.differentWebsiteFromSource = !Utils.TopLevelDomainsMatch(host1, host2: host2)
                }
            }
        }
        if let brand = json["brand"] as? [String: AnyObject], let colors = brand["colors"] as? [String: AnyObject] {
            if let hex = colors["text"] as? String, let color = UIColor(hex: hex) {
                textColor = color
            }
            if let hex = colors["background"] as? String, let color = UIColor(hex: hex) {
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
            if let a = articles {
                return a.filter({$0.fetchFailed == false}).first ?? a.first
            }
            return nil
        }
    }
}
