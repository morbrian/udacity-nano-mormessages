//
//  UserInfo.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/22/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import Foundation
import UIKit

struct UserInfo {
    
    let identity: String
    let avatarUrlString: String?
    
    init(identity: String) {
        self.identity = identity
        self.avatarUrlString = ToolKit.produceRobohashUrlFromString(identity)?.absoluteString
        configureAvatar()
    }
    
    var avatarImage: UIImage? {
        
        get {
            return WebClient.Caches.imageCache.imageWithIdentifier(avatarUrlString)
        }
        
        set {
            if let imageUrl = avatarUrlString {
                WebClient.Caches.imageCache.storeImage(newValue, withIdentifier: imageUrl)
            }
        }
    }
    
    private mutating func configureAvatar() {
        if avatarImage == nil {
            // has an image name, but it is not downloaded yet.
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            let handler = {(data: NSData?, error: NSError?) in
                dispatch_async(dispatch_get_main_queue()) {
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                }
                if error != nil {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.avatarImage = UIImage(named: Constants.ForumNoImage)
                    }
                } else if let data = data {
                    // Craete the image
                    let image = UIImage(data: data)
                    dispatch_async(dispatch_get_main_queue()) {
                        // update the model, so that the informatino gets cached
                        self.avatarImage = image
                    }
                }
                
            }
            WebClient().taskForImageUrlString(self.avatarUrlString, completionHandler: handler)
        }
    }
}