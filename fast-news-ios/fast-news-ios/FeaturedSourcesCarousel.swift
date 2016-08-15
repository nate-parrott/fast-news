//
//  FeaturedSourcesCarousel.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 8/11/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class FeaturedSourcesCarouselCell: UITableViewCell {
    let carousel = FeaturedSourcesCarousel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(carousel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        carousel.frame = bounds
    }
}

class FeaturedSourcesCarousel: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegate {
    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .Horizontal
        layout.itemSize = CGSizeMake(84, FeaturedSourcesCarousel.ThumbnailHeight)
        layout.minimumInteritemSpacing = FeaturedSourcesCarousel.XInset
        super.init(frame: CGRectZero, collectionViewLayout: layout)
        registerClass(Cell.self, forCellWithReuseIdentifier: "Cell")
        showsHorizontalScrollIndicator = false
        decelerationRate = UIScrollViewDecelerationRateFast
        backgroundColor = UIColor.groupTableViewBackgroundColor()
        dataSource = self
        delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static let XInset: CGFloat = 14
    static let YInset: CGFloat = XInset/2
    static let ThumbnailHeight: CGFloat = 100
    static let Height: CGFloat = ThumbnailHeight + 20 + YInset * 2
    
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
        let label = UILabel()
        let thumbnail = UIView()
        let imageView = NetImageView()
        var _setupYet = false
        var source: Source? {
            didSet {
                // TODO
                if !_setupYet {
                    _setupYet = true
                    addSubview(label)
                    addSubview(thumbnail)
                    addSubview(imageView)
                    label.textAlignment = .Center
                    label.font = UIFont.systemFontOfSize(12)
                    label.textColor = UIColor(hexString: "#6D6D72")
                    thumbnail.layer.cornerRadius = 7
                    imageView.contentMode = .ScaleAspectFit
                }
                if let s = source {
                    label.text = s.shortTitle ?? s.title
                    thumbnail.backgroundColor = s.color ?? UIColor.whiteColor()
                    if let iconUrl = s.iconUrl {
                        let imageSize = CGSizeMake(FeaturedSourcesCarousel.ThumbnailHeight * 3, FeaturedSourcesCarousel.ThumbnailHeight * 3)
                        imageView.setURL(NetImageView.mirroredURLForImage(iconUrl, size: imageSize), placeholder: nil)
                    } else {
                        imageView.setURL(nil, placeholder: nil)
                    }
                }
            }
        }
        var indicateSelected = false {
            didSet {
                // TODO
            }
        }
        override func layoutSubviews() {
            super.layoutSubviews()
            let t = FeaturedSourcesCarousel.ThumbnailHeight
            thumbnail.frame = CGRectMake(0, 0, bounds.width, t)
            imageView.frame = CGRectInset(thumbnail.frame, 15, 15)
            label.frame = CGRectMake(0, t, bounds.width, bounds.height - t)
        }
    }
}

