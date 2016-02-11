//
//  FeedCell.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/11/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class FeedCell: UICollectionViewCell {
    @IBOutlet var sourceName: UILabel!
    @IBOutlet var articleHighlight: UILabel!
    @IBOutlet var sourceCountView: UILabel!
    @IBOutlet var articleImage: NetImageView!
    @IBOutlet var sourceRowContainer: UIView!
    
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
            sourceRowContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "_tappedSourceName:"))
            backgroundColor = UIColor.whiteColor()
        }
    }
    
    func _tappedSourceName(tapRec: UITapGestureRecognizer) {
        if let t = onTappedSourceName {
            t(source: source!)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        sourceName.sizeToFit()
        sourceName.frame = CGRectMake(0, 0, bounds.size.width, sourceName.frame.size.height + 6)
        articleHighlight.frame = CGRectMake(0, sourceName.frame.origin.y + sourceName.frame.size.height, bounds.size.width, bounds.size.height - sourceName.frame.origin.y + sourceName.frame.size.height)
    }
    
    func _update() {
        sourceName.text = source?.title
        articleHighlight.text = source?.highlightedArticle?.title
    }
    
    override func preferredLayoutAttributesFittingAttributes(layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attr: UICollectionViewLayoutAttributes = layoutAttributes.copy() as! UICollectionViewLayoutAttributes
        
        var newFrame = attr.frame
        self.frame = newFrame
        
        self.setNeedsLayout()
        self.layoutIfNeeded()
        
        let desiredHeight: CGFloat = self.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
        newFrame.size.height = desiredHeight
        attr.frame = newFrame
        return attr
    }
}

