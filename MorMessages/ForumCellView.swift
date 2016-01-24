//
//  ForumCellView.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/23/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import UIKit

class ForumCellView: TaskCancelingCollectionViewCell {
    
    @IBOutlet weak var idLabel: UILabel!
    
    @IBOutlet weak var title: UILabel!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView? {
        didSet {
            // TODO: this is not showing the desired effect, may need to embed in containing view.
            activityIndicator?.layer.cornerRadius = 8.0
            activityIndicator?.layer.borderColor = UIColor.lightGrayColor().CGColor
        }
    }
    
    var forum: Forum? {
        didSet {
            if let forum = forum {
                configureCellWithForum(forum)
            }
        }
    }
    
    // MARK: - Configure Cell
    
    func configureCellWithForum(forum: Forum) {
        title.text = forum.title
        if let id = forum.id {
            idLabel.text = String(id)
        }
        // Set the Image
        if forum.imageUrl == nil || forum.imageUrl!.isEmpty {
            imageView!.image = UIImage(named: Constants.ForumNoImage)
        } else if forum.forumImage != nil {
            imageView!.image = forum.forumImage
        } else {
            // This is the interesting case. The movie has an image name, but it is not downloaded yet.
            
            self.activityIndicator?.startAnimating()
            let handler = {(data: NSData?, error: NSError?) in
                dispatch_async(dispatch_get_main_queue()) {
                    self.activityIndicator?.stopAnimating()
                }
                if let error = error {
                    print("Image download error: \(error.localizedDescription)")
                    dispatch_async(dispatch_get_main_queue()) {
                        self.imageView!.image = UIImage(named: Constants.ForumNoImage)
                    }
                } else if let data = data {
                    // Craete the image
                    let image = UIImage(data: data)
                    dispatch_async(dispatch_get_main_queue()) {
                        // update the model, so that the infrmation gets cashed
                        forum.forumImage = image
                        if self.forum?.imageUrl == forum.imageUrl {
                            self.imageView!.image = image
                        }
                    }
                }
                
            }
            
            imageView!.image =  UIImage(named: Constants.ForumFetchingImage)
            // Start the task that will eventually download the image
            if let task = WebClient().taskForImageUrlString(forum.imageUrl, completionHandler: handler) {
                taskToCancelifCellIsReused = task
            } else {
                taskToCancelifCellIsReused = nil
                self.activityIndicator?.stopAnimating()
            }
        }
    }


    
}
