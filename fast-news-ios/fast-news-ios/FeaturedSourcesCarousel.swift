//
//  FeaturedSourcesCarousel.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 8/11/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class FeaturedSourcesCarousel: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegate {
    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .Horizontal
        layout.itemSize = CGSizeMake(84, 100)
        super.init(frame: CGRectZero, collectionViewLayout: layout)
        registerClass(Cell.self, forCellWithReuseIdentifier: "Cell")
        showsHorizontalScrollIndicator = false
        decelerationRate = UIScrollViewDecelerationRateFast
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static let XInset: CGFloat = 14
    static let YInset: CGFloat = XInset/2
    static let Height: CGFloat = 100 + YInset * 2
    
    struct Content {
        let sources: [Source]
        let selectedIndices: [Int]
    }
    
    var content = Content(sources: [], selectedIndices: []) {
        didSet(old) {
            reloadData()
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return content.sources.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! Cell
        cell.source = content.sources[indexPath.item]
        cell.indicateSelected = content.selectedIndices.contains(indexPath.item)
        return cell
    }
    
    class Cell: UICollectionViewCell {
        var source: Source? {
            didSet {
                // TODO
            }
        }
        var indicateSelected = false {
            didSet {
                // TODO
            }
        }
    }
}

