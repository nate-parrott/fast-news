//
//  AppDelegate.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/4/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate, UITabBarControllerDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        if FN_USE_PRODUCTION {
            // EnableSPDY.enableSPDY()
        }
        
        KeyboardTracker.Shared // just make sure this is initialized
        
        let URLCache = NSURLCache(memoryCapacity: 40 * 1024 * 1024, diskCapacity: 0, diskPath: nil)
        NSURLCache.setSharedURLCache(URLCache)
        
        refresh()
        
        // print("UID: \(APIIdentity.Shared.id)")
        
        applyTheme()

        
        delay(2) { () -> () in
            // self.readArticle("http://testpage2.42pag.es")
            // self.readArticle("http://twitter.com/nateparrott")
            // self.readArticle("https://medium.com/hh-design/snapchat-reaction-emoji-a-prototype-372ba5de0bde#.4mv6jk16x")
            // self.readArticle("http://www.atlasobscura.com/articles/watch-the-saddest-political-balloon-drop-of-all-time")
            // self.readArticle("http://localhost:8081/test.html")
            
            /*let item = StatusItem(title: "hey this is a test")
            RootViewController.Shared.statusItems = [item]
            delay(3, closure: {
                RootViewController.Shared.statusItems = []
            })*/
            
            // self.readArticle("http://unparseable.42pag.es/")
        }
        
        return true
    }
    
    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        switch url.scheme! {
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
        Cache.Shared.saveAll()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        refresh()
    }
    
    func refresh() {
        delay(3) { 
            BookmarkList.Shared.ensureRecency(60) // 1 minute
        }
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        Cache.Shared.saveAll()
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
        // UINavigationBar.appearance().titleTextAttributes = [NSFontAttributeName: UIFont(name: "RobotoMono-Bold", size: 18)!]
        // UIBarButtonItem.appearanceWhenContainedInInstancesOfClasses([FNNavigationController.self]).setTitleTextAttributes([NSFontAttributeName: UIFont(name: "RobotoMono-Regular", size: 16)!], forState: .Normal)
        // UITabBarItem.appearance().setTitleTextAttributes([NSFontAttributeName: UIFont(name: "RobotoMono-Regular", size: 12)!, NSForegroundColorAttributeName: UIColor.whiteColor()], forState: .Selected)
        // UITabBarItem.appearance().setTitleTextAttributes([NSFontAttributeName: UIFont(name: "RobotoMono-Regular", size: 12)!, NSForegroundColorAttributeName: UIColor(white: 1, alpha: 0.5)], forState: .Normal)
        
        // UINavigationBar.appearanceWhenContainedInInstancesOfClasses([FNNavigationController.self]).titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        // UINavigationBar.appearanceWhenContainedInInstancesOfClasses([FNNavigationController.self]).setBackgroundImage(UIImage(named: "CoolGradient")?.stretchableImageWithLeftCapWidth(0, topCapHeight: 0), forBarPosition: .Any, barMetrics: .Default)
        // UINavigationBar.appearanceWhenContainedInInstancesOfClasses([FNNavigationController.self]).shadowImage = UIImage()

    }
}

