//
//  ConfigService.swift
//  OrderPlaceSdk
//
//  Created by Peter Liu on 5/9/2018.
//

import Foundation
import UIKit
import WebKit

class ConfigService: OrderPlaceService {

    var options: [String: Any]!;

    var closeCB: ((Any?) -> Void)? = nil

    override func getServiceName() -> String {
        return "ConfigService";
    }

    var clickedExit: (() -> ())? = nil

    override func handleMessage(method: String, body: NSDictionary, callback: CallbackHandler?) {

        JJPrint("ConfigService2:\(method) :\(body)")

        switch method {
        case "back":
            back(body: body, callback: callback);
            break;
        case "canOpenUrl":
            canOpenUrl(body: body, callback: callback);
            break;
        case "getPreference":
            getPreference(pref: "default", name: body["name"] as! String, callback: callback);
            break;
        case "getConfig":
            getConfig(callback: callback);
            break;
        case "getParams":
            getParams(callback: callback);
            break;
        case "putPreference":
            putPreference(pref: "default", name: body["name"] as! String, value: body["value"] as Any, callback: callback);
            break;
        case "closeKeyboard":
            if let vc = self.vc as? OrderViewController {
                vc.closeKeyboard();
                callback?.success(response: body)
            }
            break;
        default:
            break;

        }


    }

    func canOpenUrl(body: NSDictionary, callback: CallbackHandler?) {
        if let url = body.value(forKey: "url") as? String,let URL = URL(string: url) {
            let can = UIApplication.shared.canOpenURL(URL)
            let dict = ["result":can];
            if let open = body.value(forKey: "openUrl") as? Bool {
                if open && can {
                    UIApplication.shared.openURL(URL);
                }
            }
            callback?.success(response: dict)
        }
    }

    func back(body: NSDictionary, callback: CallbackHandler?) {
        vc.navigationController?.dismiss(animated: true)
        if clickedExit != nil {
            clickedExit!()
        }
        if closeCB != nil {
            closeCB!(body);
        }
        callback?.success(response: body)
    }

    func getPreference(pref: String, name: String, callback: CallbackHandler?) {

        let value = UserDefaults.standard.object(forKey: name)

        JJPrint("getPref:\(name)--:\(value as Any)")


        callback?.success(response: value as Any)


    }

    func getParams(callback: CallbackHandler?) {

        let value = self.options;

        JJPrint("getParams2:\(value as Any)")

        callback?.success(response: value as Any)


    }

    func getConfig(callback: CallbackHandler?) {

        let value = [String: String]()
        callback?.success(response: value)


    }

    func putPreference(pref: String, name: String, value: Any, callback: CallbackHandler?) {

        UserDefaults.standard.set(value, forKey: name)
        JJPrint("putPreference:\(name)--:\(value)")

    }


}

