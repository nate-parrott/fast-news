//
//  Utils.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/14/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation

struct Utils {
    static func JoinAttributedStrings(strings: [NSAttributedString], joint: NSAttributedString) -> NSAttributedString {
        let m = NSMutableAttributedString()
        for i in 0..<strings.count {
            m.appendAttributedString(strings[i])
            if i+1 < strings.count {
                m.appendAttributedString(joint)
            }
        }
        return m
    }
    
    static func HostFromURLString(string: String) -> String? {
        if let comps = NSURLComponents(string: string) {
            return comps.host
        } else {
            return nil
        }
    }
    
    static func TopLevelDomainsMatch(host1: String, host2: String) -> Bool {
        let s1 = host1.componentsSeparatedByString(".")
        let s2 = host2.componentsSeparatedByString(".")
        if s1.count < 2 || s2.count < 2 {
            return false
        }
        return s1[s1.count-1] == s2[s2.count-1] && s1[s1.count-2] == s2[s2.count-2]
    }
}
