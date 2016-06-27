//
//  ArticleViewController.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/10/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import SafariServices

class ArticleViewController: SwipeAwayViewController {
    // MARK: Data
    var article: Article! {
        didSet {
            if let b = _findMatchingBookmark(), let pos = b.readingPosition as? [AnyObject] where pos.count > 0, let idx = pos[0] as? Int {
                __readingPosition = idx
            }
        }
    }
    var _articleSub: Subscription?
    var _bookmarkListChangedSub: Subscription?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pager.alpha = 0
        loadingContainer.alpha = 0
        
        pager.updateLayout = {
            [weak self] (_) in
            self?._recomputeLayoutInfo()
        }
        pager.createPageForModel = {
            [weak self] (i) in
            return self!._pageViewForIndex(i)
        }
        pager.onPageChanged = {
            [weak self] (let page) in
            if let s = self, let pos = s._layoutInfo?.pages[page].indexOfFirstSegmentStarted {
                s._readingPosition = pos
            }
        }
        
        contentView.insertSubview(pager, atIndex: 0)
        
        _articleSub = article.onUpdate.subscribe({ [weak self] (_) -> () in
            self?._update()
        })
        _update()
        article.ensureRecency(3 * 60 * 60)
        
        if let bgColor = article.source?.backgroundColor, let textColor = article.source?.textColor {
            let bgVisibility = max(bgColor.hsva.1, 1 - bgColor.hsva.2)
            let textVisibility = max(textColor.hsva.1, 1 - textColor.hsva.2)
            actionsBar.tintColor = bgVisibility > textVisibility ? bgColor : textColor
        }
        
        pager.backgroundColor = Stylesheets.Default.backgroundColor
        actionsBarBackdrop.backgroundColor = Stylesheets.Default.backgroundColor.multiply(0.97)
        
        _bookmarkListChangedSub = BookmarkList.Shared.onUpdate.subscribe({ [weak self] (_) -> () in
            self?._updateBookmarked()
        })
        BookmarkList.Shared.ensureRecency(10 * 60)
        _updateBookmarked()
        
        let hiddenSettingsRec = UILongPressGestureRecognizer(target: self, action: #selector(ArticleViewController._longPressed(_:)))
        actionsBar.addGestureRecognizer(hiddenSettingsRec)
    }
    
    func _update() {
        title = article.title
        if let content = article.content {
            if content.lowQuality ?? false {
                _viewState = .ShowWeb
            } else {
                let (models, indices) = _createRowModelsFromSegments(content.segments)
                _segmentIndicesForRowModels = indices
                rowModels = models
                _viewState = .ShowContent
            }
        } else if article.fetchFailed ?? false {
            _viewState = .ShowWeb
        } else {
            _viewState = .ShowLoading
        }
    }
    
    // MARK: Bookmarks
    var bookmarked: Bool {
        get {
            return _findMatchingBookmark() != nil
        }
        set (val) {
            let t = UpdateBookmarkTransaction()
            t.bookmark = _findMatchingBookmark()
            t.article = article
            t.delete = !val
            if val {
                t.readingPosition = [_readingPosition]
            }
            t.start()
        }
    }
    func _findMatchingBookmark() -> Bookmark? {
        return BookmarkList.Shared.bookmarksIncludingOptimistic.filter({ $0.article?.id == self.article.id }).first
    }
    
    func _updateBookmarked() {
        let imageName = bookmarked ? "BookmarkChecked" : "Bookmark"
        bookmarkButton.setImage(UIImage(named: imageName), forState: .Normal)
        bookmarkButton.setImage(UIImage(named: imageName + "-Filled"), forState: .Highlighted)
    }
    
    @IBOutlet var bookmarkButton: UIButton!
    
    @IBAction func toggleBookmarked(sender: AnyObject) {
        bookmarked = !bookmarked
    }
    
    // MARK: Layout
    static let Margin: CGFloat = 14
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    enum _ViewState {
        case ShowNothing
        case ShowContent
        case ShowWeb
        case ShowLoading
        var id: Int {
            get {
                switch self {
                case .ShowNothing: return 1
                case .ShowContent: return 2
                case .ShowLoading: return 4
                case .ShowWeb: return 5
                }
            }
        }
    }
    var _viewState = _ViewState.ShowNothing {
        willSet(newVal) {
            
            if newVal.id != _viewState.id {
                var contentAlpha: CGFloat = 0
                var loaderAlpha: CGFloat = 0
                webView = nil
                
                loadingSpinner.stopAnimating()
                
                switch newVal {
                case .ShowContent: contentAlpha = 1
                case .ShowLoading:
                    loaderAlpha = 1
                    loadingSpinner.startAnimating()
                    loadingSpinner.alpha = 0
                    delay(1.2, closure: { () -> () in
                        UIView.animateWithDuration(0.7, delay: 0, options: .AllowUserInteraction, animations: { () -> Void in
                            self.loadingSpinner.alpha = 1
                            }, completion: nil)
                    })
                case .ShowWeb:
                    webView = InlineWebView()
                    webView?.article = article
                    webView?.onClickedLink = {
                        [weak self] (url) in
                        self?.openLink(url)
                    }
                    webView?.loadingBar.backgroundColor = actionsBar.tintColor
                default: ()
                }
                
                UIView.animateWithDuration(0.2, delay: 0, options: .AllowUserInteraction, animations: { () -> Void in
                    self.pager.alpha = contentAlpha
                    self.loadingContainer.alpha = loaderAlpha
                    }, completion: nil)
            }
        }
    }
    
