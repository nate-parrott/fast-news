//
//  FeedCell.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/11/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class FeedCell: UICollectionViewCell {
    let articleView = ArticleView()
    let sourceName = UILabel()
    let chevron = UIImageView(image: UIImage(named: "Chevron")?.imageWithRenderingMode(.AlwaysTemplate))
    let sourceTapView = UIView()
    
    var _sub: Subscription?
    
    var onTappedSourceName: ((source: Source) -> ())?
    
    var source: Source? {
        didSet {
            _setupIfNeeded()
            if let s = source {
                _sub = s.onUpdate.subscribe({ [weak self] (source) -> () in
                    self?._update()
                    })
                _update()
            }
        }
    }
    
    var _setupYet = false
    func _setupIfNeeded() {
        if !_setupYet {
            _setupYet = true
            
            for v in [articleView, sourceName, chevron, sourceTapView] {
                addSubview(v)
            }
            let outerTextColor = UIColor.blackColor()
            chevron.tintColor = outerTextColor
            chevron.alpha = 0.4
            sourceName.textColor = outerTextColor
            sourceName.font = UIFont(name: "RobotoMono-Regular", size: 14)
            sourceTapView.backgroundColor = UIColor.clearColor()
            sourceTapView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "_tappedSourceName:"))
        }
    }
    
    func _tappedSourceName(tapRec: UITapGestureRecognizer) {
        if let t = onTappedSourceName {
            t(source: source!)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        _layout(bounds.size.width)
    }
    
    func _update() {
        if let src = source {
            articleView.article = src.highlightedArticle
            articleView.hidden = (articleView.article == nil)
            sourceName.text = src.title
        }
        setNeedsLayout()
    }
    
    func _layout(width: CGFloat) -> CGFloat {
        let padding: CGFloat = 8
        let xPadding: CGFloat = 0
        var y: CGFloat = padding
        
        sourceName.sizeToFit()
        sourceName.frame = CGRectMake(padding, y, sourceName.frame.width, sourceName.frame.height)
        chevron.sizeToFit()
        chevron.center = CGPointMake(sourceName.frame.origin.x + sourceName.frame.size.width + padding + chevron.frame.size.width/2, sourceName.center.y)
        sourceTapView.frame = CGRectMake(0, sourceName.frame.origin.y - padding, width, sourceName.frame.bottom + padding - (sourceName.frame.origin.y - padding))
        y = sourceTapView.frame.bottom
        
        if !articleView.hidden {
            let articleWidth = width - xPadding * 2
            let articleHeight = articleView.sizeThatFits(CGSizeMake(articleWidth, 1000)).height
            articleView.frame = CGRectMake(xPadding, y, articleWidth, articleHeight)
            y = articleView.frame.bottom
        }
        return y
    }
    
    override func sizeThatFits(size: CGSize) -> CGSize {
        return CGSizeMake(size.width, _layout(size.width))
    }
}

class ArticleView: UIView {
    var article: Article? {
        didSet {
            _setup()
            if let a = article {
                headline.attributedText = getPreviewText()
                if let url = a.imageURL {
                    let scale = UIScreen.mainScreen().scale * 2
                    imageView.url = imageView.mirroredURLForImage(url, size: CGSizeMake(ArticleView.ImageSize * scale, (ArticleView.MaxLabelHeight + ArticleView.Padding * 2) * scale))
                    // imageView.url = NSURL(string: url)
                } else {
                    imageView.url = nil
                }
            }
        }
    }
    func getPreviewText() -> NSAttributedString {
        let headline = NSAttributedString(string: (article?.title ?? ""), attributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(17), NSForegroundColorAttributeName: UIColor(white: 0, alpha: 1)])
        let description = NSAttributedString(string: (article?.articleDescription ?? ""), attributes: [NSFontAttributeName: UIFont.systemFontOfSize(12), NSForegroundColorAttributeName: UIColor(white: 0, alpha: 0.5)])
        
        let all = headline.mutableCopy() as! NSMutableAttributedString
        if description.length > 0 {
            all.appendAttributedString(NSAttributedString(string: "\n\n", attributes: [NSFontAttributeName: UIFont.systemFontOfSize(1)]))
            all.appendAttributedString(description)
        }
        return all
        
    }
    let imageView = NetImageView()
    let headline = UILabel()
    var _setupYet = false
    func _setup() {
        if !_setupYet {
            _setupYet = true
            for v in [imageView, headline] {
                addSubview(v)
            }
            headline.numberOfLines = 0
            headline.font = UIFont.boldSystemFontOfSize(17)
            backgroundColor = UIColor.whiteColor()
            imageView.contentMode = .ScaleAspectFill
            imageView.clipsToBounds = true
        }
    }
    
    static let ImageSize: CGFloat = 120
    static let Padding: CGFloat = 4
    static let MaxLabelHeight: CGFloat = 124
    
    func _layout(width: CGFloat) -> CGFloat {
        let maxLabelHeight: CGFloat = ArticleView.MaxLabelHeight
        let minLabelHeight: CGFloat = 56
        let padding: CGFloat = ArticleView.Padding
        let hasImage = imageView.url != nil
        let headlineWidth = hasImage ? width - ArticleView.ImageSize - padding * 2 : width - padding * 2
        let headlineHeight = min(maxLabelHeight, headline.sizeThatFits(CGSizeMake(headlineWidth, maxLabelHeight)).height)
        let height = max(headlineHeight + padding * 2, hasImage ? ArticleView.ImageSize : 0, minLabelHeight)
        imageView.hidden = !hasImage
        imageView.frame = CGRectMake(width - ArticleView.ImageSize, 0, ArticleView.ImageSize, height)
        headline.frame = CGRectMake(padding, padding, headlineWidth, height - padding * 2)
        return height
    }
    
    override func sizeThatFits(size: CGSize) -> CGSize {
        return CGSizeMake(size.width, _layout(size.width))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        _layout(bounds.size.width)
    }
}

