//
//  AppDelegate.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/4/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

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
        
        /*delay(1) { () -> () in
            self.readArticle("http://testpage2.42pag.es")
        }*/
        
        return true
    }
    
    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        switch url.scheme {
            case "subscribed-article":
                if let comps = NSURLComponents(URL: url, resolvingAgainstBaseURL: false) {
                    if let url: String = (comps.queryItems ?? []).filter({ $0.name == "url" && $0.value != nil }).map({ $0.value! }).first {
                        // open it:
                        readArticle(url)
                        return true
                    }
                }
        default: ()
        }
        return false
    }
    
    func readArticle(url: String) {
        let article = Article(id: nil)
        article.importJson([ "url": url ])
        let articleVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("Article") as! ArticleViewController
        articleVC.article = article
        articleVC.presentFrom(viewControllerForModalPresentation())
    }
    
    func viewControllerForModalPresentation() -> UIViewController {
        var vc = window!.rootViewController!
        while let presented = vc.presentedViewController {
            vc = presented
        }
        return vc
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

