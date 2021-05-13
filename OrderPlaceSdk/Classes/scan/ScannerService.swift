//
//  ScannerService.swift
//  testNewSdkSwift
//
//  Created by 陈培爵 on 2018/9/20.
//  Copyright © 2018年 PeiJueChen. All rights reserved.
//

import UIKit

class ScannerService: OrderPlaceService {
    private let scanVCId = "ScannerViewControllerNav"
    private var scanCallback: CallbackHandler? = nil;

    var options: [String: Any]!;

    override func initialize() {

    }

    init(_ options: [String: Any]) {
        super.init()
        self.options = options;
    }

    override func getServiceName() -> String {
        return "ScannerService"
    }

    override func handleMessage(method: String, body: NSDictionary, callback: CallbackHandler?) {
        switch method {
        case "scan":
            scanCallback = callback
            scan(callback: callback)
            return;
        default:
            break;
        }
    }

    func scan(callback: CallbackHandler?) {
        guard let NavController = OrderPlace.makeViewController(vcId: scanVCId) as? UINavigationController, let scanVC = NavController.topViewController as? ScannerViewController else { return }
        scanVC.options = options;
        scanVC.SVDelegate = self;
        NavController.modalPresentationStyle = .fullScreen
        vc.present(NavController, animated: true, completion: nil)
    }


}

extension ScannerService: ScannerViewDelegate {
    func scannerReulst(result: String) {
        JJPrint("result:\(result)")
        guard let callback = scanCallback else { return }
        var resultData = Dictionary<String, Any>()
        resultData["data"] = result;
        callback.success(response: resultData)
    }
}
