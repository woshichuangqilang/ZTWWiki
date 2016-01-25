//
//  NearByTableViewController.swift
//  ZTWWiki
//
//  Created by Wenslow on 16/1/23.
//  Copyright © 2016年 Wenslow. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Alamofire
import Toucan
import WebKit

//MARK: extension
extension MKMapView {
    
    var MERCATOR_OFFSET:Double {
        return 268435456.0
    }
    var MERCATOR_RADIUS:Double {
        return 85445659.44705395
    }
    
    public func setCenterCoordinateLevel(centerCoordinate:CLLocationCoordinate2D,var zoomLevel:Double,animated:Bool) {
        //设置最小缩放级别
        zoomLevel  = min(zoomLevel, 22)
        
        let span   = self.coordinateSpanWithMapView(self, centerCoordinate: centerCoordinate, zoomLevel: zoomLevel);
        let region = MKCoordinateRegionMake(centerCoordinate, span);
        
        self.setRegion(region, animated: animated)
        
    }
    
    func longitudeToPixelSpaceX(longitude:Double) ->Double {
        return round(MERCATOR_OFFSET + MERCATOR_RADIUS * longitude * M_PI / 180.0)
    }
    
    func latitudeToPixelSpaceY(latitude:Double) ->Double {
        return round(MERCATOR_OFFSET - MERCATOR_RADIUS * log((1 + sin(latitude * M_PI / 180.0)) / (1 - sin(latitude * M_PI / 180.0))) / 2.0)
    }
    
    func pixelSpaceXToLongitude(pixelX:Double) ->Double {
        return ((round(pixelX) - MERCATOR_OFFSET) / MERCATOR_RADIUS) * 180.0 / M_PI
    }
    
    func pixelSpaceYToLatitude(pixelY:Double) ->Double {
        return (M_PI / 2.0 - 2.0 * atan(exp((round(pixelY) - MERCATOR_OFFSET) / MERCATOR_RADIUS))) * 180.0 / M_PI
    }
    
    func coordinateSpanWithMapView(mapView:MKMapView,
        centerCoordinate:CLLocationCoordinate2D,
        zoomLevel:Double) -> MKCoordinateSpan
    {
        let centerPixelX = self.longitudeToPixelSpaceX(centerCoordinate.longitude)
        let centerPixelY = self.latitudeToPixelSpaceY(centerCoordinate.latitude)
        let zoomExponent = 20.0 - zoomLevel
        let zoomScale = pow(2.0, zoomExponent)
        
        let mapSizeInPixels = mapView.bounds.size
        let scaledMapWidth  = Double(mapSizeInPixels.width) * zoomScale
        let scaledMapHeight = Double(mapSizeInPixels.height) * zoomScale
        
        let topLeftPixelX = centerPixelX - (scaledMapWidth/2)
        let topLeftPixelY = centerPixelY - (scaledMapHeight/2)
        
        let minLng = self.pixelSpaceXToLongitude(topLeftPixelX)
        let maxLng = self.pixelSpaceXToLongitude(topLeftPixelX + scaledMapWidth)
        let longitudeDelta = maxLng - minLng
        
        let minLat = self.pixelSpaceYToLatitude(topLeftPixelY);
        let maxLat = self.pixelSpaceYToLatitude(topLeftPixelY + scaledMapHeight);
        let latitudeDelta = -1 * (maxLat - minLat);
        
        let span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta)
        return span
    }
}



class NearByTableViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource {

    //MARK: instance
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func show(sender: AnyObject) {
        self.tableView.hidden = true
    }
    let baseWikiURL = "https://en.wikipedia.org/w/api.php?"
    let apiKey = "ZyxnQM3AIL6U6zEjfrXJeG5u4CCC90rW"
    let urlPrefix = "https://en.m.wikipedia.org/wiki/"
    let webStore = WebStore()
    let popularStore = PopularStore()
    
    var locateManage = CLLocationManager()
    var currentCoordinate: CLLocationCoordinate2D?
    var wikiContainers = [WikiContainer]()
    var annotationArray = [MKPointAnnotation]()
    var wikiTitles = [String]()
    var bookMarkStringArray = [String]()
    var thisPageIsMarked = false
    
    //MARK: 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //获取定位许可
        if self.locateManage.respondsToSelector(Selector("requestWhenInUseAuthorization")) {
            self.locateManage.requestWhenInUseAuthorization()
        }
        
        self.locateManage.desiredAccuracy = kCLLocationAccuracyBest//定位精准度
        self.locateManage.startUpdatingLocation()//开始定位
        
