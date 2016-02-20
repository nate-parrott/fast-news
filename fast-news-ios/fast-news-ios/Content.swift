//
//  Content.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/16/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class ArticleContent {
    init(json: [String: AnyObject]) {
        if let segmentsJson = json["segments"] as? [[String: AnyObject]] {
            segments = segmentsJson.map({ArticleContent.segmentFromJson($0)}).filter({$0 != nil}).map({$0!})
        } else {
            segments = []
        }
    }
    
    let segments: [Segment]
    
    static func segmentFromJson(json: [String: AnyObject]) -> Segment? {
        if let type = json["type"] as? String {
            switch type {
                case "text": return TextSegment(json: json)
                case "image": return ImageSegment(json: json)
                default: ()
            }
        }
        return nil
    }
    
    class Segment {
        init(json: [String: AnyObject]) {
            
        }
    }
    
    static let LinkAttributeName = "FNLinkAttributeName"
    
    class TextSegment: Segment {
        override init(json: [String: AnyObject]) {
            kind = json["kind"] as? String ?? "p"
            var attrs = Span.defaultAttrs()
            let paragraphStyle = attrs[NSParagraphStyleAttributeName] as! NSMutableParagraphStyle
            var fontOptions = FontOptions()
            switch kind {
                case "h1":
                    fontOptions.size = 3
                    fontOptions.bold = true
                    paragraphStyle.lineHeightMultiple = 1
                case "h2":
                    fontOptions.size = 2
                    fontOptions.bold = true
                    paragraphStyle.lineHeightMultiple = 1
                case "h3":
                    fontOptions.bold = true
                    paragraphStyle.lineHeightMultiple = 1
            default: ()
            }
            attrs[NSFontAttributeName] = fontOptions.font
            
            if let spanJson = json["content"] as? [AnyObject] where spanJson.count >= 1 {
                span = Span(json: spanJson, parentAttrs: attrs, parentFontOptions: fontOptions)
            } else {
                span = Span(json: [[String: AnyObject]()], parentAttrs: attrs, parentFontOptions: fontOptions)
            }
            super.init(json: json)
        }
        let kind: String
        let span: Span
    }
    
    class ImageSegment: Segment {
        override init(json: [String : AnyObject]) {
            super.init(json: json)
            url = json["src"] as? String
            if let sizeArray = json["size"] as? [CGFloat] where sizeArray.count == 2 {
                size = CGSizeMake(sizeArray[0], sizeArray[1])
            }
        }
        var url: String?
        var size: CGSize?
    }
    
    class Span {
        init(json: [AnyObject], parentAttrs: [String: AnyObject], parentFontOptions: FontOptions) {
            var attrs = parentAttrs
            var fontOptions = parentFontOptions
            if json.count > 0 {
                if let dict = json[0] as? [String: AnyObject] {
                    if let bold = dict["bold"] as? Bool {
                        fontOptions.bold = bold
                    }
                    if let italic = dict["italic"] as? Bool {
                        fontOptions.italic = italic
                    }
                    if let link = dict["link"] as? String, let url = NSURL(string: link) {
                        attrs[LinkAttributeName] = url
                        attrs[NSUnderlineStyleAttributeName] = NSUnderlineStyle.StyleSingle.rawValue
                        // attrs[NSForegroundColorAttributeName] = Span.defaultTextColor()
                    }
                }
            }
            attrs[NSFontAttributeName] = fontOptions.font
            self.attrs = attrs
            self.fontOptions = fontOptions
            if json.count > 1 {
                for i in 1..<json.count {
                    if let text = json[i] as? String {
                        children.append(Child.Text(text))
                    } else if let childSpanJson = json[i] as? [AnyObject] {
                        children.append(Child.Span(Span(json: childSpanJson, parentAttrs: attrs, parentFontOptions: fontOptions)))
                    }
                }
            }
        }
        static func defaultAttrs() -> [String: AnyObject] {
            var attrs = [String: AnyObject]()
            attrs[NSFontAttributeName] = FontOptions().font
            attrs[NSForegroundColorAttributeName] = defaultTextColor()
            attrs[NSUnderlineStyleAttributeName] = 0
            let para = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
            para.lineHeightMultiple = 1.4
            para.paragraphSpacingBefore = 20
            para.paragraphSpacing = 20
            para.alignment = .Left
            attrs[NSParagraphStyleAttributeName] = para
            return attrs
        }
        static func defaultTextColor() -> UIColor {
            return UIColor(white: 0.25, alpha: 1)
        }
        let attrs: [String: AnyObject]
        let fontOptions: FontOptions
        var children = [Child]()
        enum Child {
            case Text(String)
            case Span(ArticleContent.Span)
        }
        func appendToAttributedString(str: NSMutableAttributedString) {
            for child in children {
                switch child {
                case .Text(let text):
                    str.appendAttributedString(NSAttributedString(string: text, attributes: attrs))
                case .Span(let span):
                    span.appendToAttributedString(str)
                }
            }
        }
    }
    struct FontOptions {
        var bold = false
        var italic = false
        var size = 1 // h1 = 3, h2 = 2, else = 1
        var font: UIFont {
            var name = "IowanOldStyle-Roman"
            if bold && italic {
                name = "IowanOldStyle-BoldItalic"
            } else if bold {
                name = "IowanOldStyle-Bold"
            } else if italic {
                name = "IowanOldStyle-Italic"
            }
            var fontSize: CGFloat!
            switch size {
            case 3: fontSize = 24
            case 2: fontSize = 20
            default: fontSize = 16
            }
            return UIFont(name: name, size: fontSize)!
        }
    }
}
