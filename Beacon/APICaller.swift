//
//  APICaller.swift
//  Beacon
//
//  Created by Max Yelsky on 6/10/15.
//  Copyright (c) 2015 MissionData. All rights reserved.
//

import Foundation

class APICaller : NSObject {
    
    private let APIDomain = ""
    private let baseAPIURL = "http://10.0.1.65/api/v1/"
    
    class var sharedInstance : APICaller {
        struct Static {
            static let instance : APICaller = APICaller()
        }
        return Static.instance
    }
    
    //Override the init() function with private attribute so that a new one can't be made
    private override init() {
        super.init()
    }
    
    //Pass enter a name, location, a function to call on success and a function to call if an error is found
    func postToSlack(name: String, location: String, direction: String, successFunction: (() -> Void), errorFunction: ((NSError) -> Void)) {
        // Make the HTTP call, use baseAPIURL as the starting point of the call
        let url = NSURL(string: "http://10.0.1.65:3000/api/v1/\(direction).json")
        println(url)
        var request:NSMutableURLRequest = NSMutableURLRequest(URL: url!)
        let array = [ "slack_post": ["name":"\(name)", "location":"\(location)"]]
        let data = NSJSONSerialization.dataWithJSONObject(array, options: nil, error: nil)
        let string = NSString(data: data!, encoding: NSUTF8StringEncoding)
        request.HTTPMethod = "POST"
        request.HTTPBody = string!.dataUsingEncoding(NSUTF8StringEncoding)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.currentQueue()) {
            (response, maybeData, error) in
            if let data = maybeData {
                let contents = NSString(data: data, encoding:NSUTF8StringEncoding)
                successFunction()   //success
            } else {
                println(error.localizedDescription)
                errorFunction(NSError(domain: self.APIDomain, code: -1, userInfo: [NSLocalizedDescriptionKey:"An Error Occurred!"]))    //failure

            }
        }
    }
    
    func getUUIDs(completionHandler: ((array: NSArray) -> Void)) {
        var request: NSMutableURLRequest = NSMutableURLRequest(URL: NSURL(string: "http://10.0.1.65:3000/api/v1/uuids.json")!)
        var session = NSURLSession.sharedSession()
        request.HTTPMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        var array = NSArray()
        var task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            //println("Gets here")
            var strData = NSString(data: data, encoding: NSUTF8StringEncoding)
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
                    array = parseJSON["payload"] as! NSArray
                    completionHandler(array: array)
                    //println(array)
                }
                else {
                    // Woa, okay the json object was nil, something went wrong. Maybe the server isn't running?
                    let jsonStr = NSString(data: data, encoding: NSUTF8StringEncoding)
                    println("Error could not parse JSON: \(jsonStr)")
                }
            }
        })
        
        task.resume()

    }
    
}
