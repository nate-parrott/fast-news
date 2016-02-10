//
//  ArticleViewController.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/10/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class ArticleViewController: UIViewController {
    var article: Article!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = article.title
    }
}
