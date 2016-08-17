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
        
        addSubview(border)
        
        addSubview(field)
        field.placeholder = "Search for or paste a site"
        field.returnKeyType = .Search
        field.autocapitalizationType = .None
        field.autocorrectionType = .No
        field.textAlignment = .Center
        field.backgroundColor = nil
        field.addTarget(self, action: #selector(SourceSearchBar._textChanged(_:)), forControlEvents: .ValueChanged)
        field.delegate = self
        
        addSubview(icon)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let field = UITextField()
    let icon = UIImageView(image: UIImage(named: "SearchIcon")!)
    let border = UIImageView(image: UIImage(named: "SearchBarBackground"))
    
    let query = Observable<String>(val: "")
    let active = Observable<Bool>(val: false)
    var results = [Source]() {
        didSet {
            _resultButtons = results.map({ (let source) -> UIButton in
                let b = UIButton()
                b.titleLabel!.textAlignment = .Left
                b.setTitle(source.title, forState: .Normal)
                b.addTarget(self, action: #selector(SourceSearchBar._tappedResult), forControlEvents: .TouchUpInside)
                b.setTitleColor(UIColor.blackColor(), forState: .Normal)
                return b
            })
        }
    }
    
    func _textChanged(sender: UITextFieldDelegate) {
        query.val = field.text ?? ""
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
    }
    
    var resultHeight: CGFloat = 44
    var _resultButtons = [UIButton]() {
        didSet(old) {
            for b in old {
                b.removeFromSuperview()
            }
            for v in _resultButtons {
                addSubview(v)
            }
        }
    }
    
    func _tappedResult(result: UIButton) {
        // TODO
    }
    
    // MARK: Layout
    static let Height: CGFloat = 42
    override func layoutSubviews() {
        let borderOverhang: CGFloat = 8
        border.frame = CGRectInset(bounds, -borderOverhang, -borderOverhang)
        field.frame = CGRectMake(10, 0, bounds.width - 20, SourceSearchBar.Height)
        
        icon.sizeToFit()
        let hasQuery = (field.text ?? "") != ""
        icon.hidden = hasQuery
        icon.center = CGPointMake(icon.frame.width/2 + 15, bounds.height/2)
        
        var i = 0
        var y: CGFloat = field.frame.size.height
        for button in _resultButtons {
            button.frame = CGRectMake(0, y, bounds.width, resultHeight)
            y += resultHeight
            button.backgroundColor = UIColor(white: i%2 == 0 ? 0.05 : 0, alpha: 1)
        }
    }
}
