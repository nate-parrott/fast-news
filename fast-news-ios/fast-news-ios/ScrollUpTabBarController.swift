//
//  ScrollUpTabBarController.swift
//  fast-news-ios
//
//  Created by Justin Brower on 9/13/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation

class ScrollUpTabBarController : UITabBarController, UITabBarControllerDelegate {
    override func viewWillAppear(animated: Bool) {
        print("Assigned delegate")
        self.delegate = self;
        super.viewWillAppear(animated)
    }
    
    var lastViewController : UIViewController?
    
    func tabBarController(_didSelectViewController viewController: UIViewController) {
        if (viewController == lastViewController) {
            if let controller = viewController as? ScrollUpController {
                // for regular VC, scroll right to top.
                controller.scrollUp();
            } else if let controller = viewController as? UINavigationController {
                // for navigation controller, pick out the first VC and call scroll up.
                if controller.viewControllers.count == 1 {
                    if let scrollController = controller.viewControllers[0] as? ScrollUpController {
                        scrollController.scrollUp()
                    }
                }
            }
        }
        lastViewController = viewController
    }
}
