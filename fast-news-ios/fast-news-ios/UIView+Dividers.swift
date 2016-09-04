//
//  UICollectionViewCell+Dividers.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 9/4/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

extension UIView {
    func addDividers() {
        let height: CGFloat = 1.0 / UIScreen.mainScreen().scale
        let color = UIColor(white: 0.5, alpha: 0.3)
        for isTop in [true, false] {
            let y = isTop ? 0 : bounds.size.height - height
            let divider = UIView(frame: CGRectMake(0, y, bounds.size.width, height))
            divider.backgroundColor = color
            addSubview(divider)
            divider.autoresizingMask = isTop ? [.FlexibleWidth, .FlexibleBottomMargin] : [.FlexibleWidth, .FlexibleTopMargin]
        }
    }
}
