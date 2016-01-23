//
//  ForumViewController.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/22/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import UIKit

class ForumViewController: UIViewController {
    
    @IBOutlet weak var usernameLabel: UILabel!
    
    // central data management object
    var manager: MorMessagesManager!
    
    override func viewDidLoad() {
        manager.whoami() {
            identity, error in
            dispatch_async(dispatch_get_main_queue()) {
                self.usernameLabel.text = identity
            }
        }
        
        // normally, this will be how we get user,
        // but for the initial smoke test we're asking whoami
        //usernameLabel.text = manager.currentUser?.identity
    }
    
}