//
//  TopAlignedLabel.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 10/26/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

// from http://stackoverflow.com/questions/28605341/vertically-align-text-within-a-uilabel-note-using-autolayout

@IBDesignable class TopAlignedLabel: UILabel {
    override func drawTextInRect(rect: CGRect) {
        if let attributed = attributedText {
            let height = attributed.boundingRectWithSize(CGSizeMake(bounds.width, 10000), options: NSStringDrawingOptions.UsesLineFragmentOrigin, context: nil).height
            super.drawTextInRect(CGRectMake(0, 0, bounds.width, min(bounds.height, ceil(height))))
        } else {
            super.drawTextInRect(rect)
        }
    }
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        layer.borderWidth = 1
        layer.borderColor = UIColor.blackColor().CGColor
    }
}
