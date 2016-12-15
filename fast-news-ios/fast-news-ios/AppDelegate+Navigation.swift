//
//  AppDelegate+Navigation.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 12/14/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

extension AppDelegate {
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
    
    var tabBarController: UITabBarController {
        get {
            let root = window!.rootViewController as! RootViewController
            return root.child as! UITabBarController
            return (window!.rootViewController as! RootViewController).child as! UITabBarController
        }
    }
    
    func showSubscriptionsTab(callback: (SubscriptionsViewController -> ())?) {
        // untested
        for tabVC in tabBarController.viewControllers! {
            if let nav = tabVC as? UINavigationController, let subsVC = nav.viewControllers.first as? SubscriptionsViewController {
                tabBarController.selectedIndex = tabBarController.viewControllers!.indexOf(tabVC)!
                if let cb = callback { cb(subsVC) }
            }
        }
    }
    
    func showFeedTab(callback: (FeedViewController -> ())?) {
        for tabVC in tabBarController.viewControllers! {
            if let nav = tabVC as? UINavigationController, let feedVC = nav.viewControllers.first as? FeedViewController {
                tabBarController.selectedIndex = tabBarController.viewControllers!.indexOf(tabVC)!
                if let cb = callback { cb(feedVC) }
            }
        }
    }
    
    func showSource(source: Source) {
        showFeedTab { (let feedVC) in
            feedVC.showSource(source)
        }
    }
}
