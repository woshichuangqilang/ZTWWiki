//
//  ViewController.swift
//  ZTWWiki
//
//  Created by Wenslow on 16/1/14.
//  Copyright © 2016年 Wenslow. All rights reserved.
//

import UIKit
import Alamofire

class PopularViewController: UITableViewController, UITabBarControllerDelegate, MGSwipeTableCellDelegate{
    
    let baseUptrendsTodayURL = "https://www.kimonolabs.com/api/8kvt5rsc?"
    let baseUptrendsThisWeekURL = "https://www.kimonolabs.com/api/7j325gnu?"
    let baseUptrendsThisMonthURL = "https://www.kimonolabs.com/api/8ah1r1v0??"
    let baseDowntrendsTodayURL = "https://www.kimonolabs.com/api/6yfhj48m?"
    let baseDowntrendsThisWeekURL = "https://www.kimonolabs.com/api/57jd2kae?"
    let baseDowntrendsThisMonthURL = "https://www.kimonolabs.com/api/bcpftmzq?"
    let baseMostVisitedTodayURL = "https://www.kimonolabs.com/api/cjj1ini0?"
    let baseMostVisitedThisWeekURL = "https://www.kimonolabs.com/api/aw60115u?"
    let baseMostVisitedThisMonthURL = "https://www.kimonolabs.com/api/8bltv4ug?"
    let baseWikiImageURL = "https://en.wikipedia.org/w/api.php?"
    let apiKey = "ZyxnQM3AIL6U6zEjfrXJeG5u4CCC90rW"
    let popularStore = PopularStore()
    let menuItems = ["Today", "This week", "This Month"]
    let webStore = WebStore()
    
    var popularContainers = [WikiContainer]()
    var selectedMenuIndex = 0
    var bookMarkStringArray = [String]()
    var thisPageIsMarked = false
    //下拉更新功能
    var reControl: UIRefreshControl!
    
    @IBOutlet weak var segmentValue: UISegmentedControl!
    //MARK: 点击segment更新数据
    @IBAction func wikiTypeChange(sender: AnyObject) {
        self.updateData(self.selectedMenuIndex, selectedSegmentIndex: self.segmentValue.selectedSegmentIndex)
    }
    //MARK: 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
    
