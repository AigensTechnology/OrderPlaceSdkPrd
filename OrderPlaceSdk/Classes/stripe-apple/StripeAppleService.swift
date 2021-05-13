//
//  StripeAppleService.swift
//  OrderPlaceSdk_Example
//
//  Created by 陈培爵 on 2019/1/29.
//  Copyright © 2019年 CocoaPods. All rights reserved.
//

import UIKit

@objc public protocol StripeAppleDelegate: AnyObject {
    func stripeAppleInitialize()
    func stripeAppleMakePaymentRequest(_ body: NSDictionary, _ callback: CallbackHandler?)
    func stripeAppleCompleteLastTransaction(_ body: NSDictionary, _ callback: CallbackHandler?)
    var options: [String: Any]? { get set }
    var baseViewController:UIViewController? { get set }
}

class StripeAppleService: OrderPlaceService {
    
    var options: [String: Any]?
    
    
    // We don't need weak here, because we are the delegate of run time get.
    var stripeAppleDelegate: StripeAppleDelegate? = nil
    
    init(_ options: [String: Any], _ stripeAppleDelegate:StripeAppleDelegate? = nil ) {
        super.init();
        self.stripeAppleDelegate = stripeAppleDelegate;
        self.options = options;
        self.stripeAppleDelegate?.options = options;
        
    }
    
    override func initialize() {
       stripeAppleDelegate?.stripeAppleInitialize()
    }
    override func getServiceName() -> String {
        return "StripeAppleService";
    }
    
    override func handleMessage(method: String, body: NSDictionary, callback: CallbackHandler?) {
        switch method {
        case "makePaymentRequest":
            self.stripeAppleDelegate?.baseViewController = self.vc;
            stripeAppleDelegate?.stripeAppleMakePaymentRequest(body, callback)
            break;
        case "completeLastTransaction":
            self.stripeAppleDelegate?.baseViewController = self.vc;
            stripeAppleDelegate?.stripeAppleCompleteLastTransaction(body, callback)
            break;
        default:
            break;
        }
    }
    
}
