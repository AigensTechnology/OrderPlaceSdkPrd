//
//  CallbackHandler.swift
//  OrderPlaceSdk
//
//  Created by Peter Liu on 5/9/2018.
//

import Foundation
import UIKit
import WebKit

@objc public class CallbackHandler: NSObject {
    
    @objc public var cc: WKUserContentController!;
    @objc public var callback: String!;
    @objc public var webView: WKWebView!;
    
    
    @objc public func success(response: Any) {
        
        JJPrint("response:\(response)")
        if(callback == nil) {
            return;
        }
        
        var str: String = "null";
        
        
        do {
            if JSONSerialization.isValidJSONObject(response) {
                let data = try JSONSerialization.data(withJSONObject: response)
                if let s = String(data: data, encoding: String.Encoding.utf8) {
                    str = s;
                }
            }
        } catch {
            JJPrint("json serialization error")
        }
        
        let scriptSource = callback + "('" + str + "')"
        
        JJPrint("callback", callback)
        JJPrint("script", scriptSource)
        
        self.webView.evaluateJavaScript(scriptSource)
    }
    
}

