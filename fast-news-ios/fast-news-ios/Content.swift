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
        let stylesheet = Stylesheets.CreateDefault()
        if let segmentsJson = json["segments"] as? [[String: AnyObject]] {
            let segments_ = segmentsJson.map({ArticleContent.segmentFromJson($0, style: stylesheet)}).filter({$0 != nil}).map({$0!})
            segments = ArticleContent._moveTitleImageToTop(segments_)
        } else {
            segments = []
        }
        lowQuality = json["is_low_quality_parse"] as? Bool
    }
    
    let segments: [Segment]
    let lowQuality: Bool? // low-quality parse
    
    static func _moveTitleImageToTop(segments: [Segment]) -> [Segment] {
        var segs = segments
        if let idx = segments.indexOf({ ($0 as? ImageSegment)?.isPartOfTitle ?? false }) {
            let titleImage = segments[idx]
            segs.removeAtIndex(idx)
            segs.insert(titleImage, atIndex: 0)
        }
        return segs
    }
    
    static func segmentFromJson(json: [String: AnyObject], style: Stylesheet) -> Segment? {
        if let type = json["type"] as? String {
            switch type {
                case "text": return TextSegment(json: json, style: style)
                case "image": return ImageSegment(json: json, style: style)
                default: ()
            }
        }
        return nil
    }
    
    class Segment {
        init(json: [String: AnyObject], style: Stylesheet) {
            if let p = json["is_part_of_title"] as? Bool {
                isPartOfTitle = p
            }
            
            let leftPadding: CGFloat = json["left_padding"] as? CGFloat ?? 0
            let rightPadding: CGFloat = json["right_padding"] as? CGFloat ?? 0
            padding = UIEdgeInsetsMake(0, leftPadding * 10, 0, rightPadding * 10)
        }
        var isPartOfTitle = false
        let padding: UIEdgeInsets
    }
    
    static let LinkAttributeName = "FNLinkAttributeName"
    
    class TextSegment: Segment {
        override init(json: [String: AnyObject], style: Stylesheet) {
            var elementStyle = style.bodyStyle
            
            kind = json["kind"] as? String ?? "p"
            var attrs = Span.defaultAttrs()
            let paragraphStyle = attrs[NSParagraphStyleAttributeName] as! NSMutableParagraphStyle
            paragraphStyle.headIndent = 0
            var fontOptions = FontOptions()
            var prependText: String?
            let indent: CGFloat = 15
            
            switch kind {
                case "title":
                    elementStyle = style.titleStyle
                case "h1":
                    elementStyle = style.h1Style
                case "h2":
                    elementStyle = style.h2Style
                case "h3":
                    elementStyle = style.h3Style
                case "h4":
                    elementStyle = style.h3Style
                case "h5":
                    elementStyle = style.h3Style
                case "h6":
                    elementStyle = style.h3Style
                case "pre":
                    fontOptions.monospace = true
                    paragraphStyle.lineHeightMultiple = 1
                case "meta":
                    elementStyle = style.metaStyle
                case "blockquote":
                    paragraphStyle.headIndent = indent
                    paragraphStyle.firstLineHeadIndent = indent
                    fontOptions.italic = true
                case "li":
                    prependText = "• "
                    paragraphStyle.headIndent = indent
                    paragraphStyle.firstLineHeadIndent = indent
                case "caption":
                    elementStyle = style.captionStyle
            default: ()
            }
            fontOptions.initializeWithElementStyle(elementStyle)
            attrs[NSForegroundColorAttributeName] = elementStyle.color
            
            let font = fontOptions.font
            attrs[NSFontAttributeName] = font
            // extraBottomPadding = font.descender // cut off some of the margin
            
            if let spanJson = json["content"] as? [AnyObject] where spanJson.count >= 1 {
                span = Span(json: spanJson, parentAttrs: attrs, parentFontOptions: fontOptions)
            } else {
                span = Span(json: [[String: AnyObject]()], parentAttrs: attrs, parentFontOptions: fontOptions)
            }
            if let prepend = prependText {
                span.children.insert(Span.Child.Text(prepend), atIndex: 0)
            }
            
            /*if let t = hangingText {
                var hangingTextAttrs = attrs
                hangingTextAttrs.removeValueForKey(NSParagraphStyleAttributeName)
                self.hangingText = NSAttributedString(string: t, attributes: hangingTextAttrs)
            }*/
            
            super.init(json: json, style: style)
        }
        let kind: String
        let span: Span
        var hangingText: NSAttributedString?
        var extraBottomPadding: CGFloat = 0
        var extraTopPadding: CGFloat = 0
    }
    
    class ImageSegment: Segment {
        override init(json: [String : AnyObject], style: Stylesheet) {
            super.init(json: json, style: style)
            url = json["src"] as? String
            if let sizeArray = json["size"] as? [CGFloat] where sizeArray.count == 2 {
                size = CGSizeMake(sizeArray[0], sizeArray[1])
            }
            if let tiny = json["tiny"] as? [String: AnyObject] {
                tinyImage = UIImage.fromTinyJson(tiny)
            }
        }
        var url: String?
        var size: CGSize?
        var tinyImage: UIImage?
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
                    if let monospace = dict["monospace"] as? Bool {
                        fontOptions.monospace = monospace
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
            para.lineHeightMultiple = Stylesheets.Default.lineHeight
            // para.paragraphSpacingBefore = 20
            // para.paragraphSpacing = 20
            para.alignment = .Left
            attrs[NSParagraphStyleAttributeName] = para
            return attrs
        }
        static func defaultTextColor() -> UIColor {
            return UIColor(red: 0.146239966154, green:0.1462444067, blue:0.146241992712, alpha:1.0)
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
                case .Text(var text):
                    if fontOptions.uppercase {
                        text = text.uppercaseString
                    }
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
        var uppercase = false
        var pointSize: CGFloat = 12
        var fontName: String = FontOptions.defaultFontName
        var monospace = false
        var font: UIFont {
            var desc = UIFontDescriptor(name: fontName, size: 12) // UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleBody)
            var traits: UIFontDescriptorSymbolicTraits = []
            if bold {
                traits.insert(.TraitBold)
            }
            if italic {
                traits.insert(.TraitItalic)
            }
            desc = desc.fontDescriptorWithSymbolicTraits(traits)
            if monospace {
                return UIFont(name: "Courier", size: pointSize)!
            } else {
                return UIFont(descriptor: desc, size: pointSize)
            }
        }
        
        static let defaultFontName = UIFont.systemFontOfSize(12).fontName
        
        mutating func initializeWithElementStyle(style: Stylesheet.ElementStyle) {
            pointSize = style.font.pointSize
            fontName = style.font.fontName
            bold = style.bold
            uppercase = style.uppercase
        }
    }
}
