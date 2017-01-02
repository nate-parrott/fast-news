//
//  CommonExtensions.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/10/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

extension String {
    func asURLString() -> String? {
        var s = self
        if !s.hasPrefix("http://") && !s.hasPrefix("https://") {
            s = "http://" + s
        }
        if NSURL(string: s) != nil {
            return s
        } else {
            return nil
        }
    }
}

extension UIViewController {
    func showError(message: String?) {
        let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Okay", comment: ""), style: .Default, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
}

extension Array {
    func makeBatches(count: Int) -> [[Element]] {
        var batches = [[Element]]()
        for item in self {
            if batches.count == 0 || batches[batches.count-1].count == count {
                batches.append([])
            }
            batches[batches.count-1].append(item)
        }
        return batches
    }
}