    @IBOutlet var loadingContainer: UIView!
    @IBOutlet var loadingSpinner: UIActivityIndicatorView!
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        pager.frame = CGRectMake(0, 0, view.bounds.size.width, view.bounds.size.height - _LayoutInfo.minBottomBarHeight)
        webView?.frame = view.bounds
        webView?.inset = UIEdgeInsetsMake(0, 0, _LayoutInfo.minBottomBarHeight, 0)
    }
    
    // MARK: Pages
    
    let pager = SwipePager<Int>(frame: CGRectZero)
    
    enum RowModel {
        case Text(string: NSAttributedString, margins: (CGFloat, CGFloat), seg: ArticleContent.TextSegment)
        case Image(ArticleContent.ImageSegment)
    }
    
    struct PageModel {
        init() {}
        var rowModels = [(RowModel, CGFloat)]() // (rowModel, offset)
        var height: CGFloat = 0
        var marginTop: CGFloat = 0
        var indexOfFirstSegmentStarted: Int?
    }
    
    func _pageIndexForReadingPosition(pos: Int) -> Int? {
        if let info = _layoutInfo {
            var pageIdx: Int?
            var i = 0
            for page in info.pages {
                if let firstIndex = page.indexOfFirstSegmentStarted where pos >= firstIndex {
                    pageIdx = i
                }
                i += 1
            }
            return pageIdx
        } else {
            return nil
        }
    }
    
    func _createRowModelsFromSegments(segments: [ArticleContent.Segment]) -> ([RowModel], [Int]) {
        var models = [RowModel]()
        var segmentIndices = [Int]()
        var trailingMargin = false
        var i = 0
        for seg in segments {
            if let image = seg as? ArticleContent.ImageSegment {
                models.append(RowModel.Image(image))
                segmentIndices.append(i)
                trailingMargin = false
            } else if let text = seg as? ArticleContent.TextSegment {
                let attributedString = NSMutableAttributedString()
                text.span.appendToAttributedString(attributedString)
                let maxCharLen = 5000
                while attributedString.length > 0 {
                    let take = min(attributedString.length, maxCharLen)
                    let substring = attributedString.attributedSubstringFromRange(NSMakeRange(0, take)).mutableCopy() as! NSMutableAttributedString
                    attributedString.deleteCharactersInRange(NSMakeRange(0, take))
                    let marginTop = (trailingMargin ? 0 : ArticleViewController.Margin) + text.extraTopPadding
                    let marginBottom = ArticleViewController.Margin + text.extraBottomPadding
                    substring.stripWhitespace()
                    models.append(RowModel.Text(string: substring, margins: (marginTop, marginBottom), seg: text))
                    segmentIndices.append(i)
                    trailingMargin = true
                }
            }
            i += 1
        }
        return (models, segmentIndices)
    }
    
    var rowModels: [RowModel]? {
        didSet {
            _recomputeLayoutInfo()
        }
    }
    var _segmentIndicesForRowModels: [Int]?
    
    func cellForModel(model: RowModel) -> ArticleSegmentCell {
        switch model {
        case .Image(let segment):
            let cell = ImageSegmentTableViewCell()
            cell.segment = segment
            return cell
        case .Text(let string, let margins, let seg):
            let cell = TextSegmentTableViewCell()
            cell.string = string
            cell.segment = seg
            cell.margin = UIEdgeInsetsMake(margins.0, ArticleViewController.Margin, margins.1, ArticleViewController.Margin)
            cell.onClickedLink = {
                [weak self]
                (let url) in
                self?.openLink(url)
            }
            return cell
        }
    }
    
    func _pageViewForIndex(i: Int) -> UIView {
        let v = ArticlePageView(frame: CGRectMake(0,0,100,100))
        if let model = _layoutInfo?.pages[i] {
            var views = [(ArticleSegmentCell, CGFloat, CGFloat)]() // cell, y-offset, height
            for (row, offset) in model.rowModels {
                if views.count > 0 {
                    views[views.count - 1].2 = offset - views[views.count - 1].1
                }
                views.append((cellForModel(row), offset, 0))
            }
            views[views.count - 1].2 = model.height - views[views.count - 1].1
            v.views = views
            v.marginTop = model.marginTop
            v.backgroundColor = UIColor.whiteColor()
        }
        return v
    }
    
    // MARK: Reading position
    var __readingPosition: Int = 0
    var _readingPosition: Int {
        get {
            return __readingPosition
        }
        set(val) {
            if __readingPosition != val {
                __readingPosition = val
                if let b = _findMatchingBookmark() {
                    let t = UpdateBookmarkTransaction()
                    t.article = article
                    t.readingPosition = [_readingPosition]
                    t.bookmark = b
                    t.start()
                }
            }
        }
    }
    
    // MARK: LayoutInfo
    var _layoutInfo: _LayoutInfo?
    var _layoutQueue = dispatch_queue_create("ArticleLayoutQueue", nil)
    func _recomputeLayoutInfo() {
        _layoutInfo = nil
        pager.pageModels = []
        viewDidLayoutSubviews()
        let info = _LayoutInfo()
        let size = pager.bounds.size
        info.size = size
        
        let done: () -> () = {
            if info.size == size {
                self._layoutInfo = info
                self.pager.pageModels = Array(0..<(info.pages.count))
                if let pageIdx = self._pageIndexForReadingPosition(self._readingPosition) {
                    self.pager.page = pageIdx
                }
            }
        }
        
        if let models = rowModels, let segmentIndices = _segmentIndicesForRowModels {
            dispatch_async(_layoutQueue, { 
                info.computeWithModels(models, segmentIndices: segmentIndices)
                mainThread(done)
            })
        } else {
            done()
        }
    }
    
    class _LayoutInfo {
        var size = CGSizeZero
        var pages = [PageModel]()
        
        func computeWithModels(models: [RowModel], segmentIndices: [Int]) {
            let maxPageHeight = size.height
            
            pages = [PageModel()]
            for (model, segmentIdx) in zip(models, segmentIndices) {
                if pages.last!.indexOfFirstSegmentStarted == nil {
                    pages[pages.count - 1].indexOfFirstSegmentStarted = segmentIdx
                }
                var addedYet = false
                var localPoints = pageBreakPointsForModel(model)
                localPoints[localPoints.count-1] = ceil(localPoints.last!)
                
                var prevLocalPoint: CGFloat = 0
                for point in localPoints.filter({ $0 != 0 }).map({ ceil($0) }) {
                    if point - prevLocalPoint + pages.last!.height + pages.last!.marginTop > maxPageHeight {
                        // create a new page:
                        pages.append(PageModel())
                        pages[pages.count - 1].rowModels.append((model, -prevLocalPoint))
                        // if this is a text field w/ no margin, or mid-text, append a margin:
                        switch model {
                        case .Text(string: _, margins: (let topMargin, _), seg: _):
                            if topMargin == 0 || addedYet {
                                pages[pages.count - 1].marginTop = ArticleViewController.Margin
                            }
                        default: ()
                        }
                    } else if !addedYet {
                        pages[pages.count - 1].rowModels.append((model, pages.last!.height))
                    }
                    pages[pages.count - 1].height += point - prevLocalPoint
                    prevLocalPoint = point
                    addedYet = true
                }
            }
        }
        
        static var minBottomBarHeight: CGFloat = 44
        
        func heightForModel(model: RowModel) -> CGFloat {
            switch model {
            case .Image(let segment):
                return ceil(ImageSegmentTableViewCell.heightForSegment(segment, width: size.width, maxHeight: size.height))
            case .Text(let text, let margins, seg: _):
                let margin = UIEdgeInsetsMake(margins.0, ArticleViewController.Margin, margins.1, ArticleViewController.Margin)
                return ceil(TextSegmentTableViewCell.heightForString(text, width: size.width, margin: margin))
            }
        }
        
        func pageBreakPointsForModel(model: RowModel) -> [CGFloat] {
            switch model {
            case .Text(string: let str, margins: (let topMargin, let bottomMargin), seg: _):
                return TextSegmentTableViewCell.pageBreakPointsForSegment(str, width: size.width, margin: UIEdgeInsetsMake(topMargin, ArticleViewController.Margin, bottomMargin, ArticleViewController.Margin))
            default:
                return [0, heightForModel(model)]
            }
        }
    }
    
    // MARK: Actions
    func openLink(url: NSURL) {
        let vc = SFSafariViewController(URL: url)
        presentViewController(vc, animated: true, completion: nil)
    }
    
    @IBAction func share(sender: AnyObject) {
        let safariVCActivity = SafariVCActivity(parentViewController: self)
        let activityVC = UIActivityViewController(activityItems: [NSURL(string: article.url!)!], applicationActivities: [safariVCActivity])
        // activityVC.excludedActivityTypes = []
        presentViewController(activityVC, animated: true, completion: nil)
    }
    
    @IBOutlet var actionsBarBackdrop: UIView!
    @IBOutlet var actionsBar: UIView!
    
    @IBAction func dismiss() {
        if let cb = onBack {
            cb()
        } else {
            _induceExit()
        }
    }
    
    var onBack: (() -> ())?
    
    // MARK: WebView
    var webView: InlineWebView? {
        willSet(newVal) {
            webView?.removeFromSuperview()
            if let new = newVal {
                contentView.insertSubview(new, aboveSubview: pager)
            }
        }
    }
    
    // MARK: Hidden Settings
    func _longPressed(sender: UILongPressGestureRecognizer) {
        if sender.state == .Ended {
            presentHiddenSettingsUIFromArticle(self)
        }
    }
}

