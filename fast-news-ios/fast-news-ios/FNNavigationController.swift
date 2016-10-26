//
//  FNNavigationController.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/28/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class FNNavigationController: UINavigationController {
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return viewControllers.last?.preferredStatusBarStyle() ?? .Default
    }
}
