//
//  UIImage+ApplyTint.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 7/9/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

extension UIImage {
    func applyTint(color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        CGContextClipToMask(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, size.width, size.height), CGImage!)
        color.setFill()
        UIBezierPath(rect: CGRectMake(0, 0, size.width, size.height)).fill()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
