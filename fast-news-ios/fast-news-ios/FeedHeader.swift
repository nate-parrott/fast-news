//
//  FeedHeader.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 10/26/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class FeedHeader: UIView {
    let label = UILabel()
    let logoImageView = UIImageView(image: UIImage(named: "TitleBarLogo")!)
    let blackBackground = UIView()
    let contentBackdrop = CAShapeLayer()
    
    override func willMoveToWindow(newWindow: UIWindow?) {
        super.willMoveToWindow(newWindow)
        if blackBackground.superview == nil {
            // do setup:
            addSubview(blackBackground)
            layer.addSublayer(contentBackdrop)
            addSubview(label)
            addSubview(logoImageView)
            
            blackBackground.backgroundColor = UIColor.blackColor()
            contentBackdrop.fillColor = UIColor.whiteColor().CGColor
            
            label.font = UIFont.systemFontOfSize(12, weight: UIFontWeightMedium)
            label.textAlignment = .Right
            label.alpha = 0.7
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let statusHeight: CGFloat = 20
        let contentFrame = CGRectMake(0, statusHeight, bounds.width, bounds.height - statusHeight)
        let padding = ArticleView.Padding
        
        logoImageView.sizeToFit()
        logoImageView.frame = CGRectMake(padding, contentFrame.origin.y + (contentFrame.height - logoImageView.frame.height)/2, logoImageView.frame.width, logoImageView.frame.height)
        let labelX = logoImageView.frame.origin.x + logoImageView.frame.size.width + padding
        label.frame = CGRectMake(labelX, contentFrame.origin.y, bounds.width - padding - labelX, contentFrame.height)
        
        let bgOverhang: CGFloat = 1000
        blackBackground.frame = CGRectMake(0, -bgOverhang, bounds.width, bounds.height + bgOverhang)
        contentBackdrop.path = UIBezierPath(roundedRect: contentFrame, byRoundingCorners: [.TopLeft, .TopRight], cornerRadii: CGSizeMake(4, 4)).CGPath
    }
    
    static let Height: CGFloat = 60
}
