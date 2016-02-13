//
//  NetImageView.swift
//  ptrptr
//
//  Created by Nate Parrott on 1/16/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class NetImageView: UIImageView {
    var url: NSURL? {
        willSet(newVal) {
            // print("\(newVal)")
            if newVal != url {
                image = nil
                NetImageView.cleanImageCache()
                _task?.cancel()
                _task = nil
                loadInProgress = false
                
                if let url_ = newVal {
                    let cacheID = url_.absoluteString
                    if let cached = NetImageView.imageCache[cacheID]?.image {
                        image = cached
                    } else {
                        loadInProgress = true
                        let req = NSURLRequest(URL: url_)
                        _task = NSURLSession.sharedSession().dataTaskWithRequest(req, completionHandler: { [weak self] (let dataOpt, let responseOpt, let errorOpt) -> Void in
                            backgroundThread({ () -> Void in
                                if let self_ = self, data = dataOpt, let image = UIImage(data: data) {
                                    mainThread({ () -> Void in
                                        if self_.url == url_ {
                                            self_.image = image
                                            
                                            let weakImage = WeakImage()
                                            weakImage.image = image
                                            NetImageView.imageCache[cacheID] = weakImage
                                            
                                            self_.loadInProgress = false
                                        }
                                    })
                                }
                            })
                            })
                        _task!.resume()
                    }
                }
            } else {
                loadInProgress = false
            }
        }
    }
    
    var _task: NSURLSessionDataTask?
    
    static var imageCache = [String: WeakImage]()
    static func cleanImageCache() {
        var keysToRemove = [String]()
        for (id, weakImage) in imageCache {
            if weakImage.image == nil {
                keysToRemove.append(id)
            }
        }
        for key in keysToRemove {
            imageCache.removeValueForKey(key)
        }
    }
    class WeakImage {
        weak var image: UIImage?
    }
    
    private(set) var loadInProgress = false {
        didSet {
            backgroundColor = loadInProgress ? UIColor(white: 0.5, alpha: 0.5) : UIColor.clearColor()
        }
    }
    
    func mirroredURLForImage(imageURL: String, size: CGSize) -> NSURL {
        let comps = NSURLComponents(string: "https://surfboard-services.appspot.com/mirror")!
        comps.queryItems = [NSURLQueryItem(name: "url", value: imageURL), NSURLQueryItem(name: "resize", value: "\(size.width),\(size.height)")]
        return comps.URL!
    }
}
