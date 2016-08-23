//
//  MasonryCollectionViewLayout.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 8/22/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

protocol MasonryCollectionViewLayoutDelegate: UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, heightForItemAtIndex: NSIndexPath, width: CGFloat) -> CGFloat
}

class MasonryCollectionViewLayout: UICollectionViewLayout {
    let roughColumnWidth: CGFloat = 140
    let padding: CGFloat = 8
    
    var nColumns: Int {
        get {
            let w = collectionView?.bounds.size.width ?? 0
            return Int(max(1, floor(w / roughColumnWidth)))
        }
    }
    
    var layoutAttributes = [NSIndexPath: UICollectionViewLayoutAttributes]()
    var height: CGFloat = 0
    
    func allIndexPaths() -> [NSIndexPath] {
        var paths = [NSIndexPath]()
        if let collection = collectionView, let dataSource = collection.dataSource {
            var nSections = 1
            if let fn = dataSource.numberOfSectionsInCollectionView {
                nSections = fn(collection)
            }
            for section in 0..<nSections {
                let count = dataSource.collectionView(collection, numberOfItemsInSection: section)
                for i in 0..<count {
                    paths.append(NSIndexPath(forItem: i, inSection: section))
                }
            }
        }
        return paths
    }
    
    override func prepareLayout() {
        super.prepareLayout()
        layoutAttributes.removeAll()
        let w: CGFloat = collectionView?.bounds.size.width ?? 0
        let colWidth: CGFloat = (w - (CGFloat(nColumns) + 1) * padding) / CGFloat(nColumns)
        var columnHeights: [CGFloat] = (0..<nColumns).map({ _ in self.padding })
        for indexPath in allIndexPaths() {
            let colIndex = columnHeights.indexOf(columnHeights.minElement()!)!
            let height = heightForItem(indexPath, width: colWidth)
            let attr = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
            attr.frame = CGRectMake(colWidth * CGFloat(colIndex) + padding * CGFloat(colIndex + 1), columnHeights[colIndex], colWidth, height)
            layoutAttributes[indexPath] = attr
            columnHeights[colIndex] += height + padding
        }
        height = columnHeights.maxElement()!
    }
    
    func heightForItem(index: NSIndexPath, width: CGFloat) -> CGFloat {
        if let source = collectionView?.delegate as? MasonryCollectionViewLayoutDelegate {
            return source.collectionView(collectionView!, heightForItemAtIndex: index, width: width)
        }
        return 100
    }
    
    override func collectionViewContentSize() -> CGSize {
        let w: CGFloat = collectionView?.bounds.size.width ?? 0
        return CGSizeMake(w, height)
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return layoutAttributes.values.filter({ (let layout) -> Bool in
            return CGRectIntersectsRect(rect, layout.frame)
        })
    }
}
