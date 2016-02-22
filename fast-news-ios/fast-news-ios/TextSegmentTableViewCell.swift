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
    
    var segment: ArticleContent.TextSegment? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // MARK: Callbacks
    var onClickedLink: (NSURL -> ())?
    
    // MARK: Text layout
    
    lazy var textLayoutManager: NSLayoutManager = {
        let layoutManager = NSLayoutManager()
        self.textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(self.textContainer)
        self.textContainer.lineFragmentPadding = 0
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
        
        /*if let hangingText = segment?.hangingText, let firstLine = lineRects().first {
            let hangingTextFrame = CGRectMake(0, firstLine.origin.y, margin.left, firstLine.size.height)
            // used for bullets and stuff
            let hangingTextSize = hangingText.boundingRectWithSize(hangingTextFrame.size, options: .UsesLineFragmentOrigin, context: nil).size
            // center the text inside the hangingTextFrame:
            // UIBezierPath(rect: hangingTextSize.centeredInsideRect(hangingTextFrame)).stroke()
            var actualFrame = hangingTextSize.centeredInsideRect(hangingTextFrame)
            actualFrame.origin.x += 4
            hangingText.drawInRect(actualFrame)
        }*/
        /*
        for rect in lineRects() {
            let path = UIBezierPath(rect: rect)
            path.lineWidth = 1
            path.stroke()
        }*/
        _updateLinkRects()
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
    
    // MARK: Links
    func _updateLinkRects() {
        _linkRects = []
        if let str = string {
            str.enumerateAttribute(ArticleContent.LinkAttributeName, inRange: NSMakeRange(0, str.length), options: [], usingBlock: { (let valOpt, let range, _) -> Void in
                if let link = valOpt as? NSURL {
                    var rects = [CGRect]()
                    let glyphRange = self.textLayoutManager.glyphRangeForCharacterRange(range, actualCharacterRange: nil)
                    self.textLayoutManager.enumerateEnclosingRectsForGlyphRange(glyphRange, withinSelectedGlyphRange: NSMakeRange(NSNotFound, 0), inTextContainer: self.textContainer, usingBlock: { (let rect, _) -> Void in
                        rects.append(rect + CGPointMake(self.margin.left, self.margin.top))
                    })
                    self._linkRects += [(link, rects)]
                }
            })
        }
        if tapRec == nil {
            // set up the tapRec:
            tapRec = UITapGestureRecognizer(target: self, action: "_tapped:")
            addGestureRecognizer(tapRec!)
        }
    }
    
    var _linkRects = [(NSURL, [CGRect])]()
    var _highlightedLinkRectIndex: Int? {
        didSet {
            for v in _highlightViews {
                v.removeFromSuperview()
            }
            _highlightViews = []
            if let i = _highlightedLinkRectIndex where i < _linkRects.count {
                for rect in _linkRects[i].1 {
                    let v = UIView(frame: rect)
                    v.backgroundColor = UIColor(white: 0.2, alpha: 0.3)
                    addSubview(v)
                    _highlightViews.append(v)
                }
            }
        }
    }
    var _highlightViews = [UIView]()
    
    var tapRec: UITapGestureRecognizer?
    
    func _linkRectIndexAtPoint(pt: CGPoint) -> Int? {
        // find direct hits first:
        var i = 0
        for (_, rects) in _linkRects {
            for rect in rects {
                if CGRectContainsPoint(rect, pt) {
                    return i
                }
            }
            i++
        }
        // find close hits:
        i = 0
        let threshold: CGFloat = 20
        for (_, rects) in _linkRects {
            for rect in rects {
                if rect.distanceFromPoint(pt) <= threshold {
                    return i
                }
            }
            i++
        }
        return nil
    }
    
    func _tapped(rec: UITapGestureRecognizer) {
        if rec.state == .Began || rec.state == .Ended {
            _highlightedLinkRectIndex = _linkRectIndexAtPoint(rec.locationInView(self))
        }
        if rec.state == .Ended || rec.state == .Cancelled {
            if rec.state == .Ended {
                if let i = _highlightedLinkRectIndex where i < _linkRects.count, let callback = onClickedLink {
                    callback(_linkRects[i].0)
                }
            }
            _highlightedLinkRectIndex = nil
        }
    }
}
