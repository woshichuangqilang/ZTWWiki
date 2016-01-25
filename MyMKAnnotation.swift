//
//  MyMKAnnotation.swift
//  ZTWWiki
//
//  Created by Wenslow on 16/1/23.
//  Copyright © 2016年 Wenslow. All rights reserved.
//

import UIKit
import MapKit

class MyMKAnnotation: MKPointAnnotation {
    init(title: String, subtitle: String, coordinate: CLLocationCoordinate2D) {
        super.init()
        
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        
    }
}
