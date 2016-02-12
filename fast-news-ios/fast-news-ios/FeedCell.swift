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
            let t = src.title ?? "this subscription"
            sourceName.text = articleView.article == nil ?  "Articles from \(t)" : "More from \(t)"
        }
        setNeedsLayout()
    }
    
    func _layout(width: CGFloat) -> CGFloat {
        let padding: CGFloat = 8
        let xPadding: CGFloat = 0
        var y: CGFloat = 0
        if !articleView.hidden {
            let articleWidth = width - xPadding * 2
            let articleHeight = articleView.sizeThatFits(CGSizeMake(articleWidth, 1000)).height
            articleView.frame = CGRectMake(xPadding, y, articleWidth, articleHeight)
            y = articleView.frame.bottom + padding
        }
        sourceName.sizeToFit()
        sourceName.center = CGPointMake(width/2, y + sourceName.frame.size.height/2)
        chevron.sizeToFit()
        chevron.center = CGPointMake(sourceName.frame.origin.x + sourceName.frame.size.width + padding + chevron.frame.size.width/2, sourceName.center.y)
        sourceTapView.frame = CGRectMake(0, sourceName.frame.origin.y - padding, width, sourceName.frame.bottom + padding - (sourceName.frame.origin.y - padding))
        return sourceName.frame.bottom + padding
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
                headline.text = a.title
                if let url = a.imageURL {
                    imageView.url = NSURL(string: url)
                } else {
                    imageView.url = nil
                }
            }
        }
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
    
    func _layout(width: CGFloat) -> CGFloat {
        let imageSize: CGFloat = 120
        let padding: CGFloat = 4
        let hasImage = imageView.url != nil
        let headlineWidth = hasImage ? width - imageSize - padding * 2 : width - padding * 2
        let headlineHeight = headline.sizeThatFits(CGSizeMake(headlineWidth, 200)).height
        let height = max(headlineHeight + padding * 2, hasImage ? imageSize : 0)
        imageView.hidden = !hasImage
        imageView.frame = CGRectMake(width - imageSize, 0, imageSize, height)
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

