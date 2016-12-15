//
//  RootViewController.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 7/6/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class RootViewController: UIViewController {
    class var Shared: RootViewController {
        get {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            return appDelegate.window!.rootViewController as! RootViewController
        }
    }
    
    var child: UIViewController!
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let tabViewController = segue.destinationViewController as! UITabBarController
        // tabViewController.tabBar.tintColor = FN_PURPLE
        // let splitViewController = tabViewController.viewControllers!.first as! UISplitViewController
        // splitViewController.delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        child = segue.destinationViewController
        setNeedsStatusBarAppearanceUpdate()
        setupTabBar(tabViewController)
    }
    func setupTabBar(barController: UITabBarController) {
//        for vc in barController.viewControllers ?? [] {
//            vc.tabBarItem.image = nil
//        }
//        barController.tabBarItem.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -20)
        
        for vc in barController.viewControllers ?? [] {
            if let item = vc.tabBarItem {
                item.titlePositionAdjustment = UIOffsetMake(0, 20)
                item.imageInsets = UIEdgeInsetsMake(5.5, 0, -5.5, 0)
            }
        }
        
    }
    override func childViewControllerForStatusBarStyle() -> UIViewController? {
        return child
    }
    override func childViewControllerForStatusBarHidden() -> UIViewController? {
        return child
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        child?.view.frame = view.bounds
        
        if let status = currentStatusView {
            let height: CGFloat = status.height
            status.frame = CGRectMake(20, view.bounds.height - 50 - 20 - height, view.bounds.width - 20 * 2, height)
        }
    }
    var statusItems = [StatusItem]() {
        didSet (old) {
            currentStatusItem = statusItems.last
        }
    }
    var currentStatusItem: StatusItem? {
        didSet(old) {
            if currentStatusItem !== old {
                if let item = currentStatusItem {
                    let view = StatusView()
                    view.item = item
                    currentStatusView = view
                } else {
                    currentStatusView = nil
                }
            }
        }
    }
    var currentStatusView: StatusView? {
        didSet(old) {
            if let oldView = old {
                UIView.animateWithDuration(0.15, delay: 0, options: [.AllowUserInteraction], animations: {
                        oldView.transform = CGAffineTransformMakeTranslation(0, 40)
                        oldView.alpha = 0
                    }, completion: { (_) in
                        oldView.removeFromSuperview()
                })
            }
            if let newView = currentStatusView {
                view.addSubview(newView)
                viewDidLayoutSubviews()
                newView.transform = CGAffineTransformMakeTranslation(0, 40)
                newView.alpha = 0
                UIView.animateWithDuration(0.15, delay: 0, options: [.AllowUserInteraction], animations: {
                    newView.transform = CGAffineTransformIdentity
                    newView.alpha = 1
                    }, completion: { (_) in
                        // pass
                })
            }
        }
    }
}
