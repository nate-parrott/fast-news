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
    let header = FeedHeader()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.addSubview(header)
        
        let s = statusText
        statusText = s
        
        collectionView?.contentInset = UIEdgeInsetsMake(FeedHeader.Height, 0, 0, 0)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        header.frame = CGRectMake(0, -FeedHeader.Height, collectionView!.bounds.width, FeedHeader.Height)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    var statusText = "" {
        didSet {
            header.label.text = statusText.uppercaseString
        }
    }
    
    override var displayTitle: String? {
        get {
            return statusText
        }
        set (val) {
            statusText = val ?? ""
        }
    }
    
    // MARK: Article VC overrides
    
    override func applyModelToCell(cell: UICollectionViewCell, model: APIObject) {
        super.applyModelToCell(cell, model: model)
        let feedCell = cell as! FeedCell
        feedCell.source = (model as! Source)
        feedCell.onTappedSourceName = {
            [weak self] (let source) in
            self?.showSource(source)
        }
//        feedCell.onTappedSource = {
//            [weak self] (let source) in
//            self?.showSource(source)
//        }
//        feedCell.onTappedArticle = {
//            [weak self] (let article) in
//            self?.showArticle(article)
//        }
    }
    
    override var cellClass: UICollectionViewCell.Type {
        return FeedCell.self
    }
    
    override var modelTitle: String {
        get {
            // return NSDateFormatter.localizedStringFromDate(NSDate(), dateStyle: .MediumStyle, timeStyle: .NoStyle)
            let fmt = NSDateFormatter()
            fmt.setLocalizedDateFormatFromTemplate("EEEE, MMMM d")
            return fmt.stringFromDate(NSDate())
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
    
    let padding: CGFloat = 8
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let article = (_collectionModelsForDisplay[indexPath.item] as! Source).highlightedArticle {
            showArticle(article)
        }
    }
    
    /*func collectionView(collectionView: UICollectionView, heightForItemAtIndex: NSIndexPath, width: CGFloat) -> CGFloat {
        let source = collectionModels[heightForItemAtIndex.item] as! Source
        return VerticalFeedCell.HeightForSource(source, width: width)
    }*/
    
    // MARK: Navigation
    
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
    
    func scrollUp() {
        collectionView!.setContentOffset(CGPointZero, animated: true)
    }
}


