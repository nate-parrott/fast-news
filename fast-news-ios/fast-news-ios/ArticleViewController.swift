//
//  ArticleViewController.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/10/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class ArticleViewController: SwipeAwayViewController {
    var article: Article!
    var _articleSub: Subscription?
    
    @IBOutlet var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        _articleSub = article.onUpdate.subscribe({ [weak self] (_) -> () in
            self?.update()
        })
        update()
        article.ensureRecency(3 * 60 * 60)
    }
    func update() {
        title = article.title
        if let content = article.content {
            let allText = NSMutableAttributedString()
            for seg in content.segments {
                if let textSeg = seg as? ArticleContent.TextSegment {
                    let segText = NSMutableAttributedString()
                    textSeg.span.appendToAttributedString(segText)
                    segText.stripWhitespace()
                    segText.appendAttributedString(NSAttributedString(string: "\n", attributes: segText.attributesAtIndex(segText.length - 1, effectiveRange: nil)))
                    allText.appendAttributedString(segText)
                }
            }
            textView.attributedText = allText
        } else if let failed = article.fetchFailed where failed {
            textView.text = "fetch failed"
        } else {
            textView.text = "hold your breath"
        }
    }
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    @IBAction func share(sender: AnyObject) {
        presentViewController(UIActivityViewController(activityItems: [NSURL(string: article.url!)!], applicationActivities: nil), animated: true, completion: nil)
    }
}
