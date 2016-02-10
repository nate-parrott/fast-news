//
//  ArticleCollectionViewController.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/10/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class ArticleCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    var model: APIObject! {
        get {
            return nil
        }
    }
    var collectionModels: [APIObject] {
        get {
            return []
        }
    }
    func applyModelToCell(cell: UICollectionViewCell, model: APIObject) {
        
    }
    var modelTitle: String {
        return ""
    }
    
    // MARK: Loading
    var _modelSub: Subscription?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        _modelSub = model.onUpdate.subscribe { [weak self] (state) -> () in
            self?.update()
        }
        update()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "_foreground:", name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    let _preferredRecency: CFAbsoluteTime = 5 * 60
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        model.ensureRecency(_preferredRecency)
    }
    
    func _foreground(notif: NSNotification) {
        model.ensureRecency(_preferredRecency)
    }
    
    func update() {
        collectionView?.reloadData()
        
        switch model.loadingState {
        case .Error(_):
            title = NSLocalizedString("Offline", comment: "")
        case .Loading(_):
            title = NSLocalizedString("Refreshing…", comment: "")
        default:
            title = NSLocalizedString("fast-news", comment: "")
        }
    }
    
    // MARK: Collection
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionModels.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath)
        applyModelToCell(cell, model: collectionModels[indexPath.item])
        return cell
    }
    
    // MARK: Layout
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(collectionView.bounds.size.width, 100)
    }
    
}
