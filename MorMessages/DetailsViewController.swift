//
//  DetailsViewController.swift
//  MorMessages
//
//  Created by Brian Moriarty on 2/6/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import Foundation
import UIKit

class DetailsViewController: UIViewController {
    
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var forumImageView: UIImageView!
    @IBOutlet weak var forumTitleLabel: UILabel!
    @IBOutlet weak var forumDescriptionTextView: UITextView!
    @IBOutlet weak var createdByImageView: UIImageView!
    @IBOutlet weak var createdByUsernameLabel: UILabel!
    @IBOutlet weak var createdDateLabel: UILabel!
    @IBOutlet weak var modifiedByImageView: UIImageView!
    @IBOutlet weak var modifiedByUsernameLabel: UILabel!
    @IBOutlet weak var modifiedDateLabel: UILabel!
    
    var manager: MorMessagesManager!
    var forum: Forum!
    
    // MARK: ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        forumTitleLabel.text = forum.title
        forumDescriptionTextView.text = forum.desc
        forumImageView.image = forum.forumImage
        
        createdByImageView.image = forum.ownerImage
        createdByUsernameLabel.text = forum.createdBy
        if let createdTime = forum.createdTime {
            createdDateLabel.text = ToolKit.DateKit.DateFormatter.stringFromDate(createdTime)
        } else {
            createdDateLabel.text = "date unknown"
        }
        
        modifiedByImageView.image = UIImage(named: Constants.ForumNoImage)
        modifiedByUsernameLabel.text = forum.createdBy
        if let modifiedTime = forum.modifiedTime {
            modifiedDateLabel.text = ToolKit.DateKit.DateFormatter.stringFromDate(modifiedTime)
        } else {
            modifiedDateLabel.text = "date unknown"
        }
    }

}

