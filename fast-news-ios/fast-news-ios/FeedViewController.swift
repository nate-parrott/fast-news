//
//  FeedViewController.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/4/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class FeedViewController: ArticleCollectionViewController {
    let feed = Feed.objectsForIDs(["shared"]).first! as! Feed
    
    override func applyModelToCell(cell: UICollectionViewCell, model: APIObject) {
        super.applyModelToCell(cell, model: model)
        let feedCell = cell as! FeedCell
        feedCell.source = (model as! Source)
        feedCell.onTappedSourceName = {
            [weak self] (let source) in
            self?.showSource(source)
        }
    }
    
    override var modelTitle: String {
        get {
            return NSLocalizedString("Latest Stories", comment: "")
        }
    }
    
    override var model: APIObject! {
        get {
            return feed
        }
    }
    override var collectionModels: [APIObject] {
        get {
            return feed.sources ?? []
        }
    }
    
    // MARK: Navigation
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let source = feed.sources![indexPath.item]
        if let article = source.highlightedArticle {
            showArticle(article)
        } else {
            showSource(source)
        }
    }
    
    func showArticle(article: Article) {
        let articleVC = storyboard!.instantiateViewControllerWithIdentifier("Article") as! ArticleViewController
        articleVC.article = article
        let nav = UINavigationController(rootViewController: articleVC)
        // articleVC.navigationItem.leftBarButtonItem = splitViewController!.displayModeButtonItem()
        showDetailViewController(nav, sender: true)
    }
    
    func showSource(source: Source) {
        let sourceVC = storyboard!.instantiateViewControllerWithIdentifier("Source") as! SourceViewController
        sourceVC.source = source
        navigationController!.pushViewController(sourceVC, animated: true)
    }
}

class FeedCell: UICollectionViewCell {
    let sourceName = UILabel()
    let articleHighlight = UILabel()
    var _sub: Subscription?
    
    var onTappedSourceName: ((source: Source) -> ())?
    
    var source: Source? {
        didSet {
            _setupIfNeeded()
            if let s = source {
                _sub = s.onUpdate.subscribe({ [weak self] (source) -> () in
                    self?._update()
                })
                _update()
            }
        }
    }
    
    func _setupIfNeeded() {
        if sourceName.superview == nil {
            addSubview(sourceName)
            addSubview(articleHighlight)
            sourceName.userInteractionEnabled = true
            sourceName.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "_tappedSourceName:"))
            backgroundColor = UIColor.whiteColor()
        }
    }
    
    func _tappedSourceName(tapRec: UITapGestureRecognizer) {
        if let t = onTappedSourceName {
            t(source: source!)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        sourceName.sizeToFit()
        sourceName.frame = CGRectMake(0, 0, bounds.size.width, sourceName.frame.size.height + 6)
        articleHighlight.frame = CGRectMake(0, sourceName.frame.origin.y + sourceName.frame.size.height, bounds.size.width, bounds.size.height - sourceName.frame.origin.y + sourceName.frame.size.height)
    }
    
    func _update() {
        sourceName.text = source?.title
        articleHighlight.text = source?.highlightedArticle?.title
    }
}
