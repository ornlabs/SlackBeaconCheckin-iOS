//
//  SlackNameViewController.swift
//  Beacon
//
//  Created by Max Yelsky on 6/10/15.
//  Copyright (c) 2015 MissionData. All rights reserved.
//

import UIKit

class SlackNameViewController: UIViewController {
    
    @IBOutlet var nameField:UITextField!
    @IBOutlet var saveNameButton:UIButton!
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let name = NSUserDefaults.standardUserDefaults().objectForKey("name") as? String {
            self.nameField.text = name
        }
    }
    
    @IBAction func updateUserName(Sender : AnyObject!) {
        NSUserDefaults.standardUserDefaults().setObject(nameField.text, forKey: "name")
    }

}
