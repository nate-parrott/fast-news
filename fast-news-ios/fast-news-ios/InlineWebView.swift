//
//  InlineWebView.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/24/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import WebKit

class InlineWebView: UIView, WKNavigationDelegate {
    init() {
        super.init(frame: CGRectZero)
        webView.navigationDelegate = self
        addSubview(webView)
        addSubview(loadingBar)
        loadingBar.frame = CGRectMake(0, 0, bounds.size.width, 0)
        loadingBar.backgroundColor = FN_PURPLE
        loadingBar.autoresizingMask = [.FlexibleBottomMargin, .FlexibleWidth]
        errorView.text = NSLocalizedString("Couldn't load page.", comment: "")
        addSubview(errorView)
        errorView.font = UIFont(descriptor: UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleBody), size: 0)
        errorView.hidden = true
        // TODO: KVO webview progress
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let webView = WKWebView()
    var onClickedLink: (NSURL -> ())?
    
    var article: Article? {
        didSet {
            if let urlString = article?.url, let url = NSURL(string: urlString) {
                webView.loadRequest(NSURLRequest(URL: url))
            }
        }
    }
    
    var inset = UIEdgeInsetsZero {
        didSet {
            webView.scrollView.contentInset = inset
            webView.scrollView.scrollIndicatorInsets = inset
        }
    }
    
    enum State {
        case None
        case Loading(progress: Double)
        case Error(error: NSError?)
        case Loaded
    }
    
    let loadingBar = UIView()
    let errorView = UILabel()
    
    var state = State.None {
        didSet {
            UIView.animateWithDuration(0.1, delay: 0, options: .AllowUserInteraction, animations: { () -> Void in
                var progress: CGFloat = 0
                var show = false
                
                switch self.state {
                case .Loading(progress: let p):
                    progress = CGFloat(p)
                    show = true
                default: ()
                }
                
                self.loadingBar.frame = CGRectMake(0, 0, self.bounds.size.width * progress, show ? 2 : 0)
                }, completion: nil)
            
            switch state {
            case .Error(error: _):
                errorView.hidden = false
            default: errorView.hidden = true
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        webView.frame = bounds
        errorView.sizeToFit()
        errorView.center = CGPointMake(bounds.size.width/2, bounds.size.height/2)
    }
    
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        let navType = navigationAction.navigationType
        if navType == .LinkActivated || navType == .FormSubmitted {
            if let cb = onClickedLink, let url = navigationAction.request.URL {
                cb(url)
            }
            decisionHandler(.Cancel)
        } else {
            decisionHandler(.Allow)
        }
    }
    
    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        state = .Error(error: error)
    }
    
    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        state = .Error(error: error)
    }
    
    func webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation!) {
        state = .Loading(progress: webView.estimatedProgress)
    }
    
    func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        state = .Loading(progress: webView.estimatedProgress)
    }
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        state = .Loaded
    }
}
