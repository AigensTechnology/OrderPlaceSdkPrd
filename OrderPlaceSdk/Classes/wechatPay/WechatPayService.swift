//
//  WechatPayService.swift
//  OrderPlaceSdk_Example
//
//  Created by 陈培爵 on 2018/11/19.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import UIKit

@objc public protocol WeChatPayDelegate: AnyObject {
    func wechatPayOrder(body: NSDictionary, callback: CallbackHandler?)
    func wechatGetVersion(callback: CallbackHandler?)
    func isInstalled(callback: CallbackHandler?)
    func wechatApplicationOpenUrl(_ app: UIApplication, url: URL)
    func wechatApplication(_ app: UIApplication, continue userActivity: NSUserActivity)
}

class WechatPayService: OrderPlaceService {
    static public var SERVICE_NAME: String = "WeChatPayService"

    var payResultCallback: CallbackHandler? = nil
    // We don't need weak here, because we are the delegate of run time get.
    var weChatPayDelegate: WeChatPayDelegate? = nil

    var options: [String: Any]?
    init(_ options: [String: Any], _ weChatPayDelegate: WeChatPayDelegate? = nil) {
        self.options = options;
        self.weChatPayDelegate = weChatPayDelegate
    }

    override func getServiceName() -> String {
        
        if let features = self.options?["features"] as? String {
            let fs = features.split(separator: ",");
            if (fs.contains("wechatpayhk")) {
                WechatPayService.SERVICE_NAME = "WeChatPayHKService";
            }
        }
        
        return WechatPayService.SERVICE_NAME
    }

    override func handleMessage(method: String, body: NSDictionary, callback: CallbackHandler?) {
        switch method {
        case "requestPay":
            payResultCallback = callback
            payOrder(body: body, callback: callback)
            break;
        case "getWeChatSdkVersion":
            getVersion(callback: callback)
            break;
        case "registerApp":
            registerApp(body: body, callback: callback)
            break;
        case "isWXAppInstalled":
            isWXAppInstalled(callback)
            break;
        default:
            break;
        }
    }
    
    private func isWXAppInstalled(_ callback: CallbackHandler?) {
        if let del = weChatPayDelegate {
            del.isInstalled(callback: callback)
        }
    }
    private func registerApp(body: NSDictionary, callback: CallbackHandler?) {
        debugPrint("registerApp body:\(body)")
    }

    private func getVersion(callback: CallbackHandler?) {

        if let del = weChatPayDelegate {
            del.wechatGetVersion(callback: callback)
        }

//        if let version = WXApi.getVersion() {
//            let dict = ["wechatSdkVersion": version]
//            debugPrint("wechatSdkVersion:\(version)")
//            callback?.success(response: dict)
//        }

    }

    private func payOrder(body: NSDictionary, callback: CallbackHandler?) {
        debugPrint("wechat body:\(body)")
        if let del = weChatPayDelegate {
            del.wechatPayOrder(body: body, callback: callback)
        }
//        if !WXApi.isWXAppInstalled() {
//            self.showAlert(message: "Please install WeChat first.")
//            return
//        }

        /* test
        let urlString = "https://wxpay.wxutil.com/pub_v2/app/app_pay.php?plat=ios"
        let request = URLRequest(url: URL(string: urlString)!)
        NSURLConnection.sendAsynchronousRequest(request, queue: OperationQueue.main) { (response, data, error) in
            if error == nil && data != nil {
                let dictT = try? JSONSerialization.jsonObject(with: data!, options: .mutableLeaves)
                print("dictT:\(dictT)")
                if let dict = try? JSONSerialization.jsonObject(with: data!, options: .mutableLeaves) as? NSDictionary, dict != nil {
                    if let partnerId = dict!.value(forKey: "partnerid") as? String, let prepayId = dict!.value(forKey: "prepayid") as? String, let nonceStr = dict!.value(forKey: "noncestr") as? String, let timeStamp = dict!.value(forKey: "timestamp") as? UInt32, let package = dict!.value(forKey: "package") as? String, let sign = dict!.value(forKey: "sign") as? String {
                        let req = PayReq()
                        req.partnerId = partnerId
                        req.prepayId = prepayId
                        req.nonceStr = nonceStr
                        req.timeStamp = timeStamp
                        req.package = package
                        req.sign = sign
                        WXApi.send(req)
                    }
                }
            }
        }
    */

//        if let partnerId = body.value(forKey: "partnerId") as? String, let prepayId = body.value(forKey: "prepayId") as? String, let nonceStr = body.value(forKey: "nonceStr") as? String, let timeStamp = body.value(forKey: "timeStamp") as? UInt32, let package = body.value(forKey: "packageValue") as? String, let sign = body.value(forKey: "sign") as? String {
//            let req = PayReq()
//            req.partnerId = partnerId
//            req.prepayId = prepayId
//            req.nonceStr = nonceStr
//            req.timeStamp = timeStamp
//            req.package = package
//            req.sign = sign
//            WXApi.send(req)
//        } else {
//            debugPrint("params format error")
//        }

    }

    private func showAlert(message: String, handler: ((UIAlertAction) -> Swift.Void)? = nil) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: handler))
        self.vc.present(alertController, animated: true, completion: nil)
    }
}
