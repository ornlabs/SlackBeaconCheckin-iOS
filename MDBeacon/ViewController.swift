//
//  ViewController.swift
//  MDBeacon
//
//  Created by Max Yelsky on 5/29/15.
//  Copyright (c) 2015 MissionData. All rights reserved.
//

/*TODO: DONE: Implement a better way of dealing with edge cases than timeIntervalSince1970
        --using CAMediaTime
        DONE:Add a listing of UUIDs on the server side
        DONE:Add a GET request to get the UUIDs, then parse the json
        DONE:Use rails to determine which office you're in, then begin ranging
        DONE:Get the name stuff back in
        Might be DONE: Add authentication to rails
        Refactor leave() and enter() into one function
        DONE: Drop the proximity stuff, it's unnecessary
        --Currently updates once every 10 seconds


        //Available Regions
        //Washington: "8AEFB031-6C32-486F-825B-E26FA193487D", beacon: White Tag
        //Louisville: "9DACB046-C64E-4F5D-B770-44F0215CC66B", beacon: WallUnit1
        //nextOffice: "2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6", beacon: WallUnit2
*/

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet var locationDisplay: UITextView! //Declare a textView
    var textToDisplay = ""                     //Declare a global string that will hold the text to display
    var atTheOffice = false                    //Declare a global bool @theoffice
    var location = ""
    var user = "Max"
    var time_ref:Double = 0                    //using this as a measure of time between resets (handle edge cases)
    let locationManager = CLLocationManager()
    var region = CLBeaconRegion()
    var regionState = ""

    
    override func viewDidLoad() {

        super.viewDidLoad()
        textToDisplay = "Updating your location!"
        self.time_ref = CACurrentMediaTime() //get the time
        
        //                                  LocationManager Setup
        locationManager.delegate = self                   //set up locationmanager
        
        if (CLLocationManager.authorizationStatus() != CLAuthorizationStatus.AuthorizedAlways) {
            self.locationManager.requestAlwaysAuthorization()
        }
        //                                  End LocationManager Setup
    
        //                                  Name Alert Controller
        //      Create the alert controller, configure text field, get name, set name = input
        
        var alert = UIAlertController(title: "Slack Username", message: "Enter your username, or whatever you want Slack to call you.", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler({ (textField) in
            textField.placeholder = "Enter username here"
        })
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
            let textField = alert.textFields![0] as! UITextField
            self.user = textField.text
            
            //                      Getting UUIDS
            var request: NSMutableURLRequest = NSMutableURLRequest(URL: NSURL(string: "http://10.0.1.65:3000/api/v1/uuids.json")!)
            var session = NSURLSession.sharedSession()
            request.HTTPMethod = "GET"
            
            //var err: NSError?
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            var task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
                //println("Response: \(response)")
                var strData = NSString(data: data, encoding: NSUTF8StringEncoding)
                //println("Body: \(strData)")
                var err: NSError?
                var json = NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves, error: &err) as? NSDictionary
                
                
                // Did the JSONObjectWithData constructor return an error? If so, log the error to the console
                if(err != nil) {
                    println(err!.localizedDescription)
                    let jsonStr = NSString(data: data, encoding: NSUTF8StringEncoding)
                    println("Error could not parse JSON: '\(jsonStr)'")
                }
                else {
                    // The JSONObjectWithData constructor didn't return an error. But, we should still
                    // check and make sure that json has a value using optional binding.
                    if let parseJSON = json {
                        // Okay, the parsedJSON is here, let's get the value for 'success' out of it
                        var array = parseJSON["payload"] as? NSArray
                        array!.enumerateObjectsUsingBlock({object, index, stop in
                            var txt: NSString = object.valueForKey("uuid") as! NSString
                            var location: NSString = object.valueForKey("location") as! NSString
                            self.region = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: (txt as String)), identifier: "\(location)")
                            self.locationManager.startMonitoringForRegion(self.region)
                            self.locationManager.requestStateForRegion(self.region)
                            
                        })
                    }
                    else {
                        // Woa, okay the json object was nil, something went wrong. Maybe the server isn't running?
                        let jsonStr = NSString(data: data, encoding: NSUTF8StringEncoding)
                        println("Error could not parse JSON: \(jsonStr)")
                    }
                }
            })
            
        //                                  End Getting UUIDs
            
            task.resume()
        }))
        self.presentViewController(alert, animated: true, completion: nil)
        
        //                                  End Name Alert
        
        
    }//End of viewDidLoad
    
    
    
    //                          locationManager monitoring regions
    func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!) {
        println("Entered \(region)")
    }
    func locationManager(manager: CLLocationManager!, didExitRegion region: CLRegion!) {
        println("Exited \(region)")
    }
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        println("\(error.localizedDescription)")
    }
    func locationManager(manager: CLLocationManager!, didDetermineState state: CLRegionState, forRegion region: CLRegion!) {
        if state == .Inside {
            self.regionState = "Inside"
            self.location = region.identifier
            self.region = region as! CLBeaconRegion
            self.locationManager.startRangingBeaconsInRegion(self.region)
        } else if state == .Outside {
            self.regionState = "Outside"
        } else {
            self.regionState = "Unknown"
        }
        
    }
    //                          End locationManager monitoring regions
    
    //                          locationManager.didRangeBeacons
    func locationManager(manager: CLLocationManager!, didRangeBeacons beacons:[AnyObject]!, inRegion region: CLBeaconRegion!) {
        var time_check = CACurrentMediaTime()                //get a measure of time
        println(time_check-self.time_ref)
        if ((time_check - self.time_ref) > 10) {
            self.time_ref = time_check                       //set time to new time
            let knownBeacons = beacons.filter{ $0.proximity != CLProximity.Unknown }
            //If a beacon is detected while inside the beacon region
            println(knownBeacons.count)
            if (knownBeacons.count > 0) {
                if (!atTheOffice) {
                    //if you weren't at the office, and now you see a beacon
                    enter(location, user)
                    atTheOffice = true
                    textToDisplay = "\(user), you're at the \(location) office"
                }
            } else if ((knownBeacons.count == 0) && atTheOffice) {
                //if you were at the office, but now there are no more beacons
                leave(location, user)
                atTheOffice = false
                textToDisplay = "You're not at any office. Shouldn't you be working or something?"
            }
        }
        refreshUI()
    }
    
    //                          End locationManager.didRangeBeacons
    
    
    //Refresh the textView
    func refreshUI() {
        self.automaticallyAdjustsScrollViewInsets = false //set text to top of display
        locationDisplay.text = textToDisplay
        locationDisplay.font = UIFont(name: "Futura-Medium", size: 30) //set font size
        locationDisplay.textAlignment = .Center
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //Dismiss the keyboard if the user presses the display
    @IBAction func viewTapped(sender : AnyObject) {
        locationDisplay.resignFirstResponder()
    }
}

func enter(location: String, user: String) {
    let url = NSURL(string: "http://10.0.1.65:3000/api/v1/enter.json")
    var request:NSMutableURLRequest = NSMutableURLRequest(URL: url!)
    let array = [ "slack_post": ["name":"\(user)", "location":"\(location)"]]
    let data = NSJSONSerialization.dataWithJSONObject(array, options: nil, error: nil)
    let string = NSString(data: data!, encoding: NSUTF8StringEncoding)
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
    let url = NSURL(string: "http://10.0.1.65:3000/api/v1/leave.json")
    var request:NSMutableURLRequest = NSMutableURLRequest(URL: url!)
    let array = [ "slack_post": ["name":"\(user)", "location":"\(location)"]]
    let data = NSJSONSerialization.dataWithJSONObject(array, options: nil, error: nil)
    let string = NSString(data: data!, encoding: NSUTF8StringEncoding)
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


