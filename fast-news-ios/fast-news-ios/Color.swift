//
//  Color.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/23/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

extension UIColor {
    var hsva: (CGFloat, CGFloat, CGFloat, CGFloat) {
        get {
            var h: CGFloat = 0
            var s: CGFloat = 0
            var v: CGFloat = 0
            var a: CGFloat = 0
            if !getHue(&h, saturation: &s, brightness: &v, alpha: &a) {
                if getWhite(&v, alpha: &a) {
                    s = 0
                }
            }
            return (h,s,v,a)
        }
    }
    
    var rgba: (CGFloat, CGFloat, CGFloat, CGFloat) {
        get {
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            if !getRed(&r, green: &g, blue: &b, alpha: &a) {
                var brightness: CGFloat = 1
                if getWhite(&brightness, alpha: &a) {
                    r = brightness
                    g = brightness
                    b = brightness // TODO: this is not 100% correct
                }
            }
            return (r,g,b,a)
        }
    }
    
    func multiply(m: CGFloat) -> UIColor {
        let (h,s,v,a) = hsva
        return UIColor(hue: h, saturation: s, brightness: v*m, alpha: a)
    }
}
