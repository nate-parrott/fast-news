//
//  SearchBarCell.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 8/11/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class SourceSearchBarCell: UITableViewCell {
    var barFrame: CGRect {
        get {
            let barWidth = max(200, floor(bounds.size.width * 0.9 - 20))
            let height = SourceSearchBar.Height
            let size = CGSizeMake(barWidth, height)
            return CGRect(center: bounds.center, size: size)
        }
    }
}
