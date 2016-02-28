//
//  ImageSegmentTableViewCell.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/19/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class ImageSegmentTableViewCell: ArticleSegmentCell {
    
    let netImageView = NetImageView()
    
    override func willMoveToSuperview(newSuperview: UIView?) {
        super.willMoveToSuperview(newSuperview)
        if netImageView.superview == nil {
            // do some setup:
            contentView.addSubview(netImageView)
            netImageView.contentMode = .ScaleAspectFill
            clipsToBounds = true
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        netImageView.transform = CGAffineTransformIdentity
        netImageView.layer.anchorPoint = CGPointMake(0.5, 1)
        netImageView.frame = bounds
        
        let scale = (bounds.size.height + upwardExpansion) / bounds.size.height
        netImageView.transform = CGAffineTransformTranslate(CGAffineTransformMakeScale(scale, scale), 0, translateY)
        
        _imageSize = bounds.size
    }
    
    class func heightForSegment(seg: ArticleContent.ImageSegment, width: CGFloat, maxHeight: CGFloat) -> CGFloat {
        if let size = seg.size {
            return min(maxHeight, size.height * width / size.width)
        } else {
            return 180
        }
    }
    
    var segment: ArticleContent.ImageSegment? {
        didSet {
            if let seg = segment, let urlString = seg.url, let url = NSURL(string: urlString) {
                self._imageURL = url
            } else {
                self._imageURL = nil
            }
        }
    }
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        upwardExpansion = 0
        translateY = 0
        clipsToBounds = true
    }
    
    var _imageSize = CGSizeZero {
        didSet {
            _load()
        }
    }
    var _imageURL: NSURL? {
        didSet {
            _load()
        }
    }
    func _load() {
        if let url = _imageURL {
            let mirrored = NetImageView.mirroredURLForImage(url.absoluteString, size: _imageSize * UIScreen.mainScreen().scale)
            netImageView.setURL(mirrored, placeholder: segment?.tinyImage)
        }
    }
    
    var upwardExpansion: CGFloat = 0 {
        didSet {
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    
    var translateY: CGFloat = 0 {
        didSet {
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
}
