//
//  FeedCell.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/11/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class FeedCell: UICollectionViewCell {
    let sourceName = UILabel()
    let headline = UILabel()
    let sourceCountView = UILabel()
    let chevron = UIImageView(image: UIImage(named: "Chevron")?.imageWithRenderingMode(.AlwaysTemplate))
    let sourceRowBackground = UIView()
    var articleImage = NetImageView()
    
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
            
            for v in [articleImage, sourceRowBackground, sourceName, headline, sourceCountView, chevron] {
                addSubview(v)
            }
            for v in [sourceName, sourceCountView] {
                v.font = UIFont.boldSystemFontOfSize(13)
            }
            sourceRowBackground.backgroundColor = UIColor(white: 0.1, alpha: 0.12)
            sourceName.userInteractionEnabled = false
            sourceCountView.userInteractionEnabled = false
            sourceRowBackground.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "_tappedSourceName:"))
            headline.font = UIFont.systemFontOfSize(18)
            headline.numberOfLines = 0
            articleImage.contentMode = .ScaleAspectFill
            articleImage.backgroundColor = UIColor.whiteColor()
            articleImage.clipsToBounds = true
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
        sourceName.text = source?.title?.uppercaseString
        headline.text = source?.highlightedArticle?.title
        sourceCountView.text = "22"
        if let url = source?.highlightedArticle?.imageURL, let nsURL = NSURL(string: url) {
            if nsURL != articleImage.url {
                articleImage.url = nsURL
            }
        } else {
            articleImage.url = nil
        }
        
        backgroundColor = source?.backgroundColor ?? UIColor(white: 1, alpha: 1)
        let textColor = source?.textColor ?? UIColor.blackColor()
        for label in [sourceName, headline, sourceCountView] {
            label.textColor = textColor
        }
        chevron.tintColor = textColor
        
        setNeedsLayout()
    }
    
    func _layout(width: CGFloat) -> CGFloat {
        chevron.sizeToFit()
        sourceCountView.sizeToFit()
        sourceName.sizeToFit()
        let sourceHeight = sourceName.frame.height + padding * 2
        chevron.center = CGPointMake(width - chevron.frame.width/2 - padding, sourceHeight/2)
        sourceCountView.frame = CGRectMake(chevron.frame.origin.x - sourceCountView.frame.width - padding, sourceHeight/2 - sourceCountView.frame.height/2, sourceCountView.frame.width, sourceCountView.frame.height)
        sourceName.frame = CGRectMake(padding, padding, sourceCountView.frame.origin.x - padding*2, sourceName.frame.height)
        sourceRowBackground.frame = CGRectMake(0, 0, width, sourceHeight)
        
        let showImage = (articleImage.url != nil)
        let headlineWidth = width - padding * 2 - (showImage ? imageSize : 0)
        let headlineHeight = max(headline.sizeThatFits(CGSizeMake(headlineWidth, 1000)).height, showImage ? imageSize : 0)
        headline.frame = CGRectMake(padding, sourceHeight + padding, headlineWidth, headlineHeight)
        articleImage.hidden = !showImage
        if showImage {
            articleImage.frame = CGRectMake(width - imageSize, sourceHeight, imageSize, headline.frame.bottom + padding - sourceHeight)
        }
        
        return headline.frame.bottom + padding
    }
    
    override func sizeThatFits(size: CGSize) -> CGSize {
        return CGSizeMake(size.width, _layout(size.width))
    }
    
    let padding: CGFloat = 8
    let imageSize: CGFloat = 80
}

