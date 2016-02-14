//
//  ArticleViewController.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/10/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class ArticleViewController: SwipeAwayViewController {
    var article: Article!
    var _articleSub: Subscription?
    
    @IBOutlet var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        _articleSub = article.onUpdate.subscribe({ [weak self] (_) -> () in
            self?.update()
        })
        update()
        article.ensureRecency(3 * 60 * 60)
    }
    func update() {
        title = article.title
        textView.text = article.text
    }
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
