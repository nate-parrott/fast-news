//
//  ViewCell.swift
//  fast-news-ios
//
//  Created by n8 on 8/3/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class ViewCell: UITableViewCell {
    var view: UIView? {
        didSet(old) {
            old?.removeFromSuperview()
            if let v = view {
                contentView.addSubview(v)
            }
        }
    }
    
    override func layoutSubviews() {
        view?.frame = bounds
    }
}
