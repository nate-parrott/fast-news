//
//  FeedViewController.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/4/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class FeedViewController: ArticleCollectionViewController {
    
    // MARK: Lifecycle
    
    let feed = Feed.objectsForIDs(["shared"]).first! as! Feed
    
    // MARK: Article VC overrides
    
    override func applyModelToCell(cell: UICollectionViewCell, model: APIObject) {
        super.applyModelToCell(cell, model: model)
        let feedCell = cell as! FeedCell
        feedCell.source = (model as! Source)
        feedCell.onTappedSourceName = {
            [weak self] (let source) in
            self?.showSource(source)
        }
    }
    
    override var cellClass: UICollectionViewCell.Type {
        return FeedCell.self
    }
    
    override var modelTitle: String {
        get {
            return NSLocalizedString("Subscribed", comment: "")
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
    override func getPreloadObjectForModel(model: APIObject) -> AnyObject? {
        if let article = (model as! Source).highlightedArticle, let imageUrl = article.imageURL {
            let netImage = NetImageView()
            netImage.url = ArticleView.resizedURLForImageAtURL(imageUrl)
            return netImage
        } else {
            return nil
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
        // let nav = UINavigationController(rootViewController: articleVC)
        // articleVC.navigationItem.leftBarButtonItem = splitViewController!.displayModeButtonItem()
        // showDetailViewController(nav, sender: true)
        articleVC.presentFrom(self)
    }
    
    func showSource(source: Source) {
        let sourceVC = storyboard!.instantiateViewControllerWithIdentifier("Source") as! SourceViewController
        sourceVC.source = source
        navigationController!.pushViewController(sourceVC, animated: true)
    }
}
