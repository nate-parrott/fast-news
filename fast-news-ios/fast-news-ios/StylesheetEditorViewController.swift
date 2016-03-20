//
//  StylesheetEditorViewController.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 3/20/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

func presentHiddenSettingsUIFromArticle(article: ArticleViewController) {
    let nav = UIStoryboard(name: "CustomizationUI", bundle: nil).instantiateInitialViewController()! as! UINavigationController
    let editor = nav.viewControllers.first! as! StylesheetEditorViewController
    editor.style = Stylesheet()
    article.presentViewController(nav, animated: true, completion: nil)
}

class StylesheetEditorViewController: UIViewController, UITableViewDataSource, UITextFieldDelegate {
    
    @IBAction func dismiss() {
        navigationController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
    var style: Stylesheet! {
        didSet {
            _update()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        _update()
    }
    func _update() {
        loadViewIfNeeded()
        lineHeight.text = "\(style.lineHeight)"
        margin.text = "\(style.margins)"
        table.reloadData()
        table.backgroundColor = style.backgroundColor
    }
    @IBOutlet var table: UITableView!
    @IBAction func changeBackgroundColor(sender: AnyObject) {
        let colorPicker = CPColorPicker(nibName: "CPColorPicker", bundle: nil)
        colorPicker.color = style.backgroundColor
        colorPicker.callback = {
            [weak self] (color: UIColor?) in
            if let c = color, let style = self?.style {
                style.backgroundColor = c
                self?._update()
            }
        }
        NPSoftModalPresentationController.presentViewController(colorPicker)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return style.stylePairs.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! ElementStyleCell
        let (title, elStyle) = style.stylePairs[indexPath.row]
        cell.data = (elStyle, title)
        return cell
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let t = textField.text, let n = Float(t) {
            if textField === lineHeight {
                style.lineHeight = CGFloat(n)
            } else if textField == margin {
                style.margins = CGFloat(n)
            }
        }
        return true
    }
    @IBOutlet var lineHeight: UITextField!
    @IBOutlet var margin: UITextField!
}
