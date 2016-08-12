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
    var results = [Source]() {
        didSet {
            _update()
        }
    }
    
    func _update() {
        // TODO
        setNeedsLayout()
    }
    
    func _textChanged(sender: UITextFieldDelegate) {
        query.val = field.text ?? ""
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        _update()
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        _update()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // TODO: should we execute the default action (select the first result)?
        return false
    }
    
    // MARK: Layout
    static let Height: CGFloat = 42
    override func layoutSubviews() {
        let borderOverhang: CGFloat = 8
        border.frame = CGRectInset(bounds, -borderOverhang, -borderOverhang)
        field.frame = CGRectMake(10, 0, bounds.width - 20, SourceSearchBar.Height)
        
        icon.sizeToFit()
        let hasQuery = (field.text ?? "") != ""
        icon.hidden = !hasQuery
        icon.center = CGPointMake(icon.frame.width/2 + 15, bounds.height/2)
    }
}
