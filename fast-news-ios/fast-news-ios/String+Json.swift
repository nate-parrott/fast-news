//
//  String+Json.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 1/2/17.
//  Copyright © 2017 Nate Parrott. All rights reserved.
//

import Foundation

extension String {
    static func fromJson(json: AnyObject) -> String? {
        if let data = try? NSJSONSerialization.dataWithJSONObject(json, options: []) {
            return String(data: data, encoding: NSUTF8StringEncoding)
        } else {
            return nil
        }
    }
}
