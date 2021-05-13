//
//  ScannerManager.swift
//  OrderPlaceSdk_Example
//
//  Created by 陈培爵 on 2018/12/13.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import UIKit

protocol ScannerDelegate: AnyObject {
    func scannerApplicationOpenUrl(_ app: UIApplication, url: URL)
}

private let scannerManager = ScannerManager();
class ScannerManager: NSObject {
    weak var scannerDelegate: ScannerDelegate?
    static var shared: ScannerManager {
        return scannerManager;
    }
}

extension ScannerManager: OrderPlaceDelegate {
    func applicationOpenUrl(_ app: UIApplication, url: URL) {
        if let sDelegate = scannerDelegate {
            sDelegate.scannerApplicationOpenUrl(app, url: url)
        }
    }
}
