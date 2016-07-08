//
//  StatusBarOpacity+App.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 7/8/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

func SetStatusBarOpacity(opacity: CGFloat) {
    if let window = UIApplication.sharedApplication().valueForKey("statusBarWindow") as? UIWindow {
        window.alpha = opacity
    }
}
