//
//  AppDelegate.swift
//  Beacon
//
//  Created by Max Yelsky on 6/10/15.
//  Copyright (c) 2015 MissionData. All rights reserved.
//

import UIKit
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    
    var locationManager = CLLocationManager()
    
    let notification = NSNotificationCenter.defaultCenter()
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        ///////////////SETUP/////////////////////
        
        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: UIUserNotificationType.Alert, categories: nil))
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.delegate = self
        self.locationManager.pausesLocationUpdatesAutomatically = false
        
        ///////////////END SETUP/////////////////
        
        
        ///////////////GET UUIDS, START MONITORING REGIONS///////////////////////
        APICaller.sharedInstance.getUUIDs { (array) -> Void in
            array.enumerateObjectsUsingBlock( {object, index, stop in
                var txt: NSString = object.valueForKey("uuid") as! NSString
                var location: NSString = object.valueForKey("location") as! NSString
                let beaconUUID = NSUUID(UUIDString: txt as String)
                let beaconRegion = CLBeaconRegion(proximityUUID: beaconUUID, identifier: location as String)
                self.locationManager.startMonitoringForRegion(beaconRegion)
                self.locationManager.startRangingBeaconsInRegion(beaconRegion)
            })
        }
        ///////////////END UUIDS, NOW MONITORING/////////////////////////////////
        

        self.locationManager.startUpdatingLocation()
        return true
    }
    
    func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!) {
        var office = region.identifier
        
        //notification
        if let beaconRegion = region as? CLBeaconRegion {
            var notification = UILocalNotification()
            notification.alertBody = "Entered region \(region.identifier)"
            notification.soundName = "Default"
            UIApplication.sharedApplication().presentLocalNotificationNow(notification)
        }
        
        //post to Slack
        if let userName = NSUserDefaults.standardUserDefaults().stringForKey("name") {
            APICaller.sharedInstance.postToSlack(userName, location: region.identifier, direction: "enter", successFunction: { () -> Void in
                let textToDisplay = "\(userName), slack just noticed you entering \(office)"
                self.notification.postNotificationName("textNotification", object:nil, userInfo:["text":textToDisplay])
                println("Posted to slack")
                }, errorFunction: { (err) -> Void in
                    println("FAILED")
            })
        } else {
            self.notification.postNotificationName("textNotification", object:nil, userInfo:["text":"Please set your username!"])
        }
    }
    
    func locationManager(manager: CLLocationManager!, didExitRegion region: CLRegion!) {
        var office = region.identifier
        
        //notfication
        if let beaconRegion = region as? CLBeaconRegion {
            var notification = UILocalNotification()
            notification.alertBody = "Exited region \(region.identifier)"
            notification.soundName = "Default"
            UIApplication.sharedApplication().presentLocalNotificationNow(notification)
        }
        
        //post to slack
        if let userName = NSUserDefaults.standardUserDefaults().stringForKey("name") {
            APICaller.sharedInstance.postToSlack(userName, location: region.identifier, direction: "leave", successFunction: { () -> Void in
                let textToDisplay = "\(userName), slack just noticed you leaving \(office)"
                self.notification.postNotificationName("textNotification", object: nil, userInfo:["text":textToDisplay])
                println("Posted to slack")
                }, errorFunction: { (err) -> Void in
                    println("FAILED")
            })
        } else {
            self.notification.postNotificationName("textNotification", object: nil, userInfo:["text":"Please set your username!"])
        }
    }
    
    func locationManager(manager: CLLocationManager!, didRangeBeacons beacons: [AnyObject]!, inRegion region: CLBeaconRegion!) {
        var office = region.identifier
        
        var foundOne = false
        var closestBeacon = CLBeacon()
        
        if beacons.count > 0 {
            closestBeacon = beacons[0] as! CLBeacon
            if let userName = NSUserDefaults.standardUserDefaults().stringForKey("name") {
                APICaller.sharedInstance.postToSlack(userName, location: region.identifier, direction: "enter", successFunction: { () -> Void in
                        let textToDisplay = "\(userName), slack just noticed you at \(office)"
                        self.notification.postNotificationName("textNotification", object: nil, userInfo:["text":textToDisplay])
                    }, errorFunction: { (err) -> Void in
                        println("FAILED")
                })
            }
            foundOne = true;
            self.locationManager.stopRangingBeaconsInRegion(region)
        }
        
        if ((region.proximityUUID != closestBeacon.proximityUUID) && foundOne) {
            self.locationManager.stopRangingBeaconsInRegion(region)
        }

    }
    
}

