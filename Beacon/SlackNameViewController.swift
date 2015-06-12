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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //notificationCenter.addObserver(saveNameButton, selector: thing, name: <#String?#>, object: <#AnyObject?#>)

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func updateUserName(Sender : AnyObject!) {
        NSUserDefaults.standardUserDefaults().setObject(nameField.text, forKey: "name")
    }
    /*
    FIGURE THIS OUT, USING PREPAREFORSEGUE TO POPULATE THE LABEL
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        segue.destinationViewController = ViewController
        
    }
    */

}
