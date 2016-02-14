//
//  MessageCellView.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/29/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import UIKit

class MessageCellView: UITableViewCell {
    
    var tasksToCancelifCellIsReused: [NSURLSessionTask]? {
        
        didSet {
            if let tasksToCancel = oldValue {
                for task in tasksToCancel {
                    task.cancel()
                }
            }
        }
    }
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView? {
        didSet {
            // TODO: this is not showing the desired effect, may need to embed in containing view.
            activityIndicator?.layer.cornerRadius = 8.0
            activityIndicator?.layer.borderColor = UIColor.lightGrayColor().CGColor
        }
    }

    @IBOutlet weak var contentTextView: UITextView! {
        didSet {
            if contentTextView != nil {
                contentTextView.layer.cornerRadius = 8.0
            }
        }
    }
    
    @IBOutlet weak var avatarImageView: UIImageView!
    
    var message: Message? {
        didSet {
            if let message = message {
                configureCellWithMessage(message)
            } else {
                contentTextView.text = nil
            }
        }
    }
    
    // MARK: - Configure Cell
    
    func configureCellWithMessage(message: Message) {
        
        if let contentTextView = contentTextView {
            contentTextView.text = message.text
        }
        
        if let avatarImageView = avatarImageView {
            configureImageView(avatarImageView, urlString: message.ownerImageUrlString, proposedImage: message.ownerImage) { image in
                message.ownerImage = image
                if self.message?.ownerImageUrlString == message.ownerImageUrlString {
                    self.avatarImageView?.image = image
                }
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