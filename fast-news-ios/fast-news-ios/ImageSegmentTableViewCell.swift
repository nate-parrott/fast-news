//
//  ImageSegmentTableViewCell.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/19/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class ImageSegmentTableViewCell: UITableViewCell {
    
    let netImageView = NetImageView()
    
    override func willMoveToSuperview(newSuperview: UIView?) {
        super.willMoveToSuperview(newSuperview)
        if netImageView.superview == nil {
            // do some setup:
            contentView.addSubview(netImageView)
            netImageView.contentMode = .ScaleAspectFill
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        netImageView.frame = bounds
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
            netImageView.url = NetImageView.mirroredURLForImage(url.absoluteString, size: _imageSize * UIScreen.mainScreen().scale)
        }
    }
}
