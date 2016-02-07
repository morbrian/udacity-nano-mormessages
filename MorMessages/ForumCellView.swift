//
//  ForumCellView.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/23/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import UIKit

class ForumCellView:UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView?
    
    @IBOutlet weak var avatarView: UIImageView?
    
    @IBOutlet weak var title: UILabel!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView? {
        didSet {
            // TODO: this is not showing the desired effect, may need to embed in containing view.
            activityIndicator?.layer.cornerRadius = 8.0
            activityIndicator?.layer.borderColor = UIColor.lightGrayColor().CGColor
        }
    }
    
    var tasksToCancelifCellIsReused: [NSURLSessionTask]? {
        
        didSet {
            if let tasksToCancel = oldValue {
                for task in tasksToCancel {
                    task.cancel()
                }
            }
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
        
        configureImageView(avatarView, urlString: forum.ownerImageUrlString, proposedImage: forum.ownerImage) { image in
            forum.ownerImage = image
            if self.forum?.ownerImageUrlString == forum.ownerImageUrlString {
                self.avatarView?.image = image
            }
        }
        
        configureImageView(imageView, urlString: forum.imageUrl, proposedImage: forum.forumImage) { image in
            forum.forumImage = image
            if self.forum?.imageUrl == forum.imageUrl {
                self.imageView!.image = image
            }
        }
    }
    
    private func configureImageView(imageView: UIImageView?, urlString: String?,
        proposedImage: UIImage?, dataSpecificAction: (image: UIImage) -> Void) {
        if let image = proposedImage {
            imageView?.image = image
        } else {
            imageView?.image =  UIImage(named: Constants.ForumFetchingImage)
            fetchImage(urlString) { image in
                dispatch_async(dispatch_get_main_queue()) {
                    self.activityIndicator?.stopAnimating()
                    if let image = image {
                        dataSpecificAction(image: image)
                    } else {
                        imageView?.image = UIImage(named: Constants.ForumNoImage)
                    }
                }
            }
        }
    }
    
    private func fetchImage(imageUrlString: String?, completionHandler: (image: UIImage?) -> Void) {
        // Set the Image
        if imageUrlString == nil || imageUrlString!.isEmpty {
            completionHandler(image: nil)
        } else {
            // has an image name, but it is not downloaded yet.
            let handler = {(data: NSData?, error: NSError?) in
                if error != nil {
                    completionHandler(image: nil)
                } else if let data = data {
                    completionHandler(image: UIImage(data: data))
                }
            }
            
            // Start the task that will eventually download the image

            self.activityIndicator?.startAnimating()
            if let task = WebClient().taskForImageUrlString(imageUrlString, completionHandler: handler) {
                tasksToCancelifCellIsReused?.append(task)
            } else {
                tasksToCancelifCellIsReused = nil
                self.activityIndicator?.stopAnimating()
            }
            
        }
    }


    
}
