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
    @IBOutlet weak var loadingActivity: UIActivityIndicatorView!
    
    private var observer: NSObjectProtocol?
    private var initialLoading:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initialLoading = true
        
        if NSUserDefaults.standardUserDefaults().stringForKey("name") == nil {
            self.refreshUI("Please set your Username!")
            self.initialLoading = false
        }
        
        self.displaySpinner()
        
        self.observer = NSNotificationCenter.defaultCenter().addObserverForName("textNotification", object: nil, queue: nil) { (notification:NSNotification!) -> Void in
            
            self.initialLoading = false
            
            if let userInfo:Dictionary<String,String!> = notification.userInfo as? Dictionary<String,String!> {
                if let message = userInfo["text"] {
                    self.refreshUI(message)
                }
            }
            
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.displaySpinner()
    }
    
    deinit {
        if let observer = self.observer {
            NSNotificationCenter.defaultCenter().removeObserver(observer)
        }
    }
    
    //Dismiss the keyboard if the user presses the display
    @IBAction func viewTapped(sender : AnyObject) {
        textDisplay.resignFirstResponder()
    }
    
    func refreshUI(message:String) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.loadingActivity.hidden = true
            self.loadingActivity.stopAnimating()
            
            self.automaticallyAdjustsScrollViewInsets = false //set text to top of display
            self.textDisplay.text = message
            self.textDisplay.font = UIFont(name: "Futura-Medium", size: 20) //set font size
            self.textDisplay.textAlignment = .Center
        })
    }

    func displaySpinner() {
        if self.initialLoading {
            self.loadingActivity.hidden = false
            self.loadingActivity.startAnimating()
        } else {
            self.loadingActivity.hidden = true
            self.loadingActivity.stopAnimating()
        }
    }
}

