//
//  ViewController.swift
//  Beacon
//
//  Created by Max Yelsky on 6/10/15.
//  Copyright (c) 2015 MissionData. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var textDisplay: UITextView!
    @IBOutlet var setNameButton: UIButton!
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    let notification = NSNotificationCenter.defaultCenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defaults = NSUserDefaults.standardUserDefaults()

        if defaults.stringForKey("name") == nil {
            appDelegate.textToDisplay = "Please set your Username!"
            refreshUI()
        }
        
        notification.addObserver(self, selector: "refreshUI", name: "textNotification", object: appDelegate)

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //Dismiss the keyboard if the user presses the display
    @IBAction func viewTapped(sender : AnyObject) {
        textDisplay.resignFirstResponder()
    }
    
    func refreshUI() {
        self.automaticallyAdjustsScrollViewInsets = false //set text to top of display
        textDisplay.text = appDelegate.textToDisplay
        textDisplay.font = UIFont(name: "Futura-Medium", size: 20) //set font size
        textDisplay.textAlignment = .Center
    }

}

