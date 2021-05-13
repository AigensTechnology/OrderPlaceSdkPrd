//
//  WKScriptMsgHandler.swift
//  OrderPlaceSdk_Example
//
//  Created by 陈培爵 on 2018/11/20.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import UIKit
import WebKit

class WKScriptMsgHandler: NSObject, WKScriptMessageHandler {
    
    weak var scriptDelegate: WKScriptMessageHandler?
    
    init(scriptDelegate: WKScriptMessageHandler) {
        self.scriptDelegate = scriptDelegate
    }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let delegate = scriptDelegate {
            delegate.userContentController(userContentController, didReceive: message)
        }
    }
    
    
}
