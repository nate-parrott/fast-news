//
//  Cache.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 7/24/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation

protocol Cacheable {
    func cacheJson() -> [String: AnyObject]
    func importCacheJson(json: [String: AnyObject])
    var cacheKey: String? { get }
    var versionKey: String? { get }
}

class Cache {
    // thread-safe cache for NSCoding-conforming objects
    static let Shared = Cache()
    
    init() {
        if !NSFileManager.defaultManager().fileExistsAtPath(_cacheURL!.path!) {
            try! NSFileManager.defaultManager().createDirectoryAtURL(_cacheURL!, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    let _cacheURL = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true).first!).URLByAppendingPathComponent("APICache")
    
    func pathForKey(key: String) -> NSURL {
        let b64 = String(data: key.dataUsingEncoding(NSUTF8StringEncoding)!.base64EncodedDataWithOptions([]), encoding: NSUTF8StringEncoding)!
        return _cacheURL!.URLByAppendingPathComponent(b64)!
    }
    
    func get(key: String) -> [String: AnyObject]? {
        let path = pathForKey(key)
        if NSFileManager.defaultManager().fileExistsAtPath(path.path!) {
            if let d = try? NSJSONSerialization.JSONObjectWithData(NSData(contentsOfURL: path)!, options: []) {
                return d as? [String: AnyObject]
            }
        }
        return nil
    }
    
    func set(key: String, item: [String: AnyObject]) {
        try! NSJSONSerialization.dataWithJSONObject(item, options: []).writeToURL(pathForKey(key), options: [])
    }
    
    var cachedObjects = [Cacheable]()
    func registerObjectAsCacheable(item: Cacheable) {
        cachedObjects.append(item)
        if let key = item.cacheKey, let json = get(key) {
            item.importCacheJson(json)
        }
    }
    
    func saveAll() {
        for item in cachedObjects {
            if let key = item.cacheKey {
                set(key, item: item.cacheJson())
            }
        }
    }
}
