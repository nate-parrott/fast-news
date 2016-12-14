//
//  TinySpinner.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 12/13/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class TinySpinner : UIView {
    let imageView = UIImageView(image: UIImage(named: "TinySpinner"))
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
    }
    
    override func willMoveToWindow(newWindow: UIWindow?) {
        super.willMoveToWindow(newWindow)
        if newWindow != nil && timer == nil {
            timer = NSTimer.scheduledTimerWithTimeInterval(0.03, repeats: true, block: { [weak self] (_) in
                self?.step += 1
            })
        } else if newWindow == nil && timer != nil {
            timer?.invalidate()
            timer = nil
        }
    }
    
    var step = 0 {
        didSet {
            imageView.transform = CGAffineTransformMakeRotation(CGFloat(M_PI) / 8 * CGFloat(step))
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.center = bounds.center
    }
    
    var timer: NSTimer?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func sizeToFit() {
        bounds = imageView.bounds
    }
}
