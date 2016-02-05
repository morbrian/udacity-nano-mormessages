//
//  Message.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/18/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import Foundation
import CoreData
import UIKit


class Message: BaseEntity {
    
    static let EntityName = "Message"
    
    class func findExistingWithUuid(uuid: AnyObject?) -> Message? {
        return BaseEntity.findExistingEntity(EntityName, withUuid: uuid) as? Message
    }
    
    class func produceWithState(state: [String:AnyObject]?) -> Message? {
        return BaseEntity.produceEntity(EntityName, withState: state) as? Message
    }
    
    override func fieldPairArray() -> [String] {
        return super.fieldPairArray() + ([
            BaseEntity.stringForSingleKey(ForumService.ForumJsonKey.Text, andValue: text),
            BaseEntity.stringForSingleKey(ForumService.ForumJsonKey.ImageUrl, andValue: imageUrl),
            BaseEntity.stringForSingleKey(ForumService.ForumJsonKey.ForumUuid, andValue: forum?.uuid)
            ].filter({$0 != nil}).map({$0!}))
    }
    
    override func applyState(state: [String:AnyObject]) {
        super.applyState(state)
        // forum
        text = state[ForumService.ForumJsonKey.Text] as? String
        imageUrl = state[ForumService.ForumJsonKey.ImageUrl] as? String
        forum = Forum.findExistingWithUuid(state[ForumService.ForumJsonKey.ForumUuid])
    }
    
    var messageImage: UIImage? {
        
        get {
            return WebClient.Caches.imageCache.imageWithIdentifier(imageUrl)
        }
        
        set {
            if let imageUrl = imageUrl {
                WebClient.Caches.imageCache.storeImage(newValue, withIdentifier: imageUrl)
            }
        }
    }
    

}
