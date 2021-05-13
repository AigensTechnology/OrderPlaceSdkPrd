//
//  AlipayService.swift
//  testNewSdkSwift
//
//  Created by 陈培爵 on 2018/9/11.
//  Copyright © 2018年 PeiJueChen. All rights reserved.
//

import UIKit
import WebKit
@objc public protocol AlipayDelegate: AnyObject {
    func AlipayOrder(body: NSDictionary, callback: CallbackHandler?)
    func AlipayGetVersion(callback: CallbackHandler?)
    func AlipayApplicationOpenUrl(_ app: UIApplication, url: URL)
    func AlipayFetchOrderInfo(url: String, alipayScheme: String) -> Bool
    var AliapyWebView: WKWebView? { get set }
}

class AlipayService: OrderPlaceService {
    
    // We don't need weak here, because we are the delegate of run time get.
    var alipayDelegate: AlipayDelegate? = nil
    
    static public var SERVICE_NAME: String = "AlipayService"
    /// default alipaySchemes123
    static public var appScheme: String = "alipaySchemes123"
    
    var payResultCallback: CallbackHandler? = nil
    
    var options: [String: Any]?
    
    init(_ options: [String: Any]) {
        super.init()
        self.options = options;
        if let appScheme = self.options!["alipayScheme"] as? String {
            AlipayService.appScheme = appScheme
        }
    }
    
    override func initialize() {
        
    }
    
    override func getServiceName() -> String {
        if let features = self.options?["features"] as? String {
            let fs = features.split(separator: ",");
            if (fs.contains("alipayhk")) {
                AlipayService.SERVICE_NAME = "AlipayHKService";
            }
        }
        return AlipayService.SERVICE_NAME;
    }
    
    // body: params
    override func handleMessage(method: String, body: NSDictionary, callback: CallbackHandler?) {
        switch method {
        case "requestPay":
            payResultCallback = callback
            print("body:\(body)")
            if let alipayScheme = body.value(forKey: "alipayScheme") as? String {
                AlipayService.appScheme = alipayScheme;
            }
            payOrder(body: body, callback: callback)
            break;
        case "getAlipaySdkVersion":
            getVersion(callback: callback)
            break;
        default:
            break;
        }
    }
    
    private func getVersion(callback: CallbackHandler?) {
        
        if let del = alipayDelegate {
            del.AlipayGetVersion(callback: callback)
        }
        
        //        if let version = AlipaySDK.currentVersion(AlipaySDK())() {
        //            let dict = ["alipaySdkVersion": version]
        //            callback?.success(response: dict)
        //        }
        
    }
    
    // wap pay
    private func payOrder(body: NSDictionary, callback: CallbackHandler?) {
        debugPrint(" alipay body:\(body)")
        
        if let del = alipayDelegate {
            del.AlipayOrder(body: body, callback: callback)
        }
        
        
        // call back 是wap 支付的结果, 钱包支付的结果要在app delegate 中写
        //        AlipaySDK.defaultService().payOrder(body.value(forKey: "orderStringAlipay") as? String ?? "", fromScheme: AlipayService.appScheme) { (result) in
        //            print("payOrder result:\(result)")
        //            callback?.success(response: result)
        //
        //        }
    }
}
