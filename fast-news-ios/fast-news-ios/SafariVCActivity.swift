//
//  SafariVCActivity.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/23/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import SafariServices

class SafariVCActivity: UIActivity, SFSafariViewControllerDelegate {
    var url: NSURL?
    override func canPerformWithActivityItems(activityItems: [AnyObject]) -> Bool {
        for item in activityItems {
            if (item as? NSURL) != nil {
                return true
            }
        }
        return false
    }
    override func prepareWithActivityItems(activityItems: [AnyObject]) {
        for item in activityItems {
            if let aURL = item as? NSURL {
                url = aURL
            }
        }
    }
    override func activityViewController() -> UIViewController? {
        let vc = SFSafariViewController(URL: url!)
        vc.delegate = self
        return vc
    }
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
