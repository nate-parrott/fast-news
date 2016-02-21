//
//  TextSegmentTableViewCell.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/19/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class TextSegmentTableViewCell: UITableViewCell {
    // MARK: Properties
    var margin = UIEdgeInsetsZero {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var string: NSAttributedString? {
        didSet {
            if let str = string {
                textStorage.setAttributedString(str)
            }
            setNeedsDisplay()
        }
    }
    
    // MARK: Text layout
    
    lazy var textLayoutManager: NSLayoutManager = {
        let layoutManager = NSLayoutManager()
        self.textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(self.textContainer)
        return layoutManager
    }()
    let textContainer = NSTextContainer()
    let textStorage = NSTextStorage()
    
    func height(size: CGSize) -> CGFloat {
        textContainer.size = CGSizeMake(size.width - margin.left - margin.right, size.height - margin.top - margin.bottom)
        return textLayoutManager.boundingRectForGlyphRange(textLayoutManager.glyphRangeForTextContainer(textContainer), inTextContainer: textContainer).size.height + margin.top + margin.bottom
    }
    
    var _draws = true
    override func drawRect(rect: CGRect) {
        if !_draws { return }
        textContainer.size = CGSizeMake(bounds.size.width - margin.left - margin.right, bounds.size.height - margin.top - margin.bottom)
        textLayoutManager.drawGlyphsForGlyphRange(textLayoutManager.glyphRangeForTextContainer(textContainer), atPoint: CGPointMake(margin.left, margin.top))
    }
    
    // MARK: Global sizing
    
    class func heightForString(string: NSAttributedString, width: CGFloat, margin: UIEdgeInsets) -> CGFloat {
        _SizingCell.margin = margin
        _SizingCell.string = string
        return _SizingCell.height(CGSizeMake(width, 99999))
    }
    
    static let _SizingCell: TextSegmentTableViewCell = {
        let cell = TextSegmentTableViewCell()
        cell._draws = false
        return cell
    }()
}
