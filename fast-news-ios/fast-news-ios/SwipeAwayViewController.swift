//
//  SwipeAwayViewController.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/13/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class SwipeAwayViewController: UIViewController, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate, UIDynamicAnimatorDelegate, UIGestureRecognizerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0, alpha: 0)
        if contentView == nil {
            contentView = UIView()
            contentView.backgroundColor = UIColor.whiteColor()
        }
        if contentView.superview == nil {
            view.addSubview(contentView)
        }
        _panRec = SSWDirectionalPanGestureRecognizer(target: self, action: #selector(SwipeAwayViewController._swiped(_:)))
        _panRec.delegate = self
        _panRec.direction = .Right
        view.addGestureRecognizer(_panRec)
    }
    @IBOutlet var contentView: UIView!
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        contentView.bounds = view.bounds
        _snap?.snapPoint = view.bounds.center
    }
    
    // MARK: Interaction
    var _panRec: SSWDirectionalPanGestureRecognizer!
    var _attachment: UIAttachmentBehavior!
    var _attachmentStartPos: CGPoint!
    func _swiped(rec: SSWDirectionalPanGestureRecognizer) {
        switch _transitionState {
        case .Entrance: return
        default: ()
        }
        var end = false
        switch rec.state {
        case .Began:
            _attachmentStartPos = contentView.center
            _attachment = UIAttachmentBehavior(item: contentView, attachedToAnchor: _attachmentStartPos)
            _animator.addBehavior(_attachment)
        case .Changed:
            if _attachment != nil {
                _attachment.anchorPoint = _attachmentStartPos + CGPointMake(rec.translationInView(view).x, 0)
            }
        case .Ended:
            end = true
            if abs(rec.velocityInView(view).x) > 50 {
                _snapActive = false // continue the exit; just let contentView fly out of sight
            } else {
                _snapActive = true
            }
        case .Failed:
            end = true
            _snapActive = true
        default: ()
        }
        if end && _attachment != nil {
            _animator.removeBehavior(_attachment)
            _attachment = nil
            _itemBehavior.addLinearVelocity(CGPointMake(rec.velocityInView(view).x, 0), forItem: contentView)
        }
    }
    
    // MARK: Static transition
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        // let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        let presenting = (toVC === self)
        let root = transitionContext.containerView()!
        
        if presenting {
            root.addSubview(view)
            view.frame = transitionContext.finalFrameForViewController(toVC)
            _setupAnimator()
            _transitionState = .Entrance
            transitionContext.completeTransition(true)
        } else {
            view.removeFromSuperview()
            transitionContext.completeTransition(true)
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
        modalPresentationStyle = .Custom
        parent.presentViewController(self, animated: true, completion: nil)
    }
    
    // MARK: Dynamics
    func _setupAnimator() {
        contentView.bounds = view.bounds
        contentView.center = CGPointMake(contentView.bounds.size.width * 1.5, view.bounds.center.y)
        
        _animator = UIDynamicAnimator(referenceView: view)
        _animator.delegate = self
        
        _itemBehavior = UIDynamicItemBehavior(items: [contentView])
        _itemBehavior.allowsRotation = false
        _animator.addBehavior(_itemBehavior)
    }
    enum DynamicTransitionState {
        case NotSetUp
        case Entrance
        case Presented
        case Exit
    }
    var _transitionState = DynamicTransitionState.NotSetUp {
        didSet (oldState) {
            switch _transitionState {
            case .Entrance:
                _snapActive = true
            case .Presented: ()
                // TODO
            default: ()
            }
        }
    }
    
    var _snapActive = false {
        didSet (old) {
            if old != _snapActive {
                if _snapActive {
                    if _snap == nil {
                        _snap = UISnapBehavior(item: contentView, snapToPoint: view.bounds.center)
                    }
                    _animator.addBehavior(_snap)
                } else {
                    _animator.removeBehavior(_snap)
                }
            }
        }
    }
    var _snap: UISnapBehavior!
    func _induceExit() {
        /*_snapActive = false
        let exitSnap = UISnapBehavior(item: contentView, snapToPoint: CGPointMake(view.bounds.size.width * 2, view.bounds.size.height/2))
        _animator.addBehavior(exitSnap)*/
        _animator.removeAllBehaviors()
        UIView.animateWithDuration(0.3, delay: 0, options: [.CurveEaseIn], animations: { 
            self.contentView.center = self.contentView.center + CGPointMake(self.contentView.bounds.size.width, 0)
            self.view.backgroundColor = UIColor.clearColor()
            }) { (_) in
                self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    var _animator: UIDynamicAnimator!
    var _itemBehavior: UIDynamicItemBehavior!
    func dynamicAnimatorWillResume(animator: UIDynamicAnimator) {
        _dynamicAnimatorActive = true
    }
    func dynamicAnimatorDidPause(animator: UIDynamicAnimator) {
        _dynamicAnimatorActive = false
    }
    var _dynamicAnimatorActive = false {
        didSet (old) {
            if _dynamicAnimatorActive != old {
                if _dynamicAnimatorActive {
                    _displayLink = CADisplayLink(target: self, selector: #selector(SwipeAwayViewController._dynamicAnimationTick))
                    _displayLink!.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
                } else {
                    _displayLink?.invalidate()
                    _displayLink = nil
                    _dynamicAnimationTick()
                }
            }
        }
    }
    var _displayLink: CADisplayLink?
    func _dynamicAnimationTick() {
        view.backgroundColor = UIColor(white: 0, alpha: 0.7 * _contentViewScreenOverlap)
        
        switch _transitionState {
        case .Entrance: _checkIfDynamicEntranceCompleted()
        case .Exit: _checkIfDynamicExitCompleted()
        case .Presented: _checkIfDynamicExitBegan()
        default: ()
        }
    }
    var _contentViewScreenOverlap: CGFloat {
        get {
            if CGRectIntersectsRect(contentView.frame, view.bounds) {
                let overlapSize = CGRectIntersection(contentView.frame, view.bounds).size
                return overlapSize.width * overlapSize.height / (view.bounds.size.width * view.bounds.size.height)
            } else {
                return 0
            }
        }
    }
    func _checkIfDynamicEntranceCompleted() {
        if !_dynamicAnimatorActive && _contentViewScreenOverlap > 0.95 {
            contentView.center = view.center
            _transitionState = .Presented
        }
    }
    func _checkIfDynamicExitCompleted() {
        if !_dynamicAnimatorActive && _contentViewScreenOverlap == 1 {
            _transitionState = .Presented
        } else if _contentViewScreenOverlap == 0 {
            dismissViewControllerAnimated(true, completion: nil)
            _animator.removeAllBehaviors()
        }
    }
    func _checkIfDynamicExitBegan() {
        if _dynamicAnimatorActive && _contentViewScreenOverlap < 1 {
            _transitionState = .Exit
        }
    }
}
