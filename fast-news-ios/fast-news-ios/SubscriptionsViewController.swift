//
//  SubscriptionsViewController.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/6/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class SubscriptionsViewController: UITableViewController, UITextFieldDelegate {
    let subs = SubscriptionsList.objectsForIDs(["main"]).first! as! SubscriptionsList
    var _subsSub: Subscription?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SubscriptionsViewController._foreground(_:)), name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        for rowClass in allRowClasses {
            tableView.registerClass(rowClass.cellClass, forCellReuseIdentifier: NSStringFromClass(rowClass.cellClass))
        }
        
        _subsSub = subs.onUpdate.subscribe({ [weak self] (_) -> () in
            self?._update()
        })
        
        // tableView.tableHeaderView = addSourceTextField
    }
    
    let _preferredRecency: CFAbsoluteTime = 5 * 60
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        subs.ensureRecency(_preferredRecency)
    }
    
    func _foreground(notif: NSNotification) {
        subs.ensureRecency(_preferredRecency)
    }
    
    // MARK: Data
    
    var sections = [Section]() {
        didSet {
            tableView.reloadData()
        }
    }
    
    func _update() {
        var title = navigationItem.title
        if _addsInProgress > 0 {
            title = NSLocalizedString("Adding…", comment: "")
        } else {
            switch subs.loadingState {
            case .Error(_): title = NSLocalizedString("Offline", comment: "")
            case .Loading(_): title = NSLocalizedString("Refreshing…", comment: "")
            default: title = NSLocalizedString("News Subscriptions", comment: "")
            }
        }
        navigationItem.title = title
        
        let subscriptionRows = subs.subscriptionsIncludingOptimistic.map({ SubscriptionRow(subscription: $0) })
        sections = [
            Section(title: nil, rows: [SearchBarRow(bar: searchBar)]),
            Section(title: NSLocalizedString("Subscriptions", comment: ""), rows: subscriptionRows)
        ]
    }
    
    // MARK: Adding sources
    
    let searchBar = SourceSearchBar(frame: CGRectZero)
    
    /*@IBOutlet var addSourceTextField: UITextField!
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let url = (textField.text ?? "").asURLString() {
            _addsInProgress += 1
            AddSubscriptionTransaction(url: url).start({ (success) -> () in
                self._addsInProgress -= 1
                if !success {
                    self.showError(NSLocalizedString("Couldn't add that news source.", comment: ""))
                }
            })
        }
        textField.text = ""
        textField.resignFirstResponder()
        return false
    }
    
    func textFieldShouldClear(textField: UITextField) -> Bool {
        delay(0.01) { () -> () in
            textField.resignFirstResponder()
        }
        return true
    }
    */
    var _addsInProgress = 0 {
        didSet {
            _update()
        }
    }
    
    
    // MARK: TableView
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        let cellIdentifier = NSStringFromClass(row.dynamicType.cellClass)
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath)
        row.configureCell(cell)
        return cell
    }
    
    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let row = sections[indexPath.section].rows[indexPath.row]
        return row.canSelect
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let row = sections[indexPath.section].rows[indexPath.row]
        return row.canDelete
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let row = sections[indexPath.section].rows[indexPath.row]
        switch editingStyle {
        case .Delete:
            row.delete(self)
        default: ()
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let row = sections[indexPath.section].rows[indexPath.row]
        row.select(self)
    }
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        // addSourceTextField.resignFirstResponder()
    }
    
    override func tableView(tableView: UITableView, performAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
        if action == #selector(NSObject.delete(_:)) {
            let sub = subs.subscriptions![indexPath.row]
            DeleteSubscriptionTransaction(url: sub.source!.url!).start({ (success) -> () in
                if !success {
                    self.showError(NSLocalizedString("Couldn't unsubscribe.", comment: ""))
                }
            })
        }
    }
    
    // MARK: Row/section model classes
    
    struct Section {
        let title: String?
        let rows: [Row]
    }
    
    class Row {
        class var cellClass: UITableViewCell.Type {
            get {
                return UITableViewCell.self
            }
        }
        func configureCell(cell: UITableViewCell) {
            
        }
        func height(width: CGFloat) -> CGFloat {
            return 44
        }
        // MARK: Actions
        var canDelete: Bool {
            get {
                return false
            }
        }
        func delete(vc: SubscriptionsViewController) {
            
        }
        var canSelect: Bool {
            get {
                return false
            }
        }
        func select(vc: SubscriptionsViewController) {
            
        }
    }
    
    class SubscriptionRow: Row {
        init(subscription: SourceSubscription) {
            self.subscription = subscription
        }
        override class var cellClass: UITableViewCell.Type {
            get {
                return SubscriptionRowCell.self
            }
        }
        let subscription: SourceSubscription
        override func configureCell(cell: UITableViewCell) {
            super.configureCell(cell)
            cell.textLabel!.text = subscription.source!.title
            cell.detailTextLabel!.text = subscription.source!.url
        }
        override var canDelete: Bool {
            get {
                return true
            }
        }
        override func delete(vc: SubscriptionsViewController) {
            DeleteSubscriptionTransaction(url: subscription.source!.url!).start({ (success) -> () in
                if !success {
                    vc.showError(NSLocalizedString("Couldn't unsubscribe.", comment: ""))
                }
            })
        }
    }
    
    class SearchBarRow: Row {
        init(bar: SourceSearchBar) {
            self.bar = bar
        }
        let bar: SourceSearchBar
        override class var cellClass: UITableViewCell.Type {
            get {
                return SourceSearchBarCell.self
            }
        }
        override func configureCell(cell: UITableViewCell) {
            cell.backgroundColor = nil
            // ugh seriously apple?
            for view in cell.subviews {
                if view !== cell.contentView {
                    view.removeFromSuperview()
                }
            }
            (cell as! SourceSearchBarCell).searchBar = bar
        }
        override func height(width: CGFloat) -> CGFloat {
            return SourceSearchBar.Height
        }
    }
        
    let allRowClasses: [Row.Type] = [SubscriptionRow.self, SearchBarRow.self]
}

