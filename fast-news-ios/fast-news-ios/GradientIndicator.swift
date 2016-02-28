//
//  GradientIndicator.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/28/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import GradientView

class GradientIndicator: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        gradient.direction = .Horizontal
        shadow.direction = .Vertical
        shadow.colors = [UIColor.blackColor(), UIColor(white: 0, alpha: 0)]
        shadow.alpha = 0.11
        shadow.backgroundColor = UIColor.clearColor()
        backgroundColor = nil
        
        addSubview(gradient)
        addSubview(shadow)
        
        let s = state
        state = s
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let gradient = GradientView()
    let shadow = GradientView()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = CGRectMake(0, 0, bounds.size.width, bounds.size.height*0.5)
        shadow.frame = CGRectMake(0, bounds.size.height*0.5, bounds.size.width, bounds.size.height * 0.3)
    }
    
    static let Height: CGFloat = 6
    
    enum State {
        case Offline
        case Done
        case Loading
    }
    var state = State.Offline {
        didSet {
            switch state {
            case .Offline:
                gradient.colors = [UIColor(white: 0.7, alpha: 1), UIColor(white: 0.85, alpha: 1)]
            case .Done:
                gradient.colors = [FN_LIGHT_GREEN, FN_LIGHT_BLUE]
            case .Loading:
                gradient.colors = [UIColor(white: 0.8, alpha: 1), FN_LIGHT_BLUE, UIColor(white: 0.8, alpha: 1)]
            }
        }
    }
}
