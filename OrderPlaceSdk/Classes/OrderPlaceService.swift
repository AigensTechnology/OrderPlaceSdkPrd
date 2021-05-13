//
//  OrderPlaceService.swift
//  OrderPlaceSdk
//
//  Created by Peter Liu on 5/9/2018.
//

import Foundation
import WebKit

open class OrderPlaceService: NSObject {
    
    public var vc: UIViewController!;
    public var params: Any?;
    
    open func getServiceName() -> String {
        preconditionFailure("This method getServiceName must be overridden")
        //return "";
    }
    
    open func initialize() {
        
        
    }
    
    open func handleMessage(method: String, body: NSDictionary, callback: CallbackHandler?) {
        preconditionFailure("This method handleMessage must be overridden")
        //return;
    }
    
    func generateResultObject(_ value: Any) -> [String: Any] {
        return ["result": value]
    }
    
    func showAlert(_ title: String?, _ message: String) {
        guard vc != nil else { return }
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            
        }))
        vc.present(alertController, animated: true, completion: nil)
    }
}
