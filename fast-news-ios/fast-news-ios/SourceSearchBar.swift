//
//  SourceSearchBar.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 8/11/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class SourceSearchBar: UIView, UITextFieldDelegate {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(background)
        
        addSubview(resultsContainer)
        resultsContainer.clipsToBounds = true
        resultsContainer.layer.cornerRadius = 20
        
        addSubview(field)
        field.placeholder = "Search for or paste a site"
        field.returnKeyType = .Search
        field.autocapitalizationType = .None
        field.autocorrectionType = .No
        field.textAlignment = .Center
        field.backgroundColor = nil
        field.addTarget(self, action: #selector(SourceSearchBar._textChanged(_:)), forControlEvents: .EditingChanged)
        field.delegate = self
        
        addSubview(icon)
        
        addSubview(border)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let field = UITextField()
    let icon = UIImageView(image: UIImage(named: "SearchIcon")!)
    let background = UIImageView(image: UIImage(named: "SearchBarBackground"))
    let border = UIImageView(image: UIImage(named: "SearchBarBorder"))
    let resultsContainer = UIView()
    
    let query = Observable<String>(val: "")
    let active = Observable<Bool>(val: false)
    var results = [Result]() {
        didSet {
            _resultButtons = results.map({ (let result) -> UIButton in
                let b = UIButton()
                b.titleLabel!.textAlignment = .Left
                b.setTitle(result.title, forState: .Normal)
                b.addTarget(self, action: #selector(SourceSearchBar._tappedResult), forControlEvents: .TouchUpInside)
                b.setTitleColor(UIColor(white: result.grayed ? 0.35 : 0, alpha :1), forState: .Normal)
                b.titleLabel!.font = self.field.font
                b.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10)
                b.userInteractionEnabled = (result.callback != nil)
                b.titleLabel!.lineBreakMode = .ByTruncatingTail
                return b
            })
            _updateHeight()
        }
    }
    
    struct Result {
        let title: String
        let callback: (() -> ())?
        let grayed: Bool
    }
    
    func _textChanged(sender: UITextField) {
        query.val = field.text ?? ""
        if query.val == "" { results = [] }
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        active.val = true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        active.val = false
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // TODO: should we execute the default action (select the first result)?
        return false
    }
    
    func cancelEditing() {
        field.text = ""
        field.resignFirstResponder()
        active.val = false
        results = []
    }
    
    var resultHeight: CGFloat = 44
    var _resultButtons = [UIButton]() {
        didSet(old) {
            for b in old {
                b.removeFromSuperview()
            }
            for v in _resultButtons {
                resultsContainer.addSubview(v)
            }
            _updateHeight()
            setNeedsLayout()
        }
    }
    
    func _tappedResult(resultButton: UIButton) {
        let result = results[_resultButtons.indexOf(resultButton)!]
        if let cb = result.callback {
            cb()
        }
    }
    
    // MARK: Layout
    static let Height: CGFloat = 42
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let borderOverhang: CGFloat = 8
        background.frame = CGRectInset(bounds, -borderOverhang, -borderOverhang)
        border.frame = background.frame
        field.frame = CGRectMake(10, 0, bounds.width - 20, SourceSearchBar.Height)
        
        icon.sizeToFit()
        let hasQuery = (field.text ?? "") != ""
        icon.hidden = hasQuery
        icon.center = CGPointMake(icon.frame.width/2 + 15, field.frame.height/2)
        
        resultsContainer.frame = CGRectMake(0, 0, bounds.width, bounds.height)
        
        var i = 0
        for button in _resultButtons {
            let y = CGFloat(i) * resultHeight + field.frame.size.height
            button.frame = CGRectMake(0, y, bounds.width, resultHeight)
            button.backgroundColor = UIColor(white: i%2 == 0 ? 1-0.05 : 1, alpha: 1)
            i += 1
        }
    }
    
    var maximumHeight: CGFloat = 99999 {
        didSet (old) {
            if maximumHeight != old {
                _updateHeight()
            }
        }
    }
    
    func _updateHeight() {
        frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, _heightWithMaximumHeight(maximumHeight))
    }
    
    func _heightWithMaximumHeight(maxHeight: CGFloat) -> CGFloat {
        var barHeight = SourceSearchBar.Height
        if !active.val || query.val == "" {
            return barHeight
        }
        for _ in results {
            let newHeight = barHeight + resultHeight
            if newHeight > maxHeight {
                return barHeight
            } else {
                barHeight = newHeight
            }
        }
        return barHeight
    }
}
