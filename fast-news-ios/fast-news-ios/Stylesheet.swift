//
//  Stylesheet.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 3/10/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class Stylesheet {
    var backgroundColor = UIColor.whiteColor()
    var h1Style = ElementStyle()
    var h2Style = ElementStyle()
    var h3Style = ElementStyle()
    var titleStyle = ElementStyle()
    var bodyStyle = ElementStyle()
    var captionStyle = ElementStyle()
    var metaStyle = ElementStyle()
    var margins: CGFloat = 15
    var lineHeight: CGFloat = 1.2
    
    var stylePairs: [(String, ElementStyle)] {
        get {
            return [("h1Style", h1Style), ("h2Style", h2Style), ("h3Style", h3Style), ("bodyStyle", bodyStyle), ("captionStyle", captionStyle), ("titleStyle", titleStyle), ("metaStyle", metaStyle)]
        }
    }
    
    func importJson(json: [String: AnyObject]) {
        if let b = json["backgroundColor"] as? String, let c = UIColor(hex: b) {
            backgroundColor = c
        }
        for (key, style) in stylePairs {
            if let j = json[key] as? [String: AnyObject] {
                style.importJson(j)
            }
        }
        margins = json["margins"] as? CGFloat ?? margins
        lineHeight = json["lineHeight"] as? CGFloat ?? lineHeight
    }
    
    func exportJson() -> [String: AnyObject] {
        var j = [String: AnyObject]()
        j["backgroundColor"] = backgroundColor.hex
        for (key, style) in stylePairs {
            j[key] = style.exportJson()
        }
        j["margins"] = margins
        j["lineHeight"] = lineHeight
        return j
    }
    
    class ElementStyle {
        var font = UIFont.systemFontOfSize(16)
        var color = UIColor.blackColor()
        var uppercase = false
        var bold = false
        
        func importJson(json: [String: AnyObject]) {
            if let name = json["fontName"] as? String, let size = json["fontSize"] as? CGFloat, let theFont = UIFont(name: name, size: size) {
                font = theFont
            }
            if let b = json["color"] as? String, let c = UIColor(hex: b) {
                color = c
            }
            if let u = json["uppercase"] as? Bool {
                uppercase = u
            }
            if let b = json["bold"] as? Bool {
                bold = b
            }
        }
        
        func exportJson() -> [String: AnyObject] {
            var d = [String: AnyObject]()
            d["fontName"] = font.fontName
            d["fontSize"] = font.pointSize
            d["color"] = color.hex
            d["uppercase"] = uppercase
            d["bold"] = bold
            return d
        }
    }
}
