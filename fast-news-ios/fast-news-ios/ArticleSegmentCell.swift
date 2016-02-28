//
//  ArticleSegmentCell.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/28/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class ArticleSegmentCell: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        
    }
    
    func prepareForReuse() {
        
    }
    
    var reuseIdentifier: String {
        get {
            return "ArticleSegmentCell"
        }
    }
    
    lazy var contentView: UIView = {
        let v = UIView()
        self.addSubview(v)
        return v
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = bounds
    }
}
