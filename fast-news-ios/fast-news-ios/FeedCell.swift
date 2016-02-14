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
    let chevron = UIImageView(image: UIImage(named: "ThinChevron")?.imageWithRenderingMode(.AlwaysTemplate))
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
            let stillSyncing = src.id == nil
            if stillSyncing {
                sourceName.text = "Syncing \(src.title)…"
            }
            chevron.hidden = stillSyncing
            userInteractionEnabled = !stillSyncing
            alpha = stillSyncing ? 0.5 : 1
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
