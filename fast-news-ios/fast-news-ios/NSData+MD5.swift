//
//  NSData+MD5.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/13/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation

// via https://gist.github.com/jstn/d2c6ade1f2ad8bae6f57

extension Int {
    func hexString() -> String {
        return NSString(format:"%02x", self) as String
    }
}

extension NSData {
    func hexString() -> String {
        var string = String()
        for i in UnsafeBufferPointer<UInt8>(start: UnsafeMutablePointer<UInt8>(bytes), count: length) {
            string += Int(i).hexString()
        }
        return string
    }
    
    func MD5() -> NSData {
        let result = NSMutableData(length: Int(CC_MD5_DIGEST_LENGTH))!
        CC_MD5(bytes, CC_LONG(length), UnsafeMutablePointer<UInt8>(result.mutableBytes))
        return NSData(data: result)
    }
    
    func SHA1() -> NSData {
        let result = NSMutableData(length: Int(CC_SHA1_DIGEST_LENGTH))!
        CC_SHA1(bytes, CC_LONG(length), UnsafeMutablePointer<UInt8>(result.mutableBytes))
        return NSData(data: result)
    }
}

extension String {
    func hexString() -> String {
        return (self as NSString).dataUsingEncoding(NSUTF8StringEncoding)!.hexString()
    }
    
    func MD5() -> String {
        return (self as NSString).dataUsingEncoding(NSUTF8StringEncoding)!.MD5().hexString()
    }
    
    func SHA1() -> String {
        return (self as NSString).dataUsingEncoding(NSUTF8StringEncoding)!.SHA1().hexString()
    }
}