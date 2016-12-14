//
//  StatusView+App.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 7/6/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

extension StatusItem {
    func add() {
        RootViewController.Shared.statusItems.append(self)
    }
    func remove() {
        let items = RootViewController.Shared.statusItems
        var i = 0
        while i < items.count {
            if items[i] === self {
                RootViewController.Shared.statusItems.removeAtIndex(i)
                return
            }
            i += 1
        }
    }
    func removeAfterStandardDelay() {
        delay(2.5) {
            self.remove()
        }
    }
}


