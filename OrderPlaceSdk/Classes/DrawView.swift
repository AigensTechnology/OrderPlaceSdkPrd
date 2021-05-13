//
//  DrawView.swift
//  OrderPlaceSdk_Example
//
//  Created by 陈培爵 on 2019/1/18.
//  Copyright © 2019年 CocoaPods. All rights reserved.
//

import UIKit

class DrawView: UIView {

    var blankFramework:CGRect? = nil;
    let defaultBlankFramework = CGRect(x: 100, y: 200, width: 200, height: 200);
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        //设置 背景为clear
        backgroundColor = UIColor.clear
        isOpaque = false
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        UIColor(white: 0, alpha: 0.5).setFill()
        
        //半透明区域
        UIRectFill(rect)
        
        //透明的区域
        var holeRection = defaultBlankFramework;
        if let blankF = blankFramework {
            holeRection = blankF;
        }
        
        /** union: 并集
         CGRect CGRectUnion(CGRect r1, CGRect r2)
         返回并集部分rect
         */
        
        /** Intersection: 交集
         CGRect CGRectIntersection(CGRect r1, CGRect r2)
         返回交集部分rect
         */
        let holeiInterSection: CGRect = holeRection.intersection(rect)
        UIColor.clear.setFill()
        
        //CGContextClearRect(ctx, <#CGRect rect#>)
        //绘制
        //CGContextDrawPath(ctx, kCGPathFillStroke);
        UIRectFill(holeiInterSection)
    }
 

}
