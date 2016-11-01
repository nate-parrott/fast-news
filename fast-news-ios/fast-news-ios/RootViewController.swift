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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(statusView)
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
    }
    override func childViewControllerForStatusBarStyle() -> UIViewController? {
        return child
    }
    override func childViewControllerForStatusBarHidden() -> UIViewController? {
        return child
    }
    var statusItems = [StatusItem]() {
        didSet (old) {
            if let item = statusItems.last {
                var otherItems = statusItems
                otherItems.removeLast(1)
                statusView.label.text = item.coalescleWithItems(otherItems).title
            }
            if (old.count > 0) != (statusItems.count > 0) {
                UIView.animateWithDuration(0.2, delay: 0, options: [.AllowUserInteraction], animations: {
                    self.statusView.label.alpha = self.statusItems.count > 0 ? 1 : 0
                    self.viewDidLayoutSubviews()
                    }, completion: nil)
                statusView.shimmer.shimmering = statusItems.count > 0
            }
        }
    }
    let statusView = StatusView(frame: CGRectZero)
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let statusHeight = statusItems.count == 0 ? 0 : statusView.height
        statusView.frame = CGRectMake(0, view.bounds.size.height - statusHeight, view.bounds.size.width, statusHeight)
        child?.view.frame = CGRectMake(0, 0, view.bounds.size.width, view.bounds.size.height - statusHeight)
    }
}