        self.mapView.delegate = self
        self.locateManage.delegate = self
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        //self.navigationController?.navigationBar.hidden = true
        self.navigationController?.hidesBarsOnSwipe = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.navigationBar.hidden = true
        bookMarkStringArray = self.webStore.fetchBookMarkTitles()
    }
    
    
    //MARK: 定位，然后获取数据
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let newLoca = locations.last {
            CLGeocoder().reverseGeocodeLocation(newLoca, completionHandler: { (pms, err) -> Void in
                if let newCoordinate = pms?.last?.location?.coordinate {
                    //此处设置地图中心点为定位点，缩放级别18
                    self.mapView.setCenterCoordinateLevel(newCoordinate, zoomLevel: 10, animated: true)
                    manager.stopUpdatingLocation()//停止定位，节省电量，只获取一次定位
                    
                    self.currentCoordinate = newCoordinate
                }
            })
            self.fetchJSONData(newLoca)
        }
    }

    // MARK: - Table view data source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 20
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("nearbyCell", forIndexPath: indexPath) as! ItemCell
        
        var wikiContainer = WikiContainer(title: " ", remoteURL: NSURL(), wikiContext: " ")
        
        if !wikiContainers.isEmpty{
            wikiContainer = wikiContainers[indexPath.row]
            if wikiContainer.image != nil {
                cell.accessoryView = UIImageView(image: wikiContainer.image)
            }
        }
        
        cell.titleLabel.text = wikiContainer.title
        //设置NSMutableAttributedString
        if wikiContainer.distance != nil && wikiContainer.wikiContext != nil {
            //距离显示蓝色
            let distanceString = String(format: "%0.1fkm", wikiContainer.distance! / 1000)
            let range = NSRange.init(location: 0, length: distanceString.characters.count)
            let str = NSMutableAttributedString(string: "\(distanceString) \(wikiContainer.wikiContext!)")
            str.addAttribute(NSForegroundColorAttributeName, value: UIColor(red: 20/250, green:101/250, blue:180/250, alpha: 1.0), range: range)
            cell.contextLabel.attributedText = str
        }
        
        //从左向右滑动分享
        cell.leftExpansion.fillOnTrigger = true
        cell.leftSwipeSettings.transition = .Border
        cell.leftExpansion.buttonIndex = 0
        let shareImage = UIImage(named: "share")
        cell.leftButtons = [MGSwipeButton(title: "", icon: shareImage, backgroundColor: UIColor(red: 0.0, green: 122/255, blue: 1.0, alpha: 1.0), callback: { (sender: MGSwipeTableCell!) -> Bool in
            let actController = UIActivityViewController(activityItems: [wikiContainer.remoteURL!], applicationActivities: nil)
            self.presentViewController(actController, animated: true, completion: nil)
            return true
        })]
        
        cell.rightSwipeSettings.transition = .Border
        cell.rightExpansion.buttonIndex = 0
        cell.rightExpansion.fillOnTrigger = true
        let markImage = UIImage(named: "mark")
        //从右向左滑动保存书签
        cell.rightButtons = [MGSwipeButton(title: "", icon: markImage, backgroundColor: UIColor(red: 0.0, green: 207/250, blue: 107/250, alpha: 1.0), callback: { (sender: MGSwipeTableCell!) -> Bool in
            self.addOrDeleteBookMark(wikiContainer)
            self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
            print("Marked")
            return true
        })]
        return cell
    }

    // Override to support conditional editing of the table view.
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
//    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        let headerView = UIView()
//        headerView.backgroundColor = UIColor.grayColor()
//        
//        return headerView
//    }
//    
//    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        return "Wiki Nearby"
//    }
    
    //https://en.wikipedia.org/w/api.php?action=query&prop=coordinates%7Cpageimages%7Cpageterms%7Ciwlinks&colimit=50&piprop=thumbnail&pithumbsize=144&pilimit=50&wbptterms=description&generator=geosearch&ggscoord=37.786952%7C-122.399523&ggsradius=10000&ggslimit=50&format=json&iwprop=url
    
    //MARK: 获取json数据获取title
    private func fetchJSONData(newLoca: CLLocation) {
        Alamofire.request(.GET, baseWikiURL, parameters: [
            "action": "query",
            "format": "json",
            "prop": "coordinates|pageimages|pageterms|iwlinks",
            "colimit": "20",
            "piprop": "thumbnail",
            "pithumbsize": "144",
            "pilimit": "20",
            "wbptterms": "description",
            "generator": "geosearch",
            "ggscoord": "\(newLoca.coordinate.latitude)|\(newLoca.coordinate.longitude)",
            "ggsradius": "10000",
            "ggslimit": "20",
            "iwprop": "url"
            ])
            .responseJSON { response in
                
                if let jsonData = response.result.value {
                    let jsonObject = JSON(jsonData)
                    
                    let keyArray = Array(jsonObject["query"]["pages"].dictionaryValue.keys)
                    
                    for i in 0..<keyArray.count {
                        let wikiContainer = WikiContainer(title: " ", remoteURL: NSURL(string: "https://en.wikipedia.org")!, wikiContext: " ")
                        wikiContainer.title = jsonObject["query"]["pages"][keyArray[i]]["title"].string
                        //获取链接
                        let urlString = wikiContainer.title?.stringByReplacingOccurrencesOfString(" ", withString: "_")
                        wikiContainer.remoteURL = NSURL(string: self.urlPrefix + urlString!)
                        
                        //用来设置annotationView
                        self.wikiTitles.append(wikiContainer.title!)
                        
                        wikiContainer.latitude = jsonObject["query"]["pages"][keyArray[i]]["coordinates"][0]["lat"].double
                        wikiContainer.longitude = jsonObject["query"]["pages"][keyArray[i]]["coordinates"][0]["lon"].double
                        //获取距离
                        let wikiContainerLocation = CLLocation(latitude: wikiContainer.latitude!, longitude: wikiContainer.longitude!)
                        wikiContainer.distance = newLoca.distanceFromLocation(wikiContainerLocation)
                        //获取极短简介
                        if let shortDescription = jsonObject["query"]["pages"][keyArray[i]]["terms"]["description"][0].string {
                            wikiContainer.description = shortDescription
                        }else {
                            wikiContainer.description = " "
                        }
                        //获取wiki简介
                        wikiContainer.wikiContext = self.fetchSingleWikiContext(wikiContainer)
                        if let imageURLString = jsonObject["query"]["pages"][keyArray[i]]["thumbnail"]["source"].string{
                            self.downloadSinglePopularImage(imageURLString, wikiContainer: wikiContainer)
                        }
                        
                        self.wikiContainers.append(wikiContainer)
                        //设置annotation
                        let loc = CLLocationCoordinate2DMake(wikiContainer.latitude!, wikiContainer.longitude!)
                        let annotation = MyMKAnnotation(title: wikiContainer.title!, subtitle: wikiContainer.description!, coordinate: loc)
                        //设置annotationView
                        self.mapView(self.mapView, viewForAnnotation: annotation)
                        self.annotationArray.append(annotation)
                    }
                }
        }
    }
    
    //MARK: 得到维基词条简介
    private func fetchSingleWikiContext(wikiContainer: WikiContainer) -> String{
        Alamofire.request(.GET, self.baseWikiURL, parameters: [
            "action": "query",
            "format": "json",
            "prop": "extracts",
            "exlimit": "max",
            "explaintext": "",
            "exintro": "",
            "redirects": "",
            "titles": wikiContainer.title!
            ])
            .responseJSON { response in
                if let jsonData = response.result.value {
                    let jsonObject = JSON(jsonData)
                    let jSONPages = Array(jsonObject["query"]["pages"].dictionaryValue.keys)
                    //判断JSON中是否有简介内容
                    if let jContext = jsonObject["query"]["pages"][jSONPages[0]]["extract"].string {
                        wikiContainer.wikiContext = jContext
                    } else {
                        wikiContainer.wikiContext = " "
                    }
                }
        }
        return wikiContainer.wikiContext!
    }
    
    //MARK: 获取单张图片
    private func downloadSinglePopularImage(urlString: String, wikiContainer: WikiContainer) {
        Alamofire.request(.GET, urlString).response(completionHandler: { (_, _, data,_) -> Void in
            if let imageData = data {
                wikiContainer.image = UIImage(data: imageData, scale: 1.8)
            }
            self.tableView.reloadData()
            self.mapView.addAnnotations(self.annotationArray)
        })
    }
    
    //MARK: 设置annotationView
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        for i in 0..<wikiTitles.count {
            if annotation.title!! == wikiTitles[i]{
                let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "annotionView")
                //设置annotationView的image
                if wikiContainers[i].image != nil {
                    //处理图片大小和形状
                    let image = Toucan(image: wikiContainers[i].image!).resize(CGSize(width: 50, height: 50), fitMode: Toucan.Resize.FitMode.Scale).image
                    //设置其标签
                    annotationView.tag = i
                    annotationView.image = Toucan(image: image).maskWithEllipse(borderWidth: 1, borderColor: UIColor(red: 20/250, green:101/250, blue:180/250, alpha: 1.0)).image
                    annotationView.leftCalloutAccessoryView = UIImageView(image: wikiContainers[i].image!)
                    //设置rightCalloutAccessoryView
                    let rightButton = UIButton(type: .DetailDisclosure)
                    annotationView.rightCalloutAccessoryView = rightButton
                }
                //annotationView可以响应点击
                annotationView.canShowCallout = true
                return annotationView
            }
        }
        return nil
    }
    
    //MARK: 点击rightCalloutAccessoryView触发事件
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            let wikiContainer = self.wikiContainers[view.tag]
            self.performSegueWithIdentifier("annotationToWeb", sender: wikiContainer)
        }
    }
    
    //MARK: 传值
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "annotationToWeb" {
            
            let webViewController = segue.destinationViewController as! WebViewController
            webViewController.popularContainer = sender as? WikiContainer
            
        }
        if segue.identifier == "nearbyCellToWeb" {
            //设置要传值的行数
            if let row = tableView.indexPathForSelectedRow?.row {
                let popularContainer = wikiContainers[row]
                let webViewController = segue.destinationViewController as! WebViewController
                webViewController.popularContainer = popularContainer
            }
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
}
