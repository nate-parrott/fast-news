//
//  Stylesheets.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 3/20/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation

struct Stylesheets {
    static let Default = Stylesheets.CreateDefault()
    static func CreateDefault() -> Stylesheet {
        return CreateWithFontName(UIFont.systemFontOfSize(12).fontName)
    }
    static func CreateWithFontName(name: String) -> Stylesheet {
        let s = Stylesheet()
        s.titleStyle.font = UIFont(name: name, size: 23)!
        s.h1Style.font = UIFont(name: name, size: 21)!
        s.h2Style.font = UIFont(name: name, size: 19)!
        s.h3Style.font = UIFont(name: name, size: 17)!
        
        for style in [s.titleStyle, s.h1Style, s.h2Style, s.h3Style] {
            style.bold = true
        }
        
        s.bodyStyle.font = UIFont(name: name, size: 17)!
        s.captionStyle.font = UIFont(name: name, size: 14)!
        for (_, style) in s.stylePairs {
            style.color = UIColor(white: 0.1, alpha: 1)
        }
        s.captionStyle.color = UIColor(white: 0.1, alpha: 0.5)
        s.backgroundColor = UIColor(white: 0.99, alpha: 1)
        return s
    }
}
