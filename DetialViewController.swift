//
//  DetialViewController.swift
//  ZTWWiki
//
//  Created by Wenslow on 16/1/17.
//  Copyright © 2016年 Wenslow. All rights reserved.
//

import UIKit
import CoreData
import MessageUI
class DetialViewController: UITableViewController, MFMailComposeViewControllerDelegate {

    let coreDataStack = CoreDataStack(modelName: "ZTWWiki")
    let entityNames = ["HistoryWikiContainer", "BookMarkWikiContainer"]
    let store = HistoryAndBookMarkStore()
    let fetchRequest = NSFetchRequest()
    //let imageStore = ImageStore()
    let navigationTitle = ["Recent 50 Histories", "BookMark"]
    //let addOrRemoveBookMarkMethod = PopularViewController()
    let popularStore = PopularStore()
    let webStore = WebStore()
    
    var wikiContainers = [WikiContainer]()
    var selectedIndex = 0
    var bookMarkStringArray = [String]()
    var thisPageIsMarked = false
    
    //@IBOutlet weak var subTitle: UILabel!
    @IBOutlet weak var emailButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBAction func changeSegmentIndex(sender: AnyObject) {
        wikiContainers = self.store.loadData(entityNames[segmentControl.selectedSegmentIndex])
        //获取书签的title数组
        bookMarkStringArray = self.webStore.fetchBookMarkTitles()
        self.navigationItem.title = navigationTitle[segmentControl.selectedSegmentIndex]
        self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
    }
    @IBAction func sendEmail(sender: AnyObject) {
        //发送email
        let emailTitle = ""
        let messageBody = "Hello Wenslow"
        let toRecipent = ["wenslow.vip@gmail.com"]
        let mc = MFMailComposeViewController()
        
        mc.mailComposeDelegate = self
        mc.setSubject(emailTitle)
        mc.setMessageBody(messageBody, isHTML: true)
        mc.setToRecipients(toRecipent)
        self.presentViewController(mc, animated: true, completion: nil)
    }
    @IBAction func deleteAll(sender: AnyObject) {
        //删除所有数据
        let title = self.navigationItem.title
        let message = "Are you sure to delete all data"
        let ac = UIAlertController(title: title, message: message, preferredStyle: .ActionSheet)
        let cancelAction = UIAlertAction(title: "Cancle", style: .Cancel, handler: nil)
        ac.addAction(cancelAction)
        let deleteAction = UIAlertAction(title: "Delete", style: .Destructive, handler: {
            (action) -> Void in
            self.store.deleteAllItems(self.entityNames[self.segmentControl.selectedSegmentIndex])
            self.wikiContainers.removeAll()
            self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
            
        })
        ac.addAction(deleteAction)
        presentViewController(ac, animated: true, completion: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        navigationItem.rightBarButtonItem = editButtonItem()
    }
    
    //MARK: 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.backItem?.title = "Back"
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.deleteButton.hidden = true
        self.emailButton.hidden = true
        self.navigationItem.rightBarButtonItem?.enabled = true
        switch selectedIndex{
        case 0: self.navigationItem.title = navigationTitle[segmentControl.selectedSegmentIndex]
            //wikiContainers = self.store.loadData(entityNames[segmentControl.selectedSegmentIndex])
        default: self.navigationItem.title = "Email Me"
            self.emailButton.hidden = false
            self.segmentControl.hidden = true
            self.navigationItem.rightBarButtonItem?.enabled = false
            self.navigationItem.rightBarButtonItem?.tintColor = UIColor(red: 20/250, green:101/250, blue:180/250, alpha: 1.0)
        }
        self.tableView.reloadData()
        //self.tableView.tableFooterView = UIView()
        self.navigationController?.hidesBarsOnSwipe = true
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        wikiContainers = self.store.loadData(entityNames[segmentControl.selectedSegmentIndex])
        //获取书签的title数组
        bookMarkStringArray = self.webStore.fetchBookMarkTitles()
        self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
    }
    
    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch selectedIndex {
        case 0: return wikiContainers.count
        default: return 0
        }
    }
        
    //MARK: 设置cell内容
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("DetialCell", forIndexPath: indexPath) as! ItemCell
        let item = wikiContainers[indexPath.row]
        
        cell.titleLabel.text = item.title
        cell.contextLabel.text = item.wikiContext
        if item.image != nil {
            let imageView = UIImageView(image: item.image)
            cell.accessoryView = imageView
        } else {
            cell.accessoryView = nil
        }
        
        //从左向右滑动分享
        cell.leftExpansion.fillOnTrigger = true
        cell.leftSwipeSettings.transition = .Border
        cell.leftExpansion.buttonIndex = 0
        let shareImage = UIImage(named: "share")
        let markImage = UIImage(named: "mark")
        if segmentControl.selectedSegmentIndex == 0 {
            //书签
        cell.leftButtons = [MGSwipeButton(title: "", icon: shareImage, backgroundColor: UIColor(red: 0.0, green: 122/255, blue: 1.0, alpha: 1.0), callback: { (sender: MGSwipeTableCell!) -> Bool in
            let actController = UIActivityViewController(activityItems: [item.remoteURL!], applicationActivities: nil)
            self.presentViewController(actController, animated: true, completion: nil)
            return true
        }),//分享
            MGSwipeButton(title: "", icon: markImage, backgroundColor: UIColor(red: 0.0, green: 207/250, blue: 107/250, alpha: 1.0), callback: { (sender: MGSwipeTableCell!) -> Bool in
            self.addOrDeleteBookMark(item)
            self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
            return true
        })]
        }else {
            //分享
            cell.leftButtons = [MGSwipeButton(title: "", icon: shareImage, backgroundColor: UIColor(red: 0.0, green: 122/255, blue: 1.0, alpha: 1.0), callback: { (sender: MGSwipeTableCell!) -> Bool in
                let actController = UIActivityViewController(activityItems: [item.remoteURL!], applicationActivities: nil)
                self.presentViewController(actController, animated: true, completion: nil)
                print("Share")
                return true
            })]
        }
        
        
        cell.rightSwipeSettings.transition = .Border
        cell.rightExpansion.buttonIndex = 0
        cell.rightExpansion.fillOnTrigger = true
        //从右向左滑动保存书签
        let deleteImage = UIImage(named: "pac-man")
        cell.rightButtons = [MGSwipeButton(title: "", icon: deleteImage, backgroundColor: UIColor.redColor(), callback: { (sender: MGSwipeTableCell!) -> Bool in
            self.wikiContainers.removeAtIndex(indexPath.row)
            self.store.deleteSingleItem(indexPath.row + 1, entityName: self.entityNames[self.segmentControl.selectedSegmentIndex])
            self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
            print("Delete")
            return true
        })]
        
        return cell
    }
    
    //MARK:向WebViewController传值
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //判断目标segue是否是 ShowItem
        if segue.identifier == "detialToWeb" {
            //设置要传值的行数
            if let row = tableView.indexPathForSelectedRow?.row {
                let popularContainer = wikiContainers[row]
                let detialWebViewController = segue.destinationViewController as! WebViewController
                detialWebViewController.popularContainer = popularContainer
            }
        }
    }
    
    //MARK: 删除单条数据
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            self.wikiContainers.removeAtIndex(indexPath.row)
            self.store.deleteSingleItem(indexPath.row + 1, entityName: self.entityNames[self.segmentControl.selectedSegmentIndex])
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    //MARK: 设置deleteAll 按钮是否隐藏
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: true)
        switch editing {
        case true: self.deleteButton.hidden = false
        default: self.deleteButton.hidden = true
        }
    }
    
    //MARK: 发送email后，返回原界面
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        switch result {
        case MFMailComposeResultCancelled: print("Mail cancelled")
        case MFMailComposeResultSaved: print("Mail Saved")
        case MFMailComposeResultSent: print("Mail Sent")
        case MFMailComposeResultFailed: print("Mail sent failure \(error)")
        default: break
        }
        self.dismissViewControllerAnimated(true, completion: nil)
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
            bookMarkAction = UIAlertAction(title: "OK", style: .Default, handler: {
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
}
