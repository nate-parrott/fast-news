//
//  AppDelegate.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/4/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

let FN_USE_PRODUCTION = true

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        if FN_USE_PRODUCTION {
            EnableSPDY.enableSPDY()
        }
        applyTheme()
        // Override point for customization after application launch.
        let tabViewController = window!.rootViewController as! UITabBarController
        tabViewController.tabBar.tintColor = UIColor.whiteColor()
        let splitViewController = tabViewController.viewControllers!.first as! UISplitViewController
        // let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
        splitViewController.delegate = self
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    // MARK: - Split view

    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController:UIViewController, ontoPrimaryViewController primaryViewController:UIViewController) -> Bool {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        guard let topAsDetailController = secondaryAsNavController.topViewController else { return false }
        if (topAsDetailController as? ArticleViewController) == nil {
            return true // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
        } else {
            return false
        }
    }
    
    func applyTheme() {
        UINavigationBar.appearance().titleTextAttributes = [NSFontAttributeName: UIFont(name: "RobotoMono-Bold", size: 18)!]
        UIBarButtonItem.appearance().setTitleTextAttributes([NSFontAttributeName: UIFont(name: "RobotoMono-Regular", size: 16)!], forState: .Normal)
        UITabBarItem.appearance().setTitleTextAttributes([NSFontAttributeName: UIFont(name: "RobotoMono-Regular", size: 12)!, NSForegroundColorAttributeName: UIColor.whiteColor()], forState: .Selected)
        UITabBarItem.appearance().setTitleTextAttributes([NSFontAttributeName: UIFont(name: "RobotoMono-Regular", size: 12)!, NSForegroundColorAttributeName: UIColor(white: 1, alpha: 0.5)], forState: .Normal)

    }
}

