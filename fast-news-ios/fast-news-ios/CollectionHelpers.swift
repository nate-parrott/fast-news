//
//  ArrayHelpers.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 10/11/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation

extension SequenceType {
    func any(@noescape f: (Self.Generator.Element) -> Bool) -> Bool {
        for element in self {
            if f(element) {
                return true
            }
        }
        return false
    }
}
