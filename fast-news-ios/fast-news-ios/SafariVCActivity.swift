//
//  SafariVCActivity.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/23/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import SafariServices

@objc class SafariVCActivityOverrideURL: NSObject {
    init(url: NSURL) {
        self.url = url
    }
    let url: NSURL
}

class SafariVCActivity: UIActivity, SFSafariViewControllerDelegate {
    
    init(parentViewController: UIViewController) {
        self.parentViewController = parentViewController
        super.init()
    }
    
    var url: NSURL?
    override func canPerformWithActivityItems(activityItems: [AnyObject]) -> Bool {
        for item in activityItems {
            if (item as? NSURL) != nil {
                return true
            }
            if (item as? SafariVCActivityOverrideURL) != nil {
                return true
            }
        }
        return false
    }
    override func prepareWithActivityItems(activityItems: [AnyObject]) {
        let override = activityItems.filter({ ($0 as? SafariVCActivityOverrideURL) != nil }).first as? SafariVCActivityOverrideURL
        let url = activityItems.filter({ ($0 as? NSURL) != nil }).first as? NSURL
        self.url = override?.url ?? url
    }
    /*override func activityViewController() -> UIViewController? {
        let vc = SFSafariViewController(URL: url!)
        vc.delegate = self
        return vc
    }*/ // doesn't work, for some reason
    override func performActivity() {
        let vc = SFSafariViewController(URL: url!)
        vc.delegate = self
        parentViewController.presentViewController(vc, animated: true, completion: nil)
    }
    var parentViewController: UIViewController
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        activityDidFinish(true)
    }
    override func activityTitle() -> String? {
        return NSLocalizedString("Open Web Page", comment: "")
    }
    override func activityImage() -> UIImage? {
        return UIImage(named: "Safari")
    }
}
