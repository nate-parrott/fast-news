//
//  VerticalFeedCell.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 8/21/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import AsyncDisplayKit

class VerticalFeedCell: UICollectionViewCell {
    class func HeightForSource(source: Source, width: CGFloat) -> CGFloat {
        if let article = source.highlightedArticle, let title = article.title {
            var height: CGFloat = 0
            if let size = article.imageSize {
                height += round(size.height / size.width * width)
            }
            height += Padding
            let attrStr = AttributedStringForArticleTitle(title)
            height += attrStr.boundingRectWithSize(CGSizeMake(width - Padding * 2, 1000), options: .UsesLineFragmentOrigin, context: nil).size.height
            height += Padding
            return round(height + SourceNameButtonHeight)
        } else {
            return SourceNameButtonHeight
        }
    }
    
    static let Padding: CGFloat = 8
    static let SourceNameButtonHeight: CGFloat = 30
    
    class func AttributedStringForArticleTitle(title: String) -> NSAttributedString {
        let font = UIFont.systemFontOfSize(15, weight: UIFontWeightMedium)
        return NSAttributedString(string: title, attributes: [NSFontAttributeName: font])
    }
    
    var _setupYet = false
    let headline = ASTextNode()
    let divider = ASDisplayNode()
    let button = ASTextNode()
    let image = NetImageView()
    let chevron = ASImageNode()
    let tapRec = UITapGestureRecognizer()
    
    var source: Source? {
        didSet {
            _setup()
            
            if let article = source?.highlightedArticle, let title = article.title {
                headline.attributedText = self.dynamicType.AttributedStringForArticleTitle(title)
                headline.hidden = false
                divider.hidden = false
                if let img = article.imageURL, let imageURL = NSURL(string: img) {
                    image.hidden = false
                    let placeholder = article.topImageTinyJson != nil ? UIImage.fromTinyJson(article.topImageTinyJson!) : nil
                    image.setURL(imageURL, placeholder: placeholder)
                    if let size = article.imageSize {
                        imageAspect = size.width / size.height
                    } else {
                        imageAspect = 1.3
                    }
                } else {
                    image.hidden = true
                    image.setURL(nil, placeholder: nil)
                    imageAspect = nil
                }
            } else {
                headline.hidden = true
                image.hidden = true
                divider.hidden = true
            }
            
            // let font = UIFont.systemFontOfSize(12, weight: UIFontWeightMedium)
            let font = UIFont.boldSystemFontOfSize(12)
            // button.setTitle(source?.shortTitle ?? source?.title ?? "", withFont: font, withColor: UIColor.blackColor(), forState: .Normal)
            let buttonText = source?.shortTitle ?? source?.title ?? ""
            let para = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
            para.alignment = .Center
            button.attributedText = NSAttributedString(string: buttonText, attributes: [NSFontAttributeName: font, NSForegroundColorAttributeName: UIColor.blackColor(), NSParagraphStyleAttributeName: para])
            
            setNeedsLayout()
        }
    }
    
    var onTappedArticle: (Article -> ())?
    var onTappedSource: (Source -> ())?
    
    var imageAspect: CGFloat?
    
    func _setup() {
        if !_setupYet {
            _setupYet = true
            
            backgroundColor = UIColor.whiteColor()
            
            headline.layerBacked = true
            contentView.addSubnode(headline)
            
            chevron.layerBacked = true
            chevron.image = UIImage(named: "Chevron")!
            chevron.contentMode = .ScaleAspectFit
            chevron.alpha = 0.5
            contentView.addSubnode(chevron)
            
            contentView.addSubview(image)
            
            button.alpha = 0.5
            button.layerBacked = true
            contentView.addSubnode(button)
            
            divider.layerBacked = true
            divider.backgroundColor = UIColor.groupTableViewBackgroundColor()
            contentView.addSubnode(divider)
            
            let tapRec = UITapGestureRecognizer(target: self, action: #selector(VerticalFeedCell.tapped))
            contentView.addGestureRecognizer(tapRec)
        }
    }
    
    func tapped(tap: UITapGestureRecognizer) {
        let pos = tap.locationInView(self)
        if pos.y > bounds.size.height - self.dynamicType.SourceNameButtonHeight {
            if let cb = onTappedSource, let src = source {
                cb(src)
            }
        } else {
            if let cb = onTappedArticle, let article = source?.highlightedArticle {
                cb(article)
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let padding = self.dynamicType.Padding
        if bounds.size.width <= padding * 2 { return }
        let hasArticle = source?.highlightedArticle != nil
        var y: CGFloat = 0
        if hasArticle {
            let hasImage = !image.hidden
            if hasImage {
                let imageHeight = round(bounds.size.width / (imageAspect ?? 1))
                image.frame = CGRectMake(0, 0, bounds.size.width, imageHeight)
                y += imageHeight
            }
            y += padding
            let headlineHeight = ceil(headline.calculateSizeThatFits(CGSizeMake(bounds.size.width - padding * 2, bounds.size.height)).height)
            headline.frame = CGRectMake(padding, y, bounds.size.width - padding * 2, headlineHeight)
            y += headlineHeight + padding
        }
        y = bounds.size.height - self.dynamicType.SourceNameButtonHeight
        divider.frame = CGRectMake(0, y, bounds.size.width, 1 / UIScreen.mainScreen().scale)
        let buttonTitleHeight: CGFloat = 13
        button.frame = CGRectMake(0, y + (self.dynamicType.SourceNameButtonHeight - buttonTitleHeight)/2, bounds.size.width, buttonTitleHeight + 5)
        chevron.bounds = CGRectMake(0, 0, 8, 8)
        chevron.position = CGPointMake(bounds.size.width - 15, button.position.y)        
    }
}
