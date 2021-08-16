//
//  ScannerViewController.swift
//  OrderPlaceSdk
//
//  Created by Peter Liu on 7/9/2018.
//

import Foundation
import AVFoundation
import UIKit

protocol ScannerViewDelegate: AnyObject {

    func scannerReulst(result: String)
    //@objc optional func clicked() //optional
}

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var SVDelegate: ScannerViewDelegate?
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var options: [String: Any]!

    var closeCB: ((Any?) -> Void)? = nil


    var url: String!

    private var minView: UIView!
    private var reticleView: UIView!

    private var buildReticleColor = UIColor(red: 0.86, green: 0.56, blue: 0.43, alpha: 0.50);
    private var minViewColor = UIColor(red: 0.96, green: 0.46, blue: 0.10, alpha: 1.00);

//    private let RETICLE_SIZE: CGFloat = 500.0;
    private let RETICLE_OFFSET: CGFloat = 60.0;
    private let RETICLE_ALPHA: CGFloat = 0.4;
    private let RETICLE_WIDTH: CGFloat = 2.0;
    private let MINVIEW_WIDTH: CGFloat = 2.0;
    private let SCREEN_HEIGHT = UIScreen.main.bounds.height;
    private let SCREEN_WIDTH = UIScreen.main.bounds.width;
    private var minAxis: CGFloat = 0;
    private var onlyScan = false;
    var lang = "en";
    override func viewDidLoad() {
        super.viewDidLoad()

        minAxis = min(SCREEN_HEIGHT, SCREEN_WIDTH);
        view.frame = UIScreen.main.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.backgroundColor = UIColor.clear

        if (navigationController != nil) {
            navigationController?.delegate = self;
        }

        captureSession = AVCaptureSession()

        let videoCaptureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice!)
        } catch {
            return
        }

        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed();
            return;
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            //metadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.ean8, AVMetadataObject.ObjectType.ean13, AVMetadataObject.ObjectType.pdf417]
            metadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
        } else {
            failed()
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession);
        previewLayer.frame = view.layer.bounds;
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill;
        //view.layer.addSublayer(previewLayer);
        view.layer.insertSublayer(previewLayer, at: 0)

        captureSession.startRunning();

        

        if self.options != nil, let scan = self.options!["onlyScan"] as? Bool {
            self.onlyScan = scan
        }
        if self.options != nil, let language = self.options!["language"] as? String {
            self.lang = language
        }
        
        if self.options != nil, let scanStyle = self.options["scanStyle"] as? [String: Any], let borderColor = scanStyle["borderColor"] as? String {
            if let buildReticleColor = UIColor.getHex(hex: borderColor, 0.5) {
                self.buildReticleColor = buildReticleColor
            }
            if let minViewColor = UIColor.getHex(hex: borderColor, 1.0) {
                self.minViewColor = minViewColor
            }
            
        }
        
        addReticleView();
    }



    @IBAction func doneClicked(_ sender: Any) {

        JJPrint("exit clicked2")
        //self.navigationController?.popViewController(animated: true)
        self.navigationController?.dismiss(animated: true)
    }

    func failed() {

        JJPrint("failed")

        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        
        if #available(iOS 13.0, *) {
            
        } else {
            if let statusBarWindow = UIApplication.shared.value(forKey: "statusBarWindow") as? NSObject, let statusbar = statusBarWindow.value(forKey: "statusBar") as? UIView {
                if statusbar.responds(to: #selector(setter: UIView.backgroundColor)) {
                    statusbar.backgroundColor = .clear;
                }
            }
        }
        
        
        
        
        if (captureSession?.isRunning == false) {
            captureSession.startRunning();
        }

        loopSubViewSetBtn(self.view);
    }
    private func loopSubViewSetBtn(_ view:UIView) {
        for var v in view.subviews {
            if v.isKind(of: UIButton.self)  {
                if let button = v as? UIButton, let text = button.titleLabel?.text {
                    if (text == "Cancel") || (text == "取消") {
                        let t = lang == "en" ? "Cancel" : "取消";
                        button.setTitle(t, for: .normal);
                    }
                }
                return;
            } else {
                loopSubViewSetBtn(v)
            }
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if (captureSession?.isRunning == true) {
            captureSession.stopRunning();
        }
    }

    /*
     Obselete code copied from https://stackoverflow.com/questions/46011211/barcode-on-swift-4
     
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            let readableObject = metadataObject as! AVMetadataMachineReadableCodeObject;
            
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: readableObject.stringValue!);
        }
        
        dismiss(animated: true)
    }*/


    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {

        JJPrint("metadataOutput")

        captureSession.stopRunning()

        if let metadataObject = metadataObjects.first {
            let readableObject = metadataObject as! AVMetadataMachineReadableCodeObject;

            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: readableObject.stringValue ?? "");
        }

        //dismiss(animated: true)
    }



    func found(code: String) {
        JJPrint(code)

        if onlyScan && closeCB != nil {
            let result = ["decodeResult":code];
//            closeCB?(result);
            dismiss(animated: true) {[weak self] in
                self?.closeCB?(result)
            }
//            dismiss(animated: true, completion: nil)
            return;
        }
        if (SVDelegate == nil && code.starts(with: "http")) { // from scan order.place
            self.url = code
            self.performSegue(withIdentifier: "Scan2Order", sender: self)
        } else { // from ionic scan service
            SVDelegate?.scannerReulst(result: code)
            dismiss(animated: true, completion: nil)
        }


//        if(code.starts(with: "http")) {
//            self.url = code
//            self.performSegue(withIdentifier: "Scan2Order", sender: self)
//        } else {
//            dismiss(animated: true, completion: nil)
//        }

        //orderVC.url = url;
        //orderVC.features = features;
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if(self.url == nil) {
            return
        }

        if segue.identifier == "Scan2Order" {
            let controller = segue.destination as! OrderViewController;
            controller.url = self.url;
            controller.options = self.options;
            controller.closeCB = closeCB;
            ScannerManager.shared.scannerDelegate = controller;
        }
    }

