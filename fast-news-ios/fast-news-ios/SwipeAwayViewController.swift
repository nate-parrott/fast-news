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
        _panRec = SSWDirectionalPanGestureRecognizer(target: self, action: "_swiped:")
        _panRec.direction = .Right
        view.addGestureRecognizer(_panRec)
    }
    var _panRec: SSWDirectionalPanGestureRecognizer!
    
    func _swiped(rec: SSWDirectionalPanGestureRecognizer) {
        let progress = max(0, min(1, (rec.translationInView(view.superview).x - 10) / view.bounds.size.width))
        if rec.state == .Changed && progress > 0 {
            if !isBeingDismissed() {
                dismissViewControllerAnimated(true, completion: nil)
            }
            _percentDrivenTransition?.updateInteractiveTransition(progress)
        } else if rec.state == .Ended && isBeingDismissed() {
            let velocity = rec.velocityInView(view.superview).x
            let stationary = (velocity == 0)
            let willCompleteTransition = velocity > 0 || (velocity == 0 && progress > 0.5)
            // print("Will complete: \(willCompleteTransition)")
            // _percentDrivenTransition?.completionCurve = stationary ? .EaseInOut : .EaseOut
            
            if stationary {
                _percentDrivenTransition?.completionCurve = .EaseInOut
            } else {
                _percentDrivenTransition?.completionCurve = .Linear
                let distanceToTravel = willCompleteTransition ? (1 - progress) : progress
                // duration / k * velocity = distanceToTravel
                // 1 / k = distanceToTravel / velocity / duration
                // k = velocity * duration / distanceToTravel
                if let p = _percentDrivenTransition {
                    if distanceToTravel > 0 {
                        p.completionSpeed = (abs(velocity) / view.bounds.size.width) * p.duration / distanceToTravel
                    }
                }
            }
            
            if willCompleteTransition {
                // _percentDrivenTransition?.completionSpeed = max(0.1, velocity / view.bounds.size.width)
                _percentDrivenTransition?.finishInteractiveTransition()
            } else {
                // _percentDrivenTransition?.completionSpeed = max(0.1, -(velocity / view.bounds.size.width))
                _percentDrivenTransition?.cancelInteractiveTransition()
            }
        }
    }
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return (transitionContext?.isInteractive() ?? false) ? 0.3 : 0.2
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        // let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        let presenting = (toVC === self)
        let root = transitionContext.containerView()!
        let duration = transitionDuration(transitionContext)
        let darkBackdrop = UIView()
        darkBackdrop.frame = root.bounds
        darkBackdrop.backgroundColor = UIColor(white: 0, alpha: 0.7)
        
        if presenting {
            root.addSubview(darkBackdrop)
            darkBackdrop.alpha = 0
            root.addSubview(view)
            view.frame = transitionContext.finalFrameForViewController(toVC)
            view.transform = CGAffineTransformMakeTranslation(toVC.view.bounds.size.width, 0)
            UIView.animateWithDuration(duration, delay: 0, options: [.CurveEaseOut], animations: { () -> Void in
                toVC.view.transform = CGAffineTransformIdentity
                darkBackdrop.alpha = 1
                }, completion: { (_) -> Void in
                    transitionContext.completeTransition(true)
                    darkBackdrop.removeFromSuperview()
            })
        } else {
            darkBackdrop.alpha = 1
            root.insertSubview(toVC.view, atIndex: 0)
            root.insertSubview(darkBackdrop, aboveSubview: toVC.view)
            toVC.view.frame = transitionContext.finalFrameForViewController(toVC)
            toVC.view.layoutIfNeeded()
            UIView.animateWithDuration(duration, delay: 0, options: transitionContext.isInteractive() ? [.CurveLinear] : [.CurveEaseOut], animations: { () -> Void in
                self.view.transform = CGAffineTransformMakeTranslation(toVC.view.bounds.size.width, 0)
                darkBackdrop.alpha = 0
                }, completion: { (_) -> Void in
                    let cancelled = transitionContext.transitionWasCancelled()
                    if !cancelled {
                        self.view.removeFromSuperview()
                    }
                    darkBackdrop.removeFromSuperview()
                    transitionContext.completeTransition(!cancelled)
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
    
    var _percentDrivenTransition: UIPercentDrivenInteractiveTransition? // TODO: make weak
    
    func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if _panRec.state == .Began || _panRec.state == .Changed {
            let t = UIPercentDrivenInteractiveTransition()
            _percentDrivenTransition = t
            return t
        } else {
            return nil
        }
    }
}
