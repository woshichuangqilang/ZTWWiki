//
//  HistoryAndBookMarkStore.swift
//  ZTWWiki
//
//  Created by Wenslow on 16/1/19.
//  Copyright © 2016年 Wenslow. All rights reserved.
//

import UIKit
import CoreData

class HistoryAndBookMarkStore {
    
    let imageStore = ImageStore()
    let coreDataStack = CoreDataStack(modelName: "ZTWWiki")
    let fetchRequest = NSFetchRequest()
    
    //MARK: 读取数据
    func loadData(entityName: String) -> [WikiContainer] {
        
        var wikiContainers = [WikiContainer]()
        let entityDescription = NSEntityDescription.entityForName(entityName, inManagedObjectContext: self.coreDataStack.mainQueueContext)
        fetchRequest.entity = entityDescription
        do {
            let result = try self.coreDataStack.mainQueueContext.executeFetchRequest(fetchRequest)
            
            if result.count > 0 {
                
                for i in 1...result.count {
                    
                    let num = result.count - i
                    let container = result[num] as! NSManagedObject
                    let wikiContainer = WikiContainer(title: " ", remoteURL: NSURL(), wikiContext: " ")
                    
                    if let title = container.valueForKey("title"),
                        wikiContext = container.valueForKey("wikiContext"),
                        remoteURL = container.valueForKey("remoteURL"),
                        imageKey = container.valueForKey("imageKey"){
                            wikiContainer.title = title as? String
                            wikiContainer.wikiContext = wikiContext as? String
                            wikiContainer.remoteURL = remoteURL as? NSURL
                            wikiContainer.imageKey = (imageKey as? String)!
                            if let image = imageStore.imageForKey(wikiContainer.imageKey) {
                                let imageData = UIImageJPEGRepresentation(image, 1.0)
                                wikiContainer.image = UIImage(data: imageData!, scale: 1.8)
                            }   
                    }
                    wikiContainers.append(wikiContainer)
                }
            }
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        return wikiContainers
    }
    
    //MARK: 删除单项
    func deleteSingleItem(indexPath_Row: Int, entityName: String) {
        
        let entityDescription = NSEntityDescription.entityForName(entityName, inManagedObjectContext: coreDataStack.mainQueueContext)
        fetchRequest.entity = entityDescription
        
        do {
            let result = try coreDataStack.mainQueueContext.executeFetchRequest(fetchRequest)
            let i = result.count - indexPath_Row
            let container = result[i] as! NSManagedObject
            
            print("delete \(container.valueForKey("title")) Success")
            coreDataStack.mainQueueContext.deleteObject(container)
            try coreDataStack.mainQueueContext.save()
                    
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
    }
    
    //MARK: 删除所有数据
    func deleteAllItems (entityName: String) {
        
        let entityDescription = NSEntityDescription.entityForName(entityName, inManagedObjectContext: coreDataStack.mainQueueContext)
        fetchRequest.entity = entityDescription
        
        do {
            let result = try coreDataStack.mainQueueContext.executeFetchRequest(fetchRequest)
            for item in result {
                coreDataStack.mainQueueContext.deleteObject(item as! NSManagedObject)
            }
            print("delete container Success")
            try coreDataStack.mainQueueContext.save()
            
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
    }

}