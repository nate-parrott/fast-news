//
//  TextSegmentTableViewCell.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/19/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class TextSegmentTableViewCell: UITableViewCell {
        
    class func heightForString(string: NSAttributedString, width: CGFloat) -> CGFloat {
        return string.boundingRectWithSize(CGSizeMake(width - ArticleViewController.Margin * 2, 2000), options: .UsesLineFragmentOrigin, context: nil).size.height
    }
    
    var string: NSAttributedString? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func drawRect(rect: CGRect) {
        if let str = string {
            str.drawInRect(CGRectInset(bounds, ArticleViewController.Margin, 0))
        }
    }
}