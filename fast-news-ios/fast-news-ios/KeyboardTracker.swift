//
//  KeyboardTracker.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 8/16/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class KeyboardTracker: NSObject {
    static let Shared = KeyboardTracker()
    
    override init() {
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(KeyboardTracker._keyboardFrameChanged(_:)), name: UIKeyboardDidChangeFrameNotification, object: nil)
    }
    func _keyboardFrameChanged(notif: NSNotification) {
        // let fromFrame = (notif.userInfo![UIKeyboardFrameBeginUserInfoKey] as! NSValue).CGRectValue()
        let toFrame = (notif.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let duration = NSTimeInterval((notif.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue)
        // let curve: UIViewAnimationCurve = UIViewAnimationCurve(rawValue: Int((notif.userInfo![UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).integerValue))!
        UIView.animateWithDuration(duration, delay: 0, options: [.CurveEaseInOut], animations: { 
            self.keyboardFrame.val = toFrame
            }, completion: nil)
        print("Duration: \(duration)")
    }
    func keyboardHeightInView(view: UIView) -> CGFloat {
        if let k = keyboardFrame.val {
            let boundsInWindow = view.window!.convertRect(view.bounds, fromView: view)
            if CGRectIntersectsRect(boundsInWindow, k) {
                return CGRectIntersection(boundsInWindow, k).size.height
            }
        }
        return 0
    }
    let keyboardFrame = Observable<CGRect?>(val: nil)
}
