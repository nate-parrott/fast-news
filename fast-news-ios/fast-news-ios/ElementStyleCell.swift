//
//  ElementStyleCell.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 3/20/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class ElementStyleCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    
    @IBAction func changeFont(sender: AnyObject) {
        let picker = SKFontPicker(style: .Plain)
        picker.fontName = data!.0.font.fontName
        picker.callback = {
            [weak self] (fontName: String?) in
            if let f = fontName, let style = self?.data?.0 {
                style.font = UIFont(name: f, size: style.font.pointSize)!
                self?._update()
            }
        }
        NPSoftModalPresentationController.presentViewController(picker)
    }
    @IBAction func changeColor(sender: AnyObject) {
        let colorPicker = CPColorPicker(nibName: "CPColorPicker", bundle: nil)
        colorPicker.color = data!.0.color
        colorPicker.callback = {
            [weak self] (color: UIColor?) in
            if let c = color, let style = self?.data?.0 {
                style.color = c
                self?._update()
            }
        }
        NPSoftModalPresentationController.presentViewController(colorPicker)
    }
    @IBAction func toggleUppercase() {
        data!.0.uppercase = !data!.0.uppercase
        _update()
    }
    
    var data: (Stylesheet.ElementStyle, String)? {
        didSet {
            _update()
        }
    }
    
    func _update() {
        if let (style, title) = data {
            titleLabel.text = style.uppercase ? title.uppercaseString : title
            titleLabel.font = style.font
            titleLabel.textColor = style.color
        }
    }
}
