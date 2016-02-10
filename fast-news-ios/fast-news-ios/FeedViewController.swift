//
//  FeedViewController.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/4/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class FeedViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    let feed = Feed.objectsForIDs(["shared"]).first! as! Feed
    var _feedSub: Subscription?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView!.registerClass(FeedCell.self, forCellWithReuseIdentifier: "Cell")
        _feedSub = feed.onUpdate.subscribe { [weak self] (state) -> () in
            self?._update()
        }
        _update()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "_foreground:", name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    let _preferredRecency: CFAbsoluteTime = 5 * 60
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        feed.ensureRecency(_preferredRecency)
    }
    
    func _foreground(notif: NSNotification) {
        feed.ensureRecency(_preferredRecency)
    }
    
    func _update() {
        collectionView?.reloadData()
        
        switch feed.loadingState {
        case .Error(_):
            title = NSLocalizedString("Offline", comment: "")
        case .Loading(_):
            title = NSLocalizedString("Refreshing…", comment: "")
        default:
            title = NSLocalizedString("fast-news", comment: "")
        }
    }
    
    // MARK: CollectionView
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return feed.sources?.count ?? 0
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! FeedCell
        cell.source = feed.sources![indexPath.item]
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(collectionView.bounds.size.width, 100)
    }
}

class FeedCell: UICollectionViewCell {
    let label = UILabel()
    var _sub: Subscription?
    
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
        if label.superview == nil {
            addSubview(label)
            backgroundColor = UIColor.whiteColor()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = bounds
    }
    
    func _update() {
        label.text = source?.title
    }
}