        //设置navigationbar
        self.navigationController?.navigationBar.translucent = true
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 20/250, green:101/250, blue:180/250, alpha: 1.0)
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        //设置navigationbar的下拉菜单
        let menuView = BTNavigationDropdownMenu(navigationController: self.navigationController, title: menuItems.first!, items: menuItems)
        self.menuConfig(menuView)
        //选择下拉菜单时，更新数据
        menuView.didSelectItemAtIndexHandler = {(indexPath: Int) -> () in
            self.selectedMenuIndex = indexPath
            self.updateData(self.selectedMenuIndex, selectedSegmentIndex: self.segmentValue.selectedSegmentIndex)
        }
        
        self.navigationItem.titleView = menuView
        //启动时获取数据
        self.updateData(self.selectedMenuIndex, selectedSegmentIndex: self.segmentValue.selectedSegmentIndex)
        //下拉更新
        reControl = UIRefreshControl()
        self.tableView.addSubview(reControl)
        self.tableView.tableFooterView = UIView()
        self.navigationController?.hidesBarsOnSwipe = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.tabBarController?.tabBar.hidden = false
        //获取书签的title数组
        bookMarkStringArray = self.webStore.fetchBookMarkTitles()
    }
    
    //MARK: tableView行数
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return popularContainers.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("UITableCell", forIndexPath: indexPath) as! ItemCell
        
        let popularContainer = popularContainers[indexPath.row]

        cell.titleLabel.text = "\(popularContainer.title!) \(popularContainer.digit!)"
        cell.contextLabel.text = popularContainer.wikiContext
        
        if popularContainer.image != nil {
            let imageView = UIImageView(image: popularContainer.image)
            cell.accessoryView = imageView
        } else {
            cell.accessoryView = nil
        }
        //设定title颜色
        switch self.segmentValue.selectedSegmentIndex {
        case 0: cell.titleLabel.textColor = UIColor(red: 207/250, green: 0, blue: 0, alpha: 1.0)
        case 1: cell.titleLabel.textColor = UIColor(red: 0, green: 128/250, blue: 0, alpha: 1.0)
        default: cell.titleLabel.textColor = UIColor(red: 0, green: 64/250, blue: 128/250, alpha: 1.0)
        }
        
        //从左向右滑动分享
        cell.leftExpansion.fillOnTrigger = true
        cell.leftSwipeSettings.transition = .Border
        cell.leftExpansion.buttonIndex = 0
        let shareImage = UIImage(named: "share")
        cell.leftButtons = [MGSwipeButton(title: "", icon: shareImage, backgroundColor: UIColor(red: 0.0, green: 122/255, blue: 1.0, alpha: 1.0), callback: { (sender: MGSwipeTableCell!) -> Bool in
            let actController = UIActivityViewController(activityItems: [popularContainer.remoteURL!], applicationActivities: nil)
            self.presentViewController(actController, animated: true, completion: nil)
            return true
        })]
        
        cell.rightSwipeSettings.transition = .Border
        cell.rightExpansion.buttonIndex = 0
        cell.rightExpansion.fillOnTrigger = true
        let markImage = UIImage(named: "mark")
        //从右向左滑动保存书签
        cell.rightButtons = [MGSwipeButton(title: "", icon: markImage, backgroundColor: UIColor(red: 0.0, green: 207/250, blue: 107/250, alpha: 1.0), callback: { (sender: MGSwipeTableCell!) -> Bool in
            self.addOrDeleteBookMark(popularContainer)
            self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
            print("Marked")
            return true
        })] 
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    //MARK:向WebViewController传值
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //判断目标segue是否是 ShowItem
        if segue.identifier == "popularToWeb" {
            //设置要传值的行数
            if let row = tableView.indexPathForSelectedRow?.row {
                let popularContainer = popularContainers[row]
                let webViewController = segue.destinationViewController as! WebViewController
                webViewController.popularContainer = popularContainer
            }
        }
    }
    
    //MARK: 设置menu菜单属性
    private func menuConfig(menuView: BTNavigationDropdownMenu) {
        menuView.cellHeight = 50
        menuView.cellBackgroundColor = self.navigationController?.navigationBar.barTintColor
        menuView.cellSelectionColor = UIColor(red: 20/250, green:101/250, blue:180/250, alpha: 1.0)
        menuView.cellTextLabelColor = UIColor.whiteColor()
        menuView.cellTextLabelFont = UIFont(name: "Avenir-Heavy", size: 17)
        menuView.cellTextLabelAlignment = .Left
        menuView.arrowPadding = 15
        menuView.animationDuration = 0.5
        menuView.maskBackgroundColor = UIColor.blackColor()
        menuView.maskBackgroundOpacity = 0.3
    }
    
    //MARK: 实现下拉更新
    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if reControl.refreshing {
            self.updateData(self.selectedMenuIndex, selectedSegmentIndex: self.segmentValue.selectedSegmentIndex)
        }
    }
    
    //MARK: 添加或者删除书签
    func addOrDeleteBookMark(wikiContainer: WikiContainer) {
        switch bookMarkStringArray.contains(wikiContainer.title!) {
        case true: thisPageIsMarked = true
        default: thisPageIsMarked = false
        }
        //增加警告
        let title = "Book Mark"
        var message: String!
        var bookMarkAction: UIAlertAction!
        if thisPageIsMarked == true && !bookMarkStringArray.isEmpty {
            message = "Remove this entry from your Book Mark?"
        } else{
            message = "Save this entry to your Book Mark?"
        }
        let ac = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "Cancle", style: .Cancel, handler: nil)
        
        ac.addAction(cancelAction)
        
        if thisPageIsMarked == true && !bookMarkStringArray.isEmpty {
            bookMarkAction = UIAlertAction(title: "Remove", style: .Destructive, handler: {
                (action) -> Void in
                //删除书签
                self.bookMarkStringArray = self.webStore.deleteBookMark(wikiContainer.title!, titles: self.bookMarkStringArray)
                    self.thisPageIsMarked = false
            })
        } else{
            bookMarkAction = UIAlertAction(title: "Save", style: .Default, handler: {
                (action) -> Void in
                //保存书签
                print(wikiContainer.imageKey)
                self.bookMarkStringArray = self.popularStore.saveBookMark(wikiContainer, titles: self.bookMarkStringArray)
                self.thisPageIsMarked = true
            })
        }
        ac.addAction(bookMarkAction)
        self.presentViewController(ac, animated: true, completion: nil)
    }
    
    private func updateData(selectedMenuIndex: Int, selectedSegmentIndex: Int){
       
        var baseParams = [
            "apikey": apiKey,
            "kimpath1": "wikitrends"
        ]
        var baseURL: String!
        self.popularContainers = [WikiContainer]()
        
        //选择今天、本周或者本月热门词条的URL
        switch (selectedMenuIndex, selectedSegmentIndex){
        case (0, 0): baseURL = baseUptrendsTodayURL
        baseParams["kimpath2"] = "english-uptrends-today.html"
        case (1, 0): baseURL = baseUptrendsThisWeekURL
        baseParams["kimpath2"] = "english-uptrends-this-week.html"
        case (2, 0): baseURL = baseUptrendsThisMonthURL
        baseParams["kimpath2"] = "english-uptrends-this-month.html"
        case (0, 1): baseURL = baseDowntrendsTodayURL
        baseParams["kimpath2"] = "english-downtrends-today.html"
        case (1, 1): baseURL = baseDowntrendsThisWeekURL
        baseParams["kimpath2"] = "english-downtrends-this-week.html"
        case (2, 1): baseURL = baseDowntrendsThisMonthURL
        baseParams["kimpath2"] = "english-downtrends-this-month.html"
        case (0, 2): baseURL = baseMostVisitedTodayURL
        baseParams["kimpath2"] = "english-most-visited-today.html"
        case (1, 2): baseURL = baseMostVisitedThisWeekURL
        baseParams["kimpath2"] = "english-most-visited-this-week.html"
        default: baseURL = baseMostVisitedThisMonthURL
        baseParams["kimpath2"] = "english-most-visited-this-month.html"
        }
        //获取json数据
        self.fetchJSONData(baseURL, baseParams: baseParams)
    }
    
    //MARK: 获取json数据
    private func fetchJSONData(baseURL: String, baseParams: [String: String]) {
        Alamofire.request(.GET, baseURL, parameters: baseParams)
            .responseJSON { response in
                
                if let jsonData = response.result.value {
                    let jsonObject = JSON(jsonData)
                    
                    for i in 0..<10 {
                        let item = WikiContainer(title: " ", remoteURL: NSURL(string: "https://en.wikipedia.org")!, wikiContext: " ")
                        
                        item.title = jsonObject["results"]["collection1"][i]["title"]["text"].string
                        item.digit = jsonObject["results"]["collection1"][i]["digit"].string
                        item.wikiContext = jsonObject["results"]["collection1"][i]["context"].string
                        
                        let jURL = jsonObject["results"]["collection1"][i]["title"]["href"].string
                        item.remoteURL = NSURL(string: jURL!)
                        //获取图片
                        self.fetchSinglePopularImageURL(item)
                        self.popularContainers.append(item)
                    }
                }
        }
    }
    
    //MARK: 获取图片url
    private func fetchSinglePopularImageURL(item: WikiContainer) {
        Alamofire.request(.GET, self.baseWikiImageURL, parameters: ["action": "query",
            "format": "json",
            "prop": "pageimages",
            "pithumbsize": "144",
            "titles": item.title!])
            .responseJSON { response in
                
                if let jsonData = response.result.value {
                    let jsonObject = JSON(jsonData)
                    let jSONPages = Array(jsonObject["query"]["pages"].dictionaryValue.keys)
                    
                    if let jImage = jsonObject["query"]["pages"][jSONPages[0]]["thumbnail"]["source"].string{
                        item.imageURL = NSURL(string: jImage)
                        self.downloadSinglePopularImage(jImage, item: item)
                    }
                }
        }
    }
    
    //MARK: 获取单张图片
    private func downloadSinglePopularImage(urlString: String, item: WikiContainer) {
        Alamofire.request(.GET, urlString).response(completionHandler: { (_, _, data,_) -> Void in
            if let imageData = data {
                item.image = UIImage(data: imageData, scale: 1.8)
            }
            self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
            //停止刷新动画
            self.reControl.endRefreshing()
        })
    }
}