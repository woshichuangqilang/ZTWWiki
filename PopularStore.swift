//
//  PopularStore.swift
//  ZTWWiki
//
//  Created by Wenslow on 16/1/14.
//  Copyright © 2016年 Wenslow. All rights reserved.
//

import UIKit
import CoreData

class PopularStore {
    let imageStore = ImageStore()
    let coreDataStack = CoreDataStack(modelName: "ZTWWiki")
    let fetchRequest = NSFetchRequest()
    
    //MARK: 保存书签
    func saveBookMark(tempWikiContainer: WikiContainer, var titles: [String]) ->[String]{
        
        self.saveWikiContainers(tempWikiContainer, entityName: "BookMarkWikiContainer")
        titles.append(tempWikiContainer.title!)
        print("Save Book Mark \(tempWikiContainer.title!) Success")
        return titles
    }
    
    //MARK: 保存数据
    private func saveWikiContainers(tempWikiContainer: WikiContainer, entityName:String) {
        let entityDescription = NSEntityDescription.entityForName(entityName, inManagedObjectContext: coreDataStack.mainQueueContext)
        //fetchRequest.entity = entityDescription
        let newHistoryWikiContainer = NSManagedObject(entity: entityDescription!, insertIntoManagedObjectContext: coreDataStack.mainQueueContext)
        //设值
        newHistoryWikiContainer.setValue(tempWikiContainer.title, forKey: "title")
        newHistoryWikiContainer.setValue(tempWikiContainer.remoteURL, forKey: "remoteURL")
        newHistoryWikiContainer.setValue(tempWikiContainer.wikiContext, forKey: "wikiContext")
        newHistoryWikiContainer.setValue(tempWikiContainer.imageURL, forKey: "imageURL")
        newHistoryWikiContainer.setValue(tempWikiContainer.imageKey, forKey: "imageKey")
        if tempWikiContainer.image != nil {
            self.imageStore.setImage(tempWikiContainer.image!, forKey: tempWikiContainer.imageKey)
        }
        do {
            try newHistoryWikiContainer.managedObjectContext?.save()
            try coreDataStack.mainQueueContext.save()
            print("Save \(tempWikiContainer.title) Success")
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
    }
}