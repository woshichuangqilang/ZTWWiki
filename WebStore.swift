//
//  WebStore.swift
//  ZTWWiki
//
//  Created by Wenslow on 16/1/17.
//  Copyright © 2016年 Wenslow. All rights reserved.
//

import UIKit
import CoreData


class WebStore {

    let baseWikiURL = "https://en.wikipedia.org/w/api.php?"
    let imageStore = ImageStore()
    let coreDataStack = CoreDataStack(modelName: "ZTWWiki")
    let fetchRequest = NSFetchRequest()
    
    //MARK: 得到图片
    func fetchSingleImage(title: String, imageKey: String) -> UIImage?{
        //title为空，则不获取图片
        if title != " " {
            let components = NSURLComponents(string: baseWikiURL)
            var queryItems = [NSURLQueryItem]()
            let baseParams = [
                "action": "query",
                "format": "json",
                "prop": "pageimages",
                "pithumbsize": "144",
            ]
            for (key, value) in baseParams {
                let item = NSURLQueryItem(name: key, value: value)
                queryItems.append(item)
            }
            let queryTitleItem = NSURLQueryItem(name: "titles", value: title)
            queryItems.append(queryTitleItem)
            components?.queryItems = queryItems
            return self.analysisSingleImageJSONData((components?.URL)!, imageKey: imageKey)
        }
        return nil
    }
    
    //MARK: 解析PopularJSON数据，并得到图片
    private func analysisSingleImageJSONData(url: NSURL, imageKey: String) -> UIImage?{
        
        if let jsonData = NSData(contentsOfURL: url) {
            
            let jsonObject = JSON(data: jsonData)
            let jSONPages = Array(jsonObject["query"]["pages"].dictionaryValue.keys)
            //图片下载成功
            if let jImage = jsonObject["query"]["pages"][jSONPages[0]]["thumbnail"]["source"].string,
                let imageData = NSData(contentsOfURL: NSURL(string: jImage)!) {
                let image = UIImage(data: imageData)
                self.imageStore.setImage(image!, forKey: imageKey)
                return image
            }
        }
        return nil
    }
    
    
    //MARK: 得到维基词条简介
    func fetchSingleWikiContext(title: String) -> String{
        //判断title是否为空
        if title != " " {
            let components = NSURLComponents(string: baseWikiURL)
            var queryItems = [NSURLQueryItem]()
            let baseParams = [
                "action": "query",
                "format": "json",
                "prop": "extracts",
                "exlimit": "max",
                "explaintext": "",
                "exintro": "",
                "redirects": ""
            ]
            for (key, value) in baseParams {
                let item = NSURLQueryItem(name: key, value: value)
                queryItems.append(item)
            }
            let queryTitleItem = NSURLQueryItem(name: "titles", value: title)
            queryItems.append(queryTitleItem)
            components?.queryItems = queryItems
            return self.analysisSingleContextJSONData(components!.URL!)
        }
        return " "
    }
    
    //MARK: 解析PopularJSON数据，并得到简介
    private func analysisSingleContextJSONData(url: NSURL) -> String{
        //简介是否成功获取
        if let jsonData = NSData(contentsOfURL: url) {
            
            let jsonObject = JSON(data: jsonData)
            let jSONPages = Array(jsonObject["query"]["pages"].dictionaryValue.keys)
            //判断JSON中是否有简介内容
            if let jContext = jsonObject["query"]["pages"][jSONPages[0]]["extract"].string {
                return jContext
            }
        }
        return " "
    }
    
    //MARK: 保存历史数据，并删除大于50的数据
    func storeHistory(tempWikiContainer: WikiContainer){
        self.saveWikiContainers(tempWikiContainer, entityName: "HistoryWikiContainer")
    }
    
    //获得书签的title数组
    func fetchBookMarkTitles() ->[String]{
        
        var titles = [String]()
        //context
        let entityDescription = NSEntityDescription.entityForName("BookMarkWikiContainer", inManagedObjectContext: coreDataStack.mainQueueContext)
        fetchRequest.entity = entityDescription
        do {
            let result = try coreDataStack.mainQueueContext.executeFetchRequest(fetchRequest)
            
            if result.count > 0 {
                let containers = result as! [NSManagedObject]
                for i in 0..<containers.count {
                    let title = containers[i].valueForKey("title") as! String
                    titles.append(title)
                }
            }
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        return titles
    }
    
    //MARK: 保存书签
    func saveBookMark(tempWikiContainer: WikiContainer, var titles: [String]) ->[String]{
        
        self.saveWikiContainers(tempWikiContainer, entityName: "BookMarkWikiContainer")
        titles.append(tempWikiContainer.title!)
        print("Save Book Mark \(tempWikiContainer.title!) Success")
        return titles
    }
    
    //MARK: 删除书签
    func deleteBookMark(title: String, var titles: [String]) -> [String] {
        
        let entityDescription = NSEntityDescription.entityForName("BookMarkWikiContainer", inManagedObjectContext: coreDataStack.mainQueueContext)
        fetchRequest.entity = entityDescription
        //获取该词条在BookMarkWikiContainer中的index，并删除
        for i in 0..<titles.count {
            if title == titles[i] {
                do {
                    
                    let result = try coreDataStack.mainQueueContext.executeFetchRequest(fetchRequest)
                    let container = result[i] as! NSManagedObject
                    print("delete \(container.valueForKey("title")) Success")
                    coreDataStack.mainQueueContext.deleteObject(container)
                    try coreDataStack.mainQueueContext.save()
                    titles.removeAtIndex(i)
                    
                } catch {
                    let fetchError = error as NSError
                    print(fetchError)
                }
                break
            }
        }
        return titles
    }
    
    //MARK: 保存数据
    private func saveWikiContainers(tempWikiContainer: WikiContainer, entityName:String) {
        let entityDescription = NSEntityDescription.entityForName(entityName, inManagedObjectContext: coreDataStack.mainQueueContext)
        fetchRequest.entity = entityDescription
        let newHistoryWikiContainer = NSManagedObject(entity: entityDescription!, insertIntoManagedObjectContext: coreDataStack.mainQueueContext)
        //设值
        newHistoryWikiContainer.setValue(tempWikiContainer.title, forKey: "title")
        newHistoryWikiContainer.setValue(tempWikiContainer.remoteURL, forKey: "remoteURL")
        newHistoryWikiContainer.setValue(tempWikiContainer.wikiContext, forKey: "wikiContext")
        newHistoryWikiContainer.setValue(tempWikiContainer.imageURL, forKey: "imageURL")
        newHistoryWikiContainer.setValue(tempWikiContainer.imageKey, forKey: "imageKey")
        do {
            try newHistoryWikiContainer.managedObjectContext?.save()
            try coreDataStack.mainQueueContext.save()
            print("Save \(tempWikiContainer.title) Success")
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        
        //当历史条目大于50时，删除最早的历史条目
        if entityName == "HistoryWikiContainer" {
            do {
                let result = try coreDataStack.mainQueueContext.executeFetchRequest(fetchRequest)
                
                if result.count > 50 {
                    let container = result[0] as! NSManagedObject
                    //相对应的图片也要删除
                    let imageKey = container.valueForKey("imageKey") as! String
                    if imageStore.imageForKey(imageKey) != nil {
                        imageStore.deleteImageForKey(imageKey)
                    }
                    print("delete \(container.valueForKey("title"))")
                    coreDataStack.mainQueueContext.deleteObject(container)
                    try coreDataStack.mainQueueContext.save()
                }
            } catch {
                let fetchError = error as NSError
                print(fetchError)
            }
        }
    }
}

