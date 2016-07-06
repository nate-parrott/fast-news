//
//  StatusView.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 7/6/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import Shimmer

class StatusView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.blackColor()
        label.textAlignment = .Center
        label.font = UIFont.boldSystemFontOfSize(14)
        label.textColor = UIColor(white: 0.8, alpha: 1)
        label.numberOfLines = 1
        
        addSubview(shimmer)
        shimmer.contentView = label
        
        shimmer.shimmeringPauseDuration = 0.1
        
        clipsToBounds = true
        
        label.alpha = 0
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let label = UILabel()
    let shimmer = FBShimmeringView()
    override func layoutSubviews() {
        super.layoutSubviews()
        shimmer.frame = bounds
        label.bounds = CGRectMake(0, 0, bounds.size.width - 20, height)
        label.center = bounds.center
    }
    let height: CGFloat = 26
}

