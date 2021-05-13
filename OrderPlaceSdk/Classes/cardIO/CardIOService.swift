//
//  CardIOService.swift
//  OrderPlaceSdk_Example
//
//  Created by 陈培爵 on 2019/1/22.
//  Copyright © 2019年 CocoaPods. All rights reserved.
//

import UIKit

@objc public protocol cardIODelegate:AnyObject {
    func scan(body: NSDictionary, callback: CallbackHandler?);
    func initialize();
}

class CardIOService: OrderPlaceService {
    
    var cardIODelegate : cardIODelegate? = nil;
    override func getServiceName() -> String {
        return "CardIOService";
    }
    override func initialize() {
        cardIODelegate?.initialize()
    }
    
    init(_ cardIODelegate: cardIODelegate? = nil) {
        self.cardIODelegate = cardIODelegate;
    }
    override func handleMessage(method: String, body: NSDictionary, callback: CallbackHandler?) {
        switch method {
        case "scan":
            scan(body: body, callback: callback);
            break;
        default:
            break;
        }
    }
    private func scan(body: NSDictionary, callback: CallbackHandler?) {
        cardIODelegate?.scan(body: body, callback: callback);
    }
}
