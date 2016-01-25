//
//  WebViewController.swift
//  ZTWWiki
//
//  Created by Wenslow on 16/1/15.
//  Copyright © 2016年 Wenslow. All rights reserved.
//

import UIKit
import WebKit
import CoreData

class WebViewController: UIViewController, WKNavigationDelegate, UIScrollViewDelegate{
    
    let coreDataStack = CoreDataStack(modelName: "ZTWWiki")
    let fetchRequest = NSFetchRequest()
    let store = WebStore()
    let imageStore = ImageStore()
    let titleSuffix = " - Wikipedia, the free encyclopedia"
    let urlPrefix = "https://en.m.wikipedia.org/wiki/"
    
    
    var webView: WKWebView!
    var popularContainer: WikiContainer?
    var tempWikiContainer = WikiContainer(title: " ", remoteURL: NSURL(string: "https://en.wikipedia.org")!, wikiContext: " ")
    var historyStringArray = [String]()
    var bookMarkStringArray = [String]()
    var thisPageIsMarked = false
    var lastOffsetY: CGFloat = 0
    

    @IBOutlet weak var processView: UIProgressView!
    //MARK: 设置底部toolbar
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var forwardButton: UIBarButtonItem!
    @IBOutlet weak var bookmarkButton: UIBarButtonItem!
    @IBOutlet weak var reloadButton: UIBarButtonItem!
    @IBAction func back(sender: UIBarButtonItem) {
        webView.goBack()
    }
    @IBAction func forward(sender: UIBarButtonItem) {
        webView.goForward()
    }
    //书签功能
    @IBAction func bookMark(sender: UIBarButtonItem) {
        if thisPageIsMarked == true && !bookMarkStringArray.isEmpty {
            //删除书签
            bookMarkStringArray = self.store.deleteBookMark(tempWikiContainer.title!, titles: bookMarkStringArray)
            thisPageIsMarked = false
            bookmarkButton.image = UIImage(named: "unbookMarked")
        } else{
            //保存书签
            bookMarkStringArray = self.store.saveBookMark(tempWikiContainer, titles: bookMarkStringArray)
            thisPageIsMarked = true
            bookmarkButton.image = UIImage(named: "bookMarked")
        }
    }
    //刷新页面
    @IBAction func reload(sender: UIBarButtonItem) {
        if webView.URL != nil {
            let request = NSURLRequest(URL: webView.URL!)
            webView.loadRequest(request)
        }
    }
    //MARK: 分享功能
    @IBAction func shareButton(sender: AnyObject) {
        let actController = UIActivityViewController(activityItems: [self.webView.URL!], applicationActivities: nil)
        presentViewController(actController, animated: true, completion: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        self.webView = WKWebView(frame: CGRectZero)
        super.init(coder: aDecoder)!
    }
    
    //MARK: 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.insertSubview(webView, belowSubview: processView)
        //webview 的 frame
        webView.translatesAutoresizingMaskIntoConstraints = false
        let topConstrain = webView.topAnchor.constraintEqualToAnchor(view.topAnchor)
        let leadingConstrain = webView.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor)
        let trailingConstrain = webView.trailingAnchor.constraintEqualToAnchor((view.trailingAnchor))
        let bottomConstrain = webView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor, constant: -44)
        topConstrain.active = true
        leadingConstrain.active = true
        trailingConstrain.active = true
        bottomConstrain.active = true
        
        //添加页面载入进度的观察者
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .New, context: nil)
        webView.addObserver(self, forKeyPath: "loading", options: .New, context: nil)
        
        //载入指定页面
        let req = NSURLRequest(URL: (popularContainer?.remoteURL)!)
        print(popularContainer?.remoteURL)
        webView.loadRequest(req)
        
        //允许手势返回
        self.webView.allowsBackForwardNavigationGestures = true
        self.webView.navigationDelegate = self
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        
        
        //获取书签的title数组
        bookMarkStringArray = self.store.fetchBookMarkTitles()

    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.awakeFromNib()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.hidesBottomBarWhenPushed = true
    }
    
    //MARK: 页面载入完成时，存储数据
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        //显示网页标题
        self.navigationItem.title = self.webView.title
        
        //判断前进和后退按钮是否可用
        switch self.webView.canGoBack {
        case true: backButton.enabled = true
        default: backButton.enabled = false
        }
        switch self.webView.canGoForward {
        case true: forwardButton.enabled = true
        default: forwardButton.enabled = false
        }
        
        //进度条
        processView.setProgress(0.0, animated: false)
        
        //判断页面是否为维基百科页面
        if String(self.webView.title).containsString(titleSuffix) && String(self.webView.URL).containsString(urlPrefix){
            
            //设置tempWikiContainer的title和imageKey
            let range = self.webView.title?.rangeOfString(titleSuffix)
            tempWikiContainer.imageKey = NSUUID().UUIDString
            tempWikiContainer.title = self.webView.title?.stringByReplacingCharactersInRange(range!, withString: "")
            
            //标题不重复
            if historyStringArray.contains((tempWikiContainer.title)!) == false {
                historyStringArray.append((tempWikiContainer.title)!)
                
                tempWikiContainer.remoteURL = self.webView.URL
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)){
                    self.tempWikiContainer.wikiContext = self.store.fetchSingleWikiContext(self.tempWikiContainer.title!)
                    self.tempWikiContainer.image = self.store.fetchSingleImage(self.tempWikiContainer.title!, imageKey: self.tempWikiContainer.imageKey)
                    dispatch_async(dispatch_get_main_queue()){
                        //保存历史记录
                        self.store.storeHistory(self.tempWikiContainer)
                    }
                }
            }
            
            //只在维基页面启用书签按钮
            bookmarkButton.enabled = true
            //判断该页面是否已经包含在书签中
            if bookMarkStringArray.contains(tempWikiContainer.title!) == false {
                thisPageIsMarked = false
                bookmarkButton.image = UIImage(named: "unbookMarked")
            } else {
                thisPageIsMarked = true
                bookmarkButton.image = UIImage(named: "bookMarked")
            }
        }
    }
    
    //MARK: 观察者－进度条
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if (keyPath == "loading") {
            bookmarkButton.enabled = false
            backButton.enabled = self.webView.canGoBack
            forwardButton.enabled = self.webView.canGoForward
        }
        //进度条动画实现
        if (keyPath == "estimatedProgress") {
            processView.hidden = webView.estimatedProgress == 1
            processView.setProgress(Float(webView.estimatedProgress), animated: true)
            bookmarkButton.enabled = true
        }
    }
    
    //MARK: destroy观察者
    deinit {
        self.webView.removeObserver(self, forKeyPath: "loading")
        self.webView.removeObserver(self, forKeyPath: "estimatedProgress")
    }
}