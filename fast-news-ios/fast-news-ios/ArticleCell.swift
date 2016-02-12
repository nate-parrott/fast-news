//
//  ArticleCell.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/11/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class ArticleCell: UICollectionViewCell {
    var article: Article? {
        didSet {
            _setup()
            articleView.article = article
        }
    }
    let articleView = ArticleView()
    var _setupYet = false
    func _setup() {
        if !_setupYet {
            _setupYet = true
            addSubview(articleView)
        }
    }
    func _layout(width: CGFloat) -> CGFloat {
        let padding: CGFloat = 8
        let xPadding: CGFloat = 0
        let articleHeight = articleView.sizeThatFits(CGSizeMake(width - xPadding*2, 400)).height
        articleView.frame = CGRectMake(xPadding, padding, width - xPadding*2, articleHeight)
        return articleHeight + padding
    }
    override func sizeThatFits(size: CGSize) -> CGSize {
        return CGSizeMake(size.width, _layout(size.width))
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        _layout(bounds.size.width)
    }
}
