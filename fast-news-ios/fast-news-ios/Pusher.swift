//
//  Pusher.swift
//  ptrptr
//
//  Created by Nate Parrott on 1/22/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation

class Pusher<T> {
    typealias Callback = T -> ()
    
    var _lastSubscriptionId = 0
    var _subscriptionsById = [Int: Callback]()
    
    func subscribe(callback: Callback) -> Subscription {
        let id = _lastSubscriptionId++
        _subscriptionsById[id] = callback
        let sub = Subscription()
        sub._onDispose = {
            self._subscriptionsById.removeValueForKey(id)
        }
        return sub
    }
    
    func push(data: T) {
        for cb in Array(_subscriptionsById.values) {
            cb(data)
        }
    }
    
    var subscriptions = [Subscription]() // for your convenience
    
    class func PushLatest(pushers: [Pusher<T>]) -> Pusher<[T]> {
        var latest = [T?]()
        for _ in 0..<pushers.count { latest.append(nil) }
        let result = Pusher<[T]>()
        for (pusher, i) in zip(pushers, 0..<pushers.count) {
            let sub = pusher.subscribe({ (let x) -> () in
                latest[i] = x
                let arrived = latest.filter({ $0 != nil }).map({ $0! })
                if arrived.count == latest.count {
                    result.push(arrived)
                }
            })
            result.subscriptions.append(sub)
        }
        return result
    }
    
    class func PushLatestImmediately(pushers: [Pusher<T>]) -> Pusher<[T?]> {
        var latest = [T?]()
        for _ in 0..<pushers.count { latest.append(nil) }
        let result = Pusher<[T?]>()
        for (pusher, i) in zip(pushers, 0..<pushers.count) {
            let sub = pusher.subscribe({ (let x) -> () in
                latest[i] = x
                result.push(latest)
            })
            result.subscriptions.append(sub)
        }
        return result
    }
    
    func map<T2>(fn: T -> T2) -> Pusher<T2> {
        let result = Pusher<T2>()
        let sub = subscribe { (let x) -> () in
            result.push(fn(x))
        }
        result.subscriptions.append(sub)
        return result
    }
    
    func filter(fn: T -> Bool) -> Pusher<T> {
        let result = Pusher<T>()
        let sub = subscribe { (let x) -> () in
            if fn(x) {
                result.push(x)
            }
        }
        result.subscriptions.append(sub)
        return result
    }
}

class Subscription {
    var _onDispose: (() -> ())!
    deinit {
        _onDispose()
    }
}

class Observable<T>: Pusher<T> {
    init(val: T) {
        self.val = val
    }
    var val: T {
        didSet {
            push(val)
        }
    }
}
