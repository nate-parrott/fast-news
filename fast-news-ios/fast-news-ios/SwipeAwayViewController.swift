//
//  SwipeAwayViewController.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/13/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class SwipeAwayViewController: UIViewController, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let panRec = SSWDirectionalPanGestureRecognizer(target: self, action: "_swiped:")
        panRec.direction = .Right
        view.addGestureRecognizer(panRec)
    }
    
    func _swiped(rec: SSWDirectionalPanGestureRecognizer) {
        if rec.translationInView(view).x > 150 {
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.3
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        // let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        let presenting = (toVC === self)
        let root = transitionContext.containerView()!
        let duration = transitionDuration(transitionContext)
        let darkBackdrop = UIView()
        darkBackdrop.frame = root.bounds
        darkBackdrop.backgroundColor = UIColor.blackColor()
        
        if presenting {
            root.addSubview(darkBackdrop)
            darkBackdrop.alpha = 0
            root.addSubview(view)
            view.frame = transitionContext.finalFrameForViewController(toVC)
            view.transform = CGAffineTransformMakeTranslation(toVC.view.bounds.size.width, 0)
            UIView.animateWithDuration(duration, delay: 0, options: [.CurveEaseOut], animations: { () -> Void in
                toVC.view.transform = CGAffineTransformIdentity
                darkBackdrop.alpha = 1
                }, completion: { (let completed) -> Void in
                    transitionContext.completeTransition(completed)
                    darkBackdrop.removeFromSuperview()
            })
        } else {
            darkBackdrop.alpha = 1
            root.insertSubview(toVC.view, atIndex: 0)
            root.insertSubview(darkBackdrop, aboveSubview: toVC.view)
            toVC.view.frame = transitionContext.finalFrameForViewController(toVC)
            UIView.animateWithDuration(duration, delay: 0, options: [.CurveEaseIn], animations: { () -> Void in
                self.view.transform = CGAffineTransformMakeTranslation(toVC.view.bounds.size.width, 0)
                darkBackdrop.alpha = 0
                }, completion: { (let completed) -> Void in
                    if completed {
                        self.view.removeFromSuperview()
                    }
                    darkBackdrop.removeFromSuperview()
                    transitionContext.completeTransition(completed)
            })
        }
    }
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if presented === self {
            return self
        } else {
            return nil
        }
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed === self {
            return self
        } else {
            return nil
        }
    }
    
    func presentFrom(parent: UIViewController) {
        transitioningDelegate = self
        parent.presentViewController(self, animated: true, completion: nil)
    }
}
