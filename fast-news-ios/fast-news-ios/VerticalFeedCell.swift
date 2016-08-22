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
            return height + SourceNameButtonHeight
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
    let button = ASButtonNode()
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
            
            button.setTitle(source?.shortTitle ?? "", withFont: UIFont.systemFontOfSize(12, weight: UIFontWeightMedium), withColor: UIColor.blackColor(), forState: .Normal)
            
            setNeedsLayout()
        }
    }
    
    var imageAspect: CGFloat?
    
    func _setup() {
        if !_setupYet {
            _setupYet = true
            
            headline.layerBacked = true
            contentView.addSubnode(headline)
            
            chevron.layerBacked = true
            chevron.image = UIImage(named: "Chevron")!
            chevron.alpha = 0.5
            contentView.addSubnode(chevron)
            
            contentView.addSubnode(button)
            button.alpha = 0.5
            
            divider.layerBacked = true
            divider.backgroundColor = UIColor.groupTableViewBackgroundColor()
            contentView.addSubnode(divider)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let padding = self.dynamicType.Padding
        let hasArticle = source?.highlightedArticle != nil
        var y: CGFloat = 0
        if hasArticle {
            let hasImage = !image.hidden
            if hasImage {
                let imageHeight = round((imageAspect ?? 1) * bounds.size.width)
                image.frame = CGRectMake(0, 0, bounds.size.width, imageHeight)
                y += imageHeight
            }
            y += padding
            let headlineHeight = headline.calculateSizeThatFits(CGSizeMake(bounds.size.width - padding * 2, bounds.size.height)).height
            headline.frame = CGRectMake(padding, y, bounds.size.width - padding * 2, headlineHeight)
            y += headlineHeight + padding
        }
        divider.frame = CGRectMake(0, y, bounds.size.width, 1 / UIScreen.mainScreen().scale)
        button.frame = CGRectMake(0, y, bounds.size.width, self.dynamicType.SourceNameButtonHeight)
        chevron.bounds = CGRectMake(0, 0, 8, 8)
        chevron.position = CGPointMake(bounds.size.width - 15, button.position.y)
    }
}
