//
//  UIImage+Tiny.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/20/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

extension UIImage {
    class func fromTinyJson(tinyJson: [String: AnyObject]) -> UIImage? {
        if let size = tinyJson["size"] as? [Int] where size.count == 2,
            let pixels = tinyJson["pixels"] as? [[Int]] where pixels.count == size[0] * size[1] {
                let data = UnsafeMutablePointer<PixelData>.alloc(size.count)
                var i = 0
                for pixel in pixels {
                    if pixel.count >= 3 {
                        data[i] = PixelData(a: 255, r: UInt8(pixel[0]), g: UInt8(pixel[1]), b: UInt8(pixel[2]))
                    }
                    i += 1
                }
                let image = imageFromARGB32Bitmap(data, width: size[0], height: size[1])
                data.dealloc(size.count)
                
                var aspect: CGFloat = 1
                if let realSize = tinyJson["real_size"] as? [CGFloat] where realSize.count == 2 {
                    aspect = realSize[1] / max(1, realSize[0])// avoid divide-by-0
                }
                let x: CGFloat = 5
                let resizeTo = aspect > 1 ? CGSizeMake(x * aspect, x) : CGSizeMake(x, x / aspect)
                
                return image.resizeTo(resizeTo)
        } else {
            return nil
        }
    }
}
