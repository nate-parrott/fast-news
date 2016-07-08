//
//  SwipePager.swift
//  SwipePager
//
//  Created by Nate Parrott on 2/28/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class SwipePager<T:Hashable>: UIView, UIScrollViewDelegate {
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.delegate = self
        scrollViewDidScroll(scrollView)
        scrollView.pagingEnabled = true
        
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = true
    }
    
    let scrollView = UIScrollView()
    let contentView = UIView()
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        _updatePosition()
        if let o = onScroll {
            o(scrollView.contentOffset.y)
        }
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            _notifyIfPageChanged()
        }
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        _notifyIfPageChanged()
    }
    
    func _notifyIfPageChanged() {
        if let p = page where p != _prevPage {
            _prevPage = p
            if let cb = onPageChanged {
                cb(p)
            }
        }
    }
    
    func _updatePosition() {
        contentView.center = CGPointMake(bounds.size.width/2, bounds.size.height/2 + scrollView.contentOffset.y)
        if scrollView.bounds.size.height > 0 {
            if scrollView.contentOffset.y == 0 {
                position = (0, 0)
            } else {
                let page: CGFloat = floor(scrollView.contentOffset.y / scrollView.bounds.size.height)
                position = (Int(page), scrollView.contentOffset.y / scrollView.bounds.size.height - page)
            }
        }
    }
    
    var pageModels = [T]() {
        didSet {
            _viewsOnscreen.removeAll()
            let p = position
            position = p
            scrollView.contentSize = CGSizeMake(bounds.size.width, bounds.size.height * CGFloat(pageModels.count))
        }
    }
    func reload() {
        let p = position
        _viewsOnscreen.removeAll()
        position = p
    }
    var createPageForModel: (T -> UIView)!
    var updateLayout: (SwipePager -> ())? {
        didSet {
            if let fn = updateLayout {
                fn(self)
            }
        }
    }
    
    var position: (Int, CGFloat) = (0, 0.0) {
        didSet {
            _loadViewsForModelIndices = [position.0-1, position.0, position.0+1]
            _updatePagePositions()
        }
    }
    
    var _loadViewsForModelIndices = [Int]() {
        didSet {
            let models = _loadViewsForModelIndices.filter({ $0 >= 0 && $0 < self.pageModels.count }).map({ self.pageModels[$0] })
            var views = [T: UIView]()
            for model in models {
                views[model] = _viewsOnscreen[model] ?? createPageForModel(model)
            }
            _viewsOnscreen = views
        }
    }
    
    var page: Int? {
        get {
            let i = position.1 > 0.5 ? position.0 + 1 : position.0
            if pageModels.count > 0 {
                return max(0, min(i, pageModels.count - 1))
            } else {
                return nil
            }
        }
        set(val) {
            if let v = val {
                scrollView.contentOffset = CGPointMake(0, bounds.size.height * CGFloat(v))
            }
        }
    }
    
    var _prevPage: Int = 0
    var onPageChanged: (Int -> ())?
    
    var onScroll: (CGFloat -> ())?
    
    var _viewsOnscreen = [T: UIView]() {
        willSet(newVal) {
            for v in _viewsOnscreen.values {
                if !newVal.values.contains(v) {
                    v.removeFromSuperview()
                }
            }
            for v in newVal.values {
                if v.superview == nil {
                    contentView.addSubview(v)
                }
            }
        }
    }
    
    var _lastLaidOutAtBounds = CGSizeZero
    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = bounds
        contentView.frame = bounds
        _updatePosition()
        
        let contentSize = CGSizeMake(bounds.size.width, bounds.size.height * CGFloat(pageModels.count))
        if !CGSizeEqualToSize(contentSize, scrollView.contentSize) {
            scrollView.contentSize = contentSize
        }
        if !CGSizeEqualToSize(_lastLaidOutAtBounds, bounds.size) {
            _lastLaidOutAtBounds = bounds.size
            if let fn = updateLayout {
                fn(self)
            }
        }
        _updatePagePositions()
    }
    
    func _updatePagePositions() {
        for i in _loadViewsForModelIndices {
            if i >= 0 && i < pageModels.count {
                let model = pageModels[i]
                let view = _viewsOnscreen[model]!
                let pos = CGFloat(i - position.0) - position.1
                view.bounds = bounds
                view.center = CGPointMake(bounds.size.width/2, bounds.size.height/2)
                view.transform = CGAffineTransformMakeTranslation(0, pos * bounds.size.height)
            }
        }
    }
}
