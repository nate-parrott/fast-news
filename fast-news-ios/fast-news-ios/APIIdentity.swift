//
//  Identity.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/13/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation

class APIIdentity: NSObject {
    static let Shared = APIIdentity()
    override init() {
        super.init()
        _update()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(APIIdentity._update), name: NSUbiquityIdentityDidChangeNotification, object: nil)
    }
    func _update() {
        id = _compute()
    }
    func _compute() -> String {
        let defaultsKey = "APIObject.userID"
        let IDFromDefaultsOpt = NSUserDefaults.standardUserDefaults().valueForKey(defaultsKey) as? String
        var IDFromICloudOpt: String?
        if let token = NSFileManager.defaultManager().ubiquityIdentityToken {
            IDFromICloudOpt = NSKeyedArchiver.archivedDataWithRootObject(token).MD5().hexString()
        }
        // if we have an iCloud key, store it in defaults and return it:
        // TODO: deal with overwriting by icloud; maybe prompt user?
        if let iCloud = IDFromICloudOpt {
            if IDFromDefaultsOpt != iCloud {
                NSUserDefaults.standardUserDefaults().setValue(iCloud, forKey: defaultsKey)
            }
            return iCloud
        } else if let id = IDFromDefaultsOpt {
            return id
        } else {
            // we've got nothing:
            let key = NSUUID().UUIDString
            NSUserDefaults.standardUserDefaults().setValue(key, forKey: defaultsKey)
            return key
        }
    }
    private(set) var id: String!
}
