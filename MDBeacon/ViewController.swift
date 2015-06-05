//
//  ViewController.swift
//  MDBeacon
//
//  Created by Max Yelsky on 5/29/15.
//  Copyright (c) 2015 MissionData. All rights reserved.
//

/*TODO: Implement a better way of dealing with edge cases than timeIntervalSince1970
        Try to write serverside to be able to see who else in the office
        Add the UUID of the louisville device
        Refactor leave() and enter() into one function
        Drop the proximity stuff, it's unnecessary
        --Currently updates once every 60 seconds
*/

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet var locationDisplay: UITextView! //Declare a textView
    var textToDisplay = ""                     //Declare a global string that will hold the text to display
    var atTheOffice = false                    //Declare a global bool @theoffice
    var location = ""
    var user = ""
    var time:Double = 0         //using this as a measure of time between resets (handle edge cases)
    
    //let myTimer: NSTimer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: Selector("function name here"), userInfo: nil, repeats: true)
    let locationManager = CLLocationManager()
    
    //set the region
    let washington = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: "8AEFB031-6C32-486F-825B-E26FA193487D"), identifier: "ParticleWhiteTag")
    let louisville = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: "FILL THIS IN"), identifier: "ParticleWallUnit")
    
    override func viewDidLoad() {   //Runs once, set up locationManager, adjust text, alert for name
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false //set text to top of display
        locationManager.delegate = self                   //set up locationmanager
        self.time = NSTimeIntervalSince1970
        if (CLLocationManager.authorizationStatus() != CLAuthorizationStatus.AuthorizedAlways) {
            self.locationManager.requestAlwaysAuthorization()
        }
        
        //Create the alert controller, configure text field, get name, set name = input
        var alert = UIAlertController(title: "Slack Username", message: "Enter your username, or whatever you want Slack to call you.", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler({ (textField) in
            textField.placeholder = "Enter username here"
        })
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
            let textField = alert.textFields![0] as! UITextField
            self.user = textField.text
            self.locationManager.startRangingBeaconsInRegion(self.washington)
        }))
        self.presentViewController(alert, animated: true, completion: nil)

    }
    
    //Dismiss the keyboard if the user presses the display
    @IBAction func viewTapped(sender : AnyObject) {
        locationDisplay.resignFirstResponder()
    }
    
    func locationManager(manager: CLLocationManager!, didRangeBeacons beacons:[AnyObject]!, inRegion region: CLBeaconRegion!) {
        var time_check = NSTimeIntervalSince1970    //get another measure of time
        
        if ((time_check - time) > 60) {
            time = time_check                       //set time to new time
        
            if region == washington {
                location = "The F Street Office"
            } else if region == louisville {
                location = "The Kentucky Office"
            } else {
                location = "Error"
            }
        
            let knownBeacons = beacons.filter{ $0.proximity != CLProximity.Unknown }
        
            //If a beacon is detected while inside the beacon region
            if (knownBeacons.count > 0) {
                let closestBeacon = knownBeacons[0] as! CLBeacon //save the beacon
            
                var proximity = (closestBeacon.proximity)  //get the proximity of closest beacon
                var proximityDisplay = ""
                switch(proximity) {
                case CLProximity.Immediate:
                    proximityDisplay = "right on top of the beacon!"
                case CLProximity.Near:
                    proximityDisplay = "in a room with the beacon!"
                case CLProximity.Far:
                    proximityDisplay = "somewhere near the beacon!"
                case CLProximity.Unknown:
                    proximityDisplay = "unknown relaive to the beacon!"
                default:
                    println("Huh? Switch statement didn't catch you, impossible.")
                }
            
                if (!atTheOffice) {
                    //if you weren't at the office, and now you see a beacon
                    enter(location, user)
                    atTheOffice = true
                    textToDisplay = "You're at the F Street Office and \(proximityDisplay)"
                }
            } else if ((knownBeacons.count == 0) && atTheOffice) {
                //if you were at the office, but now there are no more beacons
                leave(location, user)
                atTheOffice = false
                textToDisplay = "You're not at any office. Shouldn't you be working or something?"
            }
        
            //Update the text
            refreshUI()
        }
    }
    
    //Refresh the textView
    func refreshUI() {
        locationDisplay.text = textToDisplay
        locationDisplay.font = UIFont(name: "Futura-Medium", size: 30) //set font size
        locationDisplay.textAlignment = .Center
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

func enter(location: String, user: String) {
    //URL where POST request is going
    let url = NSURL(string: "http://10.0.1.65:3000/api/v1/enter.json")
    //Create a Mutable URL request with said (unwrapped) URL
    var request:NSMutableURLRequest = NSMutableURLRequest(URL: url!)
    
    //For the sake of making a properly formatted JSON Object
    let array = [ "slack_post": ["name":"\(user)", "location":"\(location)"]]
    let data = NSJSONSerialization.dataWithJSONObject(array, options: nil, error: nil)
    let string = NSString(data: data!, encoding: NSUTF8StringEncoding)
    print(string)
    
    //HTTP request formatting, the header is important
    request.HTTPMethod = "POST"
    request.HTTPBody = string!.dataUsingEncoding(NSUTF8StringEncoding)
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.currentQueue()) {
        (response, maybeData, error) in
        if let data = maybeData {
            let contents = NSString(data: data, encoding:NSUTF8StringEncoding)
            println(contents)
        } else {
            println(error.localizedDescription)
        }
    }
    
    
}

func leave(location: String, user: String) {
    //URL where POST request is going
    let url = NSURL(string: "http://10.0.1.65:3000/api/v1/leave.json")
    //Create a Mutable URL request with said (unwrapped) URL
    var request:NSMutableURLRequest = NSMutableURLRequest(URL: url!)
    
    //For the sake of making a properly formatted JSON Object
    let array = [ "slack_post": ["name":"\(user)", "location":"\(location)"]]
    let data = NSJSONSerialization.dataWithJSONObject(array, options: nil, error: nil)
    let string = NSString(data: data!, encoding: NSUTF8StringEncoding)
    print(string)
    
    //HTTP request formatting, the header is important
    request.HTTPMethod = "POST"
    request.HTTPBody = string!.dataUsingEncoding(NSUTF8StringEncoding)
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.currentQueue()) {
        (response, maybeData, error) in
        if let data = maybeData {
            let contents = NSString(data: data, encoding:NSUTF8StringEncoding)
            println(contents)
        } else {
            println(error.localizedDescription)
        }
    }
}

