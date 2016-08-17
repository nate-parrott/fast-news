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
    let featured = FeaturedSources.objectForID("featured") as! FeaturedSources
    var _featuredSub: Subscription?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SubscriptionsViewController._foreground(_:)), name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        for rowClass in allRowClasses {
            tableView.registerClass(rowClass.cellClass, forCellReuseIdentifier: NSStringFromClass(rowClass.cellClass))
        }
        
        _subsSub = subs.onUpdate.subscribe({ [weak self] (_) -> () in
            self?._update()
        })
        
        _featuredSub = featured.onUpdate.subscribe({ [weak self] (_) -> () in
            self?._update()
        })
        
        tableView.sectionHeaderHeight = 1
        tableView.sectionFooterHeight = 30
        tableView.contentInset = UIEdgeInsetsZero
        
        _searchActiveSub = searchBar.active.subscribe({ [weak self] (active) in
            self?.searchActive = active
        })
        
        searchContentCover.backgroundColor = UIColor.groupTableViewBackgroundColor()
        searchContentCover.alpha = 0
        view.addSubview(searchContentCover)
        let tapRec = UITapGestureRecognizer(target: searchBar, action: #selector(SourceSearchBar.cancelEditing))
        searchContentCover.addGestureRecognizer(tapRec)
        
        view.addSubview(searchBar)
    }
    
    let _preferredRecency: CFAbsoluteTime = 5 * 60
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        subs.ensureRecency(_preferredRecency)
        featured.ensureRecency(30 * 60) // 30 mins
    }
    
    func _foreground(notif: NSNotification) {
        subs.ensureRecency(_preferredRecency)
    }
    
    // MARK: Data
    
    var sections = [Section]() {
        didSet {
            tableView.reloadData()
            _updateSearchBarFrame()
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
        let selectedSourceIds = Set<String>(subs.subscriptionsIncludingOptimistic.map({ $0.source?.id ?? "" }))
        let featuredSourceRows = (featured.categories ?? []).map({ FeaturedSourcesCarouselRow(category: $0, selectedSourceIds: selectedSourceIds) })
        sections = [
            Section(title: nil, rows: [SearchBarRow(bar: searchBar)]),
            Section(title: nil, rows: featuredSourceRows),
            Section(title: NSLocalizedString("Subscriptions", comment: ""), rows: subscriptionRows)
        ]
    }
    
    // MARK: Adding/removing sources
    
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
    
    func toggleSourceSubscribed(source: Source) {
        if !currentlySubscribedToSource(source) {
            subscribeToSource(source, url: nil)
        } else {
            unsubscribeFromSource(source)
        }
    }
    
    func subscribeToSource(source: Source?, url: String?) {
        // either source or url must be present
        _addsInProgress += 1
        AddSubscriptionTransaction(source: source, url: url).start({ (success) -> () in
            self._addsInProgress -= 1
            if !success {
                self.showError(NSLocalizedString("Couldn't add that news source.", comment: ""))
            }
        })
    }
    
    func unsubscribeFromSource(source: Source) {
        DeleteSubscriptionTransaction(url: source.url!).start({ (success) -> () in
            if !success {
                self.showError(NSLocalizedString("Couldn't unsubscribe.", comment: ""))
            }
        })
    }
    
    func currentlySubscribedToSource(source: Source) -> Bool {
        if let sourceId = source.id {
            for sub in subs.subscriptionsIncludingOptimistic {
                if let id = sub.source?.id where id == sourceId {
                    return true
                }
            }
        }
        return false
    }
    
    // MARK: Search
    
    let searchBar = SourceSearchBar(frame: CGRectZero)
    var _searchActiveSub: Subscription?
    let searchContentCover = UIView()
    
    var searchActive = false {
        didSet(old) {
            if old == searchActive { return }
            if searchActive {
                tableView.setContentOffset(CGPointMake(0, -tableView.contentInset.top), animated: true)
            }
            viewDidLayoutSubviews()
            UIView.animateWithDuration(0.25, delay: 0, options: [], animations: {
                self.searchContentCover.alpha = self.searchActive ? 0.75 : 0
                }, completion: nil)
        }
    }
    
    // MARK: Layout
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        searchContentCover.frame = view.bounds
        _updateSearchBarFrame()
    }
    
    func _updateSearchBarFrame() {
        if let searchBarCell = tableView.visibleCells.map({ ($0 as? SourceSearchBarCell) }).filter({ $0 != nil }).map({ $0! }).first {
            searchBar.hidden = false
            searchBar.frame = view.convertRect(searchBarCell.barFrame, fromView: searchBarCell)
        } else {
            searchBar.hidden = true
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
        row.configureCell(cell, vc: self)
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
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let row = sections[indexPath.section].rows[indexPath.row]
        return row.height(tableView.bounds.width)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let row = sections[indexPath.section].rows[indexPath.row]
        row.select(self)
    }
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        searchBar.cancelEditing()
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        _updateSearchBarFrame()
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
        func configureCell(cell: UITableViewCell, vc: SubscriptionsViewController) {
            
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
        // MARK: Special helpers
        func _removeDividersFromCell(cell: UITableViewCell) {
            // ugh seriously apple?
            for view in cell.subviews {
                if view !== cell.contentView {
                    view.removeFromSuperview()
                }
            }
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
        override func configureCell(cell: UITableViewCell, vc: SubscriptionsViewController) {
            super.configureCell(cell, vc: vc)
            cell.textLabel!.text = subscription.source!.title
            cell.detailTextLabel!.text = subscription.source!.url
        }
        override var canDelete: Bool {
            get {
                return true
            }
        }
        override func delete(vc: SubscriptionsViewController) {
            if let s = subscription.source {
                vc.unsubscribeFromSource(s)
            }
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
        override func configureCell(cell: UITableViewCell, vc: SubscriptionsViewController) {
            super.configureCell(cell, vc: vc)
            cell.backgroundColor = nil
            _removeDividersFromCell(cell)
        }
        override func height(width: CGFloat) -> CGFloat {
            return SourceSearchBar.Height
        }
    }
    
    class FeaturedSourcesCarouselRow: Row {
        init(category: FeaturedSourcesCategory, selectedSourceIds: Set<String>) {
            self.category = category
            
            var selectedSourceIndices = [Int]()
            var i = 0
            for source in category.sources ?? [] {
                if selectedSourceIds.contains(source.id ?? "") {
                    selectedSourceIndices.append(i)
                }
                i += 1
            }
            self.selectedSourceIndices = selectedSourceIndices
        }
        let category: FeaturedSourcesCategory
        let selectedSourceIndices: [Int]
        override func height(width: CGFloat) -> CGFloat {
            return FeaturedSourcesCarousel.Height
        }
        override class var cellClass: UITableViewCell.Type {
            get {
                return FeaturedSourcesCarouselCell.self
            }
        }
        override func configureCell(cell: UITableViewCell, vc: SubscriptionsViewController) {
            super.configureCell(cell, vc: vc)
            let carouselCell = cell as! FeaturedSourcesCarouselCell
            _removeDividersFromCell(carouselCell)
            carouselCell.carousel.content = FeaturedSourcesCarousel.Content(sources: category.sources ?? [], selectedIndices: selectedSourceIndices)
            carouselCell.carousel.onSelectSource = {
                [weak vc] (source) in
                vc?.toggleSourceSubscribed(source)
            }
        }
    }
    
    let allRowClasses: [Row.Type] = [SubscriptionRow.self, SearchBarRow.self, FeaturedSourcesCarouselRow.self]
}

