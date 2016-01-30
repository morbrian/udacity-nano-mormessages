//
//  MessageCellView.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/29/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import UIKit

class MessageCellView: TaskCancelingTableViewCell {
    
    @IBOutlet weak var idLabel: UILabel!
    
    @IBOutlet weak var content: UILabel!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView? {
        didSet {
            // TODO: this is not showing the desired effect, may need to embed in containing view.
            activityIndicator?.layer.cornerRadius = 8.0
            activityIndicator?.layer.borderColor = UIColor.lightGrayColor().CGColor
        }
    }
    
    var message: Message? {
        didSet {
            if let message = message {
                configureCellWithMessage(message)
            }
        }
    }
    
    // MARK: - Configure Cell
    
    func configureCellWithMessage(message: Message) {
        content.text = message.text
        if let id = message.id {
            idLabel.text = String(id)
        }
        // Set the Image
        Logger.info("URL \(message.imageUrl)")
        if message.imageUrl == nil || message.imageUrl!.isEmpty {
            imageView!.image = UIImage(named: Constants.ForumNoImage)
        } else if message.messageImage != nil {
            imageView!.image = message.messageImage
        } else {
            // This is the interesting case. The movie has an image name, but it is not downloaded yet.
            
            self.activityIndicator?.startAnimating()
            let handler = {(data: NSData?, error: NSError?) in
                dispatch_async(dispatch_get_main_queue()) {
                    self.activityIndicator?.stopAnimating()
                }
                if let error = error {
                    Logger.info("Image download error: \(error.localizedDescription)")
                    dispatch_async(dispatch_get_main_queue()) {
                        self.imageView!.image = UIImage(named: Constants.ForumNoImage)
                    }
                } else if let data = data {
                    // Craete the image
                    let image = UIImage(data: data)
                    dispatch_async(dispatch_get_main_queue()) {
                        // update the model, so that the informatino gets cached
                        message.messageImage = image
                        if self.message?.imageUrl == message.imageUrl {
                            self.imageView!.image = image
                        }
                    }
                }
                
            }
            
            imageView!.image =  UIImage(named: Constants.ForumFetchingImage)
            // Start the task that will eventually download the image
            if let task = WebClient().taskForImageUrlString(message.imageUrl, completionHandler: handler) {
                taskToCancelifCellIsReused = task
            } else {
                taskToCancelifCellIsReused = nil
                self.activityIndicator?.stopAnimating()
            }
            
        }
    }
    
    
    
}