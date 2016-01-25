//
//  WikiContainer.swift
//  ZTWWiki
//
//  Created by Wenslow on 16/1/14.
//  Copyright © 2016年 Wenslow. All rights reserved.
//

import UIKit
import CoreLocation

class WikiContainer {
    
    var title: String?
    var remoteURL: NSURL?
    var wikiContext: String?
    var imageURL: NSURL?
    var image: UIImage?
    var imageKey: String
    var digit: String?
    var longitude: CLLocationDegrees?
    var latitude: CLLocationDegrees?
    var description: String?
    var distance: CLLocationDistance?
    
    init(title: String, remoteURL: NSURL, wikiContext: String) {
        self.title = title
        self.remoteURL = remoteURL
        self.wikiContext = wikiContext
        self.imageKey = NSUUID().UUIDString
        
    }
}