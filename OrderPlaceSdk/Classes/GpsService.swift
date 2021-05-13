//
//  GpsService.swift
//  OrderPlaceSdk
//
//  Created by Peter Liu on 7/9/2018.
//

import Foundation
import UIKit
import WebKit
import MapKit

public class GpsService: OrderPlaceService, CLLocationManagerDelegate {
    
    var lm: CLLocationManager!;
    var listenCb: CallbackHandler!;
    var lastCb: CallbackHandler!;
    
    override public func getServiceName() -> String{
        return "GpsService";
    }
    
    override public func initialize(){
        
        self.lm = CLLocationManager()
        self.lm.delegate = self
        self.lm.desiredAccuracy = kCLLocationAccuracyBest
        self.lm.requestWhenInUseAuthorization()
        //self.lm.requestAlwaysAuthorization()
        
    }
    
    override public func handleMessage(method: String, body: NSDictionary, callback: CallbackHandler?) {
        
        JJPrint("GpsService:\(method)--:\(body)")
        
        switch method{
        case "listenUpdate":
            listenUpdate(callback: callback);
            break;
            
        case "getLastLocation":
            getLastLocation(callback: callback);
            break;
        case "stopUpdate":
            stopUpdate();
            break;
            
        default:
            break;
            
        }
        
        
    }
    
    func listenUpdate(callback: CallbackHandler?){
        
        self.listenCb = callback;
        
        self.lm.startUpdatingLocation()
        
        JJPrint("started location updates")
    }
    
    func getLastLocation(callback: CallbackHandler?){
        
        self.lastCb = callback;
        self.lm.startUpdatingLocation()
        
        JJPrint("started get location")
        
    }
    
    func stopUpdate(){
        
        self.lm.stopUpdatingLocation()
        self.listenCb = nil
        self.lastCb = nil
        
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        
        JJPrint("locations:\(locations)")
        
        for loc in locations{
            
            let jo = [
                "latitude": loc.coordinate.latitude,
                "longitude": loc.coordinate.longitude,
                "altitude": loc.altitude,
                "accuracy": loc.horizontalAccuracy,
                "time": floor(loc.timestamp.timeIntervalSince1970 * 1000)
                ] as [String : Any];
            
            if(self.listenCb != nil){
                self.listenCb.success(response: jo)
            }
            
            if(self.lastCb != nil){
                self.lastCb.success(response: jo)
                self.lastCb = nil
            }
            
            break;
            
        }
        
        if(self.lastCb == nil && self.listenCb == nil){
            self.stopUpdate()
        }
        
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error){
        
        JJPrint("location failed")
    }
}
