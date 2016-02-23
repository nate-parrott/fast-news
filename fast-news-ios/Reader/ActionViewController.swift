//
//  ActionViewController.swift
//  Reader
//
//  Created by Nate Parrott on 2/23/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import MobileCoreServices

class ActionViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Get the item[s] we're handling from the extension context.
        
        // For example, look for an image and place it into an image view.
        // Replace this with something appropriate for the type[s] your extension supports.
        var found = false
        for item: AnyObject in self.extensionContext!.inputItems {
            let inputItem = item as! NSExtensionItem
            for provider: AnyObject in inputItem.attachments! {
                let itemProvider = provider as! NSItemProvider
                if itemProvider.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                    // This is an image. We'll load it, then place it in our image view.
                    itemProvider.loadItemForTypeIdentifier(kUTTypeURL as String, options: nil, completionHandler: { (url, error) in
                        NSOperationQueue.mainQueue().addOperationWithBlock {
                            let article = Article(id: nil)
                            article.url = (url as? NSURL)?.absoluteString
                            
                            let articleVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("Article") as! ArticleViewController
                            articleVC.article = article
                            self.articleVC = articleVC
                        }
                    })
                    
                    found = true
                    break
                }
            }
            
            if (found) {
                // We only handle one image, so stop looking for more.
                break
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func done() {
        // Return any edited content to the host app.
        // This template doesn't do anything, so we just echo the passed in items.
        self.extensionContext!.completeRequestReturningItems(self.extensionContext!.inputItems, completionHandler: nil)
    }
    
    var articleVC: ArticleViewController? {
        willSet(newVal) {
            if let old = articleVC {
                old.view.removeFromSuperview()
                old.removeFromParentViewController()
            }
            if let new = newVal {
                view.addSubview(new.view)
                new.view.frame = view.bounds
                new.view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
                addChildViewController(new)
                new.onBack = {
                    [weak self] in
                    self?.done()
                }
            }
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
