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
}


