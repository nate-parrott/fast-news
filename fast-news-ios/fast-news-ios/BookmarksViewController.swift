//
//  BookmarksViewController.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/12/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class BookmarksViewController: ArticleCollectionViewController {

    let bookmarkList = BookmarkList.Shared
    
    override var model: APIObject! {
        get {
            return bookmarkList
        }
    }
    
    override var cellClass: UICollectionViewCell.Type {
        return ArticleCell.self
    }
    
    override var modelTitle: String {
        get {
            return NSLocalizedString("Bookmarks", comment: "")
        }
    }
    
    override var collectionModels: [APIObject] {
        get {
            return bookmarkList.bookmarksIncludingOptimistic.filter({ $0.article != nil }).map({ $0.article! })
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
        showArticle(_collectionModelsForDisplay[indexPath.item] as! Article)
    }
    
    func showArticle(article: Article) {
        let articleVC = storyboard!.instantiateViewControllerWithIdentifier("Article") as! ArticleViewController
        articleVC.article = article
        articleVC.presentFrom(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView!.contentInset = UIEdgeInsetsMake(8 + topLayoutGuide.length, 0, 0, 0)
    }
    
    func scrollUp() {
        collectionView!.setContentOffset(CGPointZero, animated: true)
    }
    
    override func comparisonStringForModel(model: APIObject) -> String? {
        if let b = model as? Article {
            let t = b.title
            let s = b.articleDescription
            let src = b.url
            // TODO: make sure this is exhaustive
            return "\(t) \(s) \(src)"
        }
        return nil
    }
}
