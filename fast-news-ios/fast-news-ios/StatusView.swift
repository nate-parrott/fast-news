//
//  StatusView.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 7/6/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class StatusView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(hex: "#272727")
        
        label.textAlignment = .Center
        label.font = UIFont.boldSystemFontOfSize(12)
        label.textColor = UIColor.whiteColor()
        label.numberOfLines = 0
        label.lineBreakMode = .ByWordWrapping
        addSubview(label)
        
        let swipeRec = UISwipeGestureRecognizer(target: self, action: #selector(StatusView.dismiss))
        addGestureRecognizer(swipeRec)
        
        let tapRec = UITapGestureRecognizer(target: self, action: #selector(StatusView.tapped))
        addGestureRecognizer(tapRec)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    var item: StatusItem? {
        didSet {
            if let i = item {
                label.text = i.title
                iconView = i.iconView
            }
        }
    }
    
    let label = UILabel()
    
    var iconView: UIView? {
        didSet(old) {
            old?.removeFromSuperview()
            if let v = iconView {
                addSubview(v)
            }
        }
    }
    let horizontalPadding: CGFloat = 40
    let verticalPadding: CGFloat = 14
    
    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = CGRectMake(horizontalPadding, verticalPadding, bounds.width - horizontalPadding * 2, bounds.height - verticalPadding * 2)
        iconView?.sizeToFit()
        iconView?.center = CGPointMake(bounds.width - horizontalPadding/2, bounds.height / 2)
        
        layer.shadowOffset = CGSizeMake(0, 3)
        layer.shadowRadius = 10
        layer.shadowPath = UIBezierPath(rect: bounds).CGPath
        layer.shadowColor = UIColor(white: 0, alpha: 0.5).CGColor
        layer.shadowOpacity = 1
    }
    
    var height: CGFloat {
        get {
            return 60
        }
    }
    
    func dismiss() {
        item?.remove()
    }
    
    func tapped() {
        item?.tapped()
        dismiss()
    }
}

