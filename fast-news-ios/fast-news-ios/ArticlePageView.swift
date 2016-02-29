//
//  ArticlePageView.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/28/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class ArticlePageView: UIView {
    var views = [(ArticleSegmentCell, CGFloat, CGFloat)]() { // (cell, y, height)
        willSet(newVal) {
            for v in views {
                v.0.removeFromSuperview()
            }
            for v in newVal {
                addSubview(v.0)
            }
            // clipsToBounds = true
        }
    }
    var marginTop: CGFloat = 0 {
        didSet {
            setNeedsLayout()
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        
        for v in views {
            v.0.frame = CGRectMake(0, v.1 + marginTop, bounds.size.width, v.2)
            v.0.autoresizingMask = [.FlexibleWidth, .FlexibleBottomMargin]
        }
        if let lastView = views.last?.0 {
            if maskView == nil {
                maskView = UIView()
                maskView!.backgroundColor = UIColor.whiteColor()
            }
            
            maskView!.frame = CGRectMake(0, marginTop, bounds.size.width, lastView.frame.bottom - marginTop)
            
            lastView.frame = CGRectMake(0, lastView.frame.origin.y, lastView.frame.size.width, lastView.frame.size.height + 20)
        }
    }
}