//    override var prefersStatusBarHidden: Bool {
//        return true
//    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    

}

//extension ScannerViewController: OrderPlaceDelegate {
//    func applicationOpenUrl(_ app: UIApplication, url: URL) {
//
//    }
//
//}
extension ScannerViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {

        let isHidden = viewController.isKind(of: ScannerViewController.self)
        ///print("viewController: \(viewController) \(isHidden)")
        navigationController.setNavigationBarHidden(isHidden, animated: false)
    }
    
    public func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        return .portrait
    }
}

extension ScannerViewController {

    private func addReticleView() {
        guard let reticleImage = buildReticleImage() else { return; }

        let reticleView = UIImageView(image: reticleImage);
        reticleView.contentMode = .scaleAspectFit

        let rectArea = CGRect(x: CGFloat(0.5 * (SCREEN_WIDTH - minAxis)), y: CGFloat(0.5 * (SCREEN_HEIGHT - minAxis)), width: minAxis, height: minAxis);
        reticleView.frame = rectArea;
        reticleView.isOpaque = false
        reticleView.contentMode = .scaleAspectFit
        reticleView.autoresizingMask = [.flexibleRightMargin, .flexibleLeftMargin, .flexibleBottomMargin, .flexibleTopMargin];
        if let midImage = buildMinBar() {
            
            let minView = UIImageView(image: midImage);
            minView.isOpaque = false
            minView.contentMode = .scaleAspectFit
            minView.autoresizingMask = [.flexibleRightMargin, .flexibleLeftMargin, .flexibleBottomMargin, .flexibleTopMargin];
            minView.frame = CGRect(x: RETICLE_OFFSET + (RETICLE_WIDTH * 0.5), y: RETICLE_OFFSET + (RETICLE_WIDTH * 0.5), width: (minAxis - 2 * RETICLE_OFFSET - RETICLE_WIDTH), height: MINVIEW_WIDTH);
            self.minView = minView;
            reticleView.addSubview(minView)
        }
        self.reticleView = reticleView;
        reticleView.clipsToBounds = true;
        view.addSubview(reticleView);

        addDrawView(rectArea);

        beginScanAnimation();
    }

    private func addDrawView(_ rectArea: CGRect) {
        let drawView = DrawView(frame: UIScreen.main.bounds)
        var blankF = rectArea
        blankF.origin.x += RETICLE_OFFSET;
        blankF.origin.y += RETICLE_OFFSET;
        blankF.size.height = minAxis - 2 * RETICLE_OFFSET;
        blankF.size.width = minAxis - 2 * RETICLE_OFFSET;
        drawView.blankFramework = blankF;
        view.insertSubview(drawView, at: 1)
    }

    private func beginScanAnimation() {
        if (minView == nil || reticleView == nil) { return }
        self.minView.frame.origin.y = RETICLE_OFFSET + (RETICLE_WIDTH * 0.5);
        self.view.layoutIfNeeded();
        UIView.animate(withDuration: 2.0) {
            UIView.setAnimationRepeatCount(Float(CGFloat.greatestFiniteMagnitude))
            self.minView.frame.origin.y = self.reticleView.frame.size.height - self.RETICLE_OFFSET - self.RETICLE_WIDTH;
            self.view.layoutIfNeeded();
        }

    }
    private func buildMinBar() -> UIImage? {
        var result: UIImage? = nil;

        UIGraphicsBeginImageContext(CGSize(width: minAxis, height: MINVIEW_WIDTH))
        let context = UIGraphicsGetCurrentContext()
        context?.setStrokeColor(minViewColor.cgColor)
        context?.setLineWidth(RETICLE_WIDTH)
        context?.stroke(CGRect(x: 0, y: 0, width: minAxis, height: MINVIEW_WIDTH))
        result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return result;
    }

    private func buildReticleImage() -> UIImage? {
        var result: UIImage? = nil;
        UIGraphicsBeginImageContext(CGSize(width: minAxis, height: minAxis))
        let context = UIGraphicsGetCurrentContext()
        context?.setStrokeColor(buildReticleColor.cgColor);
        context?.setLineWidth(RETICLE_WIDTH)
        context?.stroke(CGRect(x: RETICLE_OFFSET, y: RETICLE_OFFSET, width: minAxis - 2 * RETICLE_OFFSET, height: minAxis - 2 * RETICLE_OFFSET))
        result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result;
    }

}

