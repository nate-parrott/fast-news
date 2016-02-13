//
//  SourceViewController.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/10/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class SourceViewController: ArticleCollectionViewController {
    var source: Source!
    
    override var model: APIObject! {
        get {
            return source
        }
    }
    
    override var cellClass: UICollectionViewCell.Type {
        return ArticleCell.self
    }
    
    override var modelTitle: String {
        get {
            return source.title ?? NSLocalizedString("Articles", comment: "")
        }
    }
    
    override var collectionModels: [APIObject] {
        get {
            return source.articles ?? []
        }
    }
    
    override func applyModelToCell(cell: UICollectionViewCell, model: APIObject) {
        super.applyModelToCell(cell, model: model)
        (cell as! ArticleCell).article = (model as! Article)
    }
    
    override func getPreloadObjectForModel(model: APIObject) -> AnyObject? {
        if let imageUrl = (model as! Article).imageURL {
            let netImage = NetImageView()
            netImage.url = ArticleView.resizedURLForImageAtURL(imageUrl)
            return netImage
        } else {
            return nil
        }
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        showArticle(collectionModels[indexPath.item] as! Article)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView!.contentInset = UIEdgeInsetsMake(8, 0, 0, 0)
    }
    
    func showArticle(article: Article) {
        let articleVC = storyboard!.instantiateViewControllerWithIdentifier("Article") as! ArticleViewController
        articleVC.article = article
        let nav = UINavigationController(rootViewController: articleVC)
        // articleVC.navigationItem.leftBarButtonItem = splitViewController!.displayModeButtonItem()
        showDetailViewController(nav, sender: true)
    }
}
