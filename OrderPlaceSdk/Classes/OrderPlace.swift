//
//  OrderPlace.swift
//  OrderPlaceSdk
//
//  Created by Peter Liu on 2/9/2018.
//

import Foundation
import UIKit
import AVFoundation


protocol OrderPlaceDelegate: AnyObject {

    func applicationOpenUrl(_ app: UIApplication, url: URL)
//    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?)
    //@objc optional func otherFunction() //optional
}


@objc public class OrderPlace: NSObject {

    static weak var OPDelegate: OrderPlaceDelegate?

    public static func makeViewController(vcId: String) -> UIViewController {

        let podBundle = Bundle(for: OrderPlace.self)

        JJPrint("podBundle", podBundle.bundlePath)

        let bundleURL = podBundle.url(forResource: "OrderPlaceSdkPrd", withExtension: "bundle")

        var bundle = podBundle

        if(bundleURL != nil) {
            bundle = Bundle(url: bundleURL!)!
        }

        let storyboard = UIStoryboard(name: "OrderPlaceStoryboard", bundle: bundle)

        JJPrint("storyboard:\(storyboard)")

        let controller = storyboard.instantiateViewController(withIdentifier: vcId);


        return controller;

    }

    @objc public static func openUrl(caller: UIViewController, url: String, options: [String: Any],closeCB: ((Any?) -> Void)? = nil) {
        
        if let target = options["target"] as? String,let Url = URL(string: url){
            let can = UIApplication.shared.canOpenURL(Url);
            if can && target == "_system" {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(Url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(Url)
                }
                return;
            }
            
        }
        
        JJPrint("open url")
        guard let controller = makeViewController(vcId: "OrderViewControllerNav") as? UINavigationController else { return }

        guard let orderVC = controller.topViewController as? OrderViewController else { return }

        orderVC.url = url;
        orderVC.options = options;
        
        orderVC.closeCB = closeCB;
        self.OPDelegate = orderVC
        
        if let follow = options["followiOS11"] as? Bool {
            if !follow {
                controller.modalPresentationStyle = .fullScreen
            }
        } else {
            controller.modalPresentationStyle = .fullScreen
        }
        
        if let push = options["presentationAnimate"] as? Bool, push == true {
            let aigensPresentationController = AigensPresentationController(presentedViewController: controller, presenting: caller)
            controller.transitioningDelegate = aigensPresentationController
            caller.present(controller, animated: true, completion: nil)
            return
        }

        caller.present(controller, animated: true, completion: nil)

    }

    @objc public static func openUrl(caller: UIViewController, url: String, options: [String: Any], services: Array<OrderPlaceService>,closeCB: ((Any?) -> Void)? = nil) {

        JJPrint("open url")
        if let target = options["target"] as? String,let Url = URL(string: url){
            let can = UIApplication.shared.canOpenURL(Url);
            if can && target == "_system" {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(Url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(Url)
                }
                return;
            }
            
        }

        guard let controller = makeViewController(vcId: "OrderViewControllerNav") as? UINavigationController else { return }

        guard let orderVC = controller.topViewController as? OrderViewController else { return }
        orderVC.url = url;
        orderVC.options = options;
        orderVC.extraServices = services;
        orderVC.closeCB = closeCB;
        self.OPDelegate = orderVC
        
        if let follow = options["followiOS11"] as? Bool {
            if !follow {
                controller.modalPresentationStyle = .fullScreen
            }
        } else {
            controller.modalPresentationStyle = .fullScreen
        }

        if let push = options["presentationAnimate"] as? Bool, push == true {
            let aigensPresentationController = AigensPresentationController(presentedViewController: controller, presenting: caller)
            controller.transitioningDelegate = aigensPresentationController
            caller.present(controller, animated: true, completion: nil)
            return
        }
        
        caller.present(controller, animated: true, completion: nil)
        

    }

    @objc public static func scan(caller: UIViewController, options: [String: Any],closeCB: ((Any?) -> Void)? = nil) {

        guard let controller = makeViewController(vcId: "ScannerViewControllerNav") as? UINavigationController else { return }

        guard let scanVC = controller.topViewController as? ScannerViewController else { return }
        scanVC.options = options;
        scanVC.closeCB = closeCB;
        self.OPDelegate = ScannerManager.shared;
        
        controller.modalPresentationStyle = .fullScreen;
        
        caller.present(controller, animated: true, completion: nil)

    }
    
    @objc public static func scanDecode(caller: UIViewController, options: [String: Any]?,closeCB: ((Any?) -> Void)? = nil) {
        let params : [String: Any] = options ?? [:];
        // params["onlyScan"] = true;
        
        // guard let controller = makeViewController(vcId: "ScannerViewControllerNav") as? UINavigationController else { return }
        // guard let scanVC = controller.topViewController as? ScannerViewController else { return }
        // scanVC.options = params;
        // scanVC.closeCB = closeCB;
        
        // controller.modalPresentationStyle = .fullScreen;
        
        // self.OPDelegate = ScannerManager.shared;
        // caller.present(controller, animated: true, completion: nil)

        guard let vc = LBXScanNativeViewController (success: { reslut in
            let result = ["decodeResult":reslut];
            closeCB?(result)
        }) else {return}
        if let language = params["language"] as? String {
            vc.language = language
        }
        vc.modalPresentationStyle = .fullScreen
        caller.present(vc, animated: true, completion: nil)
        
    }
    
    @objc public static func checkCameraPermission(callback: ((Bool) -> Void)? = nil) {
        
        if OrderPlace.isCameraPermissionGranted {
            callback?(true);
        } else {
            AVCaptureDevice.requestAccess(for: .video) { (granted) in
                if granted {
                    callback?(true);
                } else {
                   callback?(false)
                }
            }
        }
        
    }
    @objc public static func openSetting() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }
    private static var isCameraPermissionGranted: Bool {
        return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }

    @objc public static func application(_ app: UIApplication, open url: URL) {
        if let del = OPDelegate {
            del.applicationOpenUrl(app, url: url)
        }
    }
    
    @objc public static func getImagePathWithName(name:String,type:String) -> String? {
        let scan = Int(UIScreen.main.scale);
        var i = Bundle.main.path(forResource: name, ofType: type);
        if (i == nil) {
            let n = name + "@\(scan)x";
            i = Bundle.main.path(forResource: n, ofType: type);
        }
        return i;
    }

//    @objc public static func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {

//        if let dictArray = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [Dictionary<String, Any>] {
//            for dicts in dictArray {
//                if let dict = dicts["CFBundleURLName"] as? String, dict == "weixin", let arrayCFBundleURLSchemes = dicts["CFBundleURLSchemes"] as? [String], let weixinURLSchemes = arrayCFBundleURLSchemes.first {
//
//                    WXApi.registerApp(weixinURLSchemes, enableMTA: true)
//                    //print("weixinURLSchemes:\(weixinURLSchemes)")
//                    break;
//                }
//
//            }
//        }

//    }


}
