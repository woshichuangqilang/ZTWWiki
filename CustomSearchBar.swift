//
//  CustomSearchBar.swift
//  ZTWWiki
//
//  Created by Wenslow on 16/1/21.
//  Copyright © 2016年 Wenslow. All rights reserved.
//

import UIKit

class CustomSearchBar: UISearchBar {

    var preferredFont: UIFont!
    var preferredTextColor: UIColor!
    
    init(frame: CGRect, font: UIFont, textColor: UIColor) {
        super.init(frame: frame)
        self.frame = frame
        preferredFont = font
        preferredTextColor = textColor
        searchBarStyle = UISearchBarStyle.Prominent
        translucent = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //search bar has a UIView view as a subview
    //and the search field is UITextField
    func indexOfSearchFieldInSubviews() ->Int! {
        var index: Int!
        let searchBarView = subviews[0]
        for i in 0..<searchBarView.subviews.count {
            if searchBarView.subviews[i].isKindOfClass(UITextField){
                index = i
                break
            }
        }
        return index
    }
    
    override func drawRect(rect: CGRect) {
        if let index = indexOfSearchFieldInSubviews() {
            //设置search field
            let searchField: UITextField = (subviews[0]).subviews[index] as! UITextField
            searchField.frame = CGRectMake(5.0, 5.0, frame.width - 10, frame.height - 10)
            searchField.font = preferredFont
            searchField.textColor = preferredTextColor
            searchField.backgroundColor = barTintColor
        }
        let startPoint = CGPointMake(0.0, frame.height)
        let endPoint = CGPointMake(frame.width, frame.height)
        let path = UIBezierPath()
        path.moveToPoint(startPoint)
        path.addLineToPoint(endPoint)
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.CGPath
        shapeLayer.strokeColor = preferredTextColor.CGColor
        shapeLayer.lineWidth = 2.5
        layer.addSublayer(shapeLayer)
        super.drawRect(rect)
    }
}
