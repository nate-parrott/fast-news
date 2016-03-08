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
        lowQuality = json["is_low_quality_parse"] as? Bool
    }
    
    let segments: [Segment]
    let lowQuality: Bool? // low-quality parse
    
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
            paragraphStyle.headIndent = 0
            var fontOptions = FontOptions()
            var prependText: String?
            let indent: CGFloat = 15
            switch kind {
                case "title":
                    fontOptions.headingFont = true
                    fontOptions.size = 3
                    fontOptions.bold = true
                case "h1":
                    fontOptions.headingFont = true
                    fontOptions.size = 3
                    fontOptions.bold = true
                    // paragraphStyle.lineHeightMultiple = 1
                case "h2":
                    fontOptions.headingFont = true
                    fontOptions.size = 2
                    fontOptions.bold = true
                    // paragraphStyle.lineHeightMultiple = 1
                case "h3":
                    fontOptions.uppercase = true
                    fontOptions.headingFont = true
                    fontOptions.bold = true
                    // paragraphStyle.lineHeightMultiple = 1
                case "h4":
                    fontOptions.uppercase = true
                    fontOptions.headingFont = true
                    fontOptions.bold = true
                    // paragraphStyle.lineHeightMultiple = 1
                case "h5":
                    fontOptions.uppercase = true
                    fontOptions.headingFont = true
                    fontOptions.bold = true
                    // paragraphStyle.lineHeightMultiple = 1
                case "h6":
                    fontOptions.uppercase = true
                    fontOptions.headingFont = true
                    fontOptions.bold = true
                    // paragraphStyle.lineHeightMultiple = 1
                case "pre":
                    fontOptions.monospace = true
                    paragraphStyle.lineHeightMultiple = 1
                case "blockquote":
                    paragraphStyle.headIndent = indent
                    paragraphStyle.firstLineHeadIndent = indent
                    fontOptions.italic = true
                case "li":
                    prependText = "• "
                    paragraphStyle.headIndent = indent
                    paragraphStyle.firstLineHeadIndent = indent
                case "caption":
                    attrs[NSForegroundColorAttributeName] = (attrs[NSForegroundColorAttributeName] as! UIColor).colorWithAlphaComponent(0.6)
                    fontOptions.size = 0
            default: ()
            }
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
            
            super.init(json: json)
        }
        let kind: String
        let span: Span
        var hangingText: NSAttributedString?
        var extraBottomPadding: CGFloat = 0
        var extraTopPadding: CGFloat = 0
    }
    
    class ImageSegment: Segment {
        override init(json: [String : AnyObject]) {
            super.init(json: json)
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
            para.lineHeightMultiple = 1.2
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
        var headingFont = false
        var uppercase = false
        var size = 1 // h1 = 3, h2 = 2, else = 1; x-small = 0
        var monospace = false
        var font: UIFont {
            let name = "IowanOldStyle-Roman"
            var desc = UIFontDescriptor(name: name, size: 12) // UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleBody)
            var traits: UIFontDescriptorSymbolicTraits = []
            if bold {
                traits.insert(.TraitBold)
            }
            if italic {
                traits.insert(.TraitItalic)
            }
            desc = desc.fontDescriptorWithSymbolicTraits(traits)
            var pointSize = UIFont.preferredFontForTextStyle(UIFontTextStyleBody).pointSize
            switch size {
            case 3: pointSize = max(pointSize, 22)
            case 2: pointSize = max(pointSize, 20)
            case 0: pointSize = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1).pointSize
            default: ()
            }
            if monospace {
                return UIFont(name: "Courier", size: pointSize)!
            } else {
                return UIFont(descriptor: desc, size: pointSize)
            }
        }
    }
}
