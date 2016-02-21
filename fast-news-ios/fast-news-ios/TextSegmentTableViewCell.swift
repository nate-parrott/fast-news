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
    
    var _draws = true
    override func drawRect(rect: CGRect) {
        if !_draws { return }
        textContainer.size = CGSizeMake(bounds.size.width - margin.left - margin.right, bounds.size.height - margin.top - margin.bottom)
        let textOrigin = CGPointMake(margin.left, margin.top)
        textLayoutManager.drawGlyphsForGlyphRange(textLayoutManager.glyphRangeForTextContainer(textContainer), atPoint: textOrigin)
        /*for rect in lineRects() {
            let path = UIBezierPath(rect: rect)
            path.lineWidth = 1
            path.stroke()
        }*/
    }
    
    func lineRects() -> [CGRect] {
        let origin = CGPointMake(margin.left, margin.top)
        var rects = [CGRect]()
        var i = 0
        let glyphRange = textLayoutManager.glyphRangeForTextContainer(textContainer)
        let range = NSRangePointer.alloc(1)
        while i < glyphRange.length {
            let lineRect = textLayoutManager.lineFragmentRectForGlyphAtIndex(i, effectiveRange: range)
            i = range[0].location + range[0].length
            rects.append(lineRect + origin)
        }
        range.dealloc(1)
        return rects
    }
    
    // MARK: Global sizing
    
    class func heightForString(string: NSAttributedString, width: CGFloat, margin: UIEdgeInsets) -> CGFloat {
        return pageBreakPointsForSegment(string, width: width, margin: margin).last!
    }
    
    class func pageBreakPointsForSegment(string: NSAttributedString, width: CGFloat, margin: UIEdgeInsets) -> [CGFloat] {
        _SizingCell.margin = margin
        _SizingCell.string = string
        _SizingCell.textContainer.size = CGSizeMake(width - margin.left - margin.right, 99999)
        let rects = _SizingCell.lineRects()
        var points: [CGFloat] = [0]
        if let first = rects.first {
            points.append(first.origin.y)
        }
        points += rects.map({ $0.bottom })
        points.append(_SizingCell.textLayoutManager.boundingRectForGlyphRange(_SizingCell.textLayoutManager.glyphRangeForTextContainer(_SizingCell.textContainer), inTextContainer: _SizingCell.textContainer).size.height + margin.top + margin.bottom)
        return points
    }
    
    static let _SizingCell: TextSegmentTableViewCell = {
        let cell = TextSegmentTableViewCell()
        cell._draws = false
        return cell
    }()
}
