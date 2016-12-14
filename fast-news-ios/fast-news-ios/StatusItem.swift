//
//  StatusItem.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 7/6/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class StatusItem {
    init(title: String) {
        self.title = title
    }
    let title: String
    func coalescleWithItems(items: [StatusItem]) -> StatusItem {
        return self
    }
    var iconView: UIView? // icon views have about 40px of space
    func tapped() {
        // TODO
    }
    func populateIconWithSpinner() {
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .White)
        spinner.transform = CGAffineTransformMakeScale(0.7, 0.7)
        iconView = spinner
        spinner.startAnimating()
    }
}


