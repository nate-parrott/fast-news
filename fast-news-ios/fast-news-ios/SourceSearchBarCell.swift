//
//  SearchBarCell.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 8/11/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class SourceSearchBarCell: UITableViewCell {
    var searchBar: SourceSearchBar? {
        didSet(old) {
            if old !== searchBar {
                old?.removeFromSuperview()
            }
            if let bar = searchBar {
                contentView.addSubview(bar)
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let barWidth = max(200, floor(bounds.size.width * 0.9 - 20))
        if let bar = searchBar {
            bar.bounds = CGRectMake(0, 0, barWidth, bounds.size.height)
            bar.center = bounds.center
        }
    }
}
