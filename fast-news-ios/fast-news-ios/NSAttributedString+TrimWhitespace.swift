//
//  NSAttributedString+TrimWhitespace.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/18/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation

extension NSMutableAttributedString {
    func stripWhitespace() {
        let str: NSString = self.string
        let strippedStr: NSString = str.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        let range = str.rangeOfString(strippedStr as String)
        let trimFromEnd = str.length - (range.location + range.length)
        let trimFromFront = range.location
        deleteCharactersInRange(NSMakeRange(0, trimFromFront))
        deleteCharactersInRange(NSMakeRange(str.length - trimFromFront - trimFromEnd, trimFromEnd))
    }
}