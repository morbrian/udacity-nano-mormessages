//
//  Forum.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/18/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import Foundation
import UIKit
import CoreData


class Forum: BaseEntity {
    
    static let EntityName = "Forum"
    
    class func findExistingWithUuid(uuid: AnyObject?) -> Forum? {
        return BaseEntity.findExistingEntity(EntityName, withUuid: uuid) as? Forum
    }
    
    class func findExistingWithId(id: AnyObject?) -> Forum? {
        return BaseEntity.findExistingEntity(EntityName, withId: id) as? Forum
    }
    
    class func produceWithState(state: [String:AnyObject]?) -> Forum? {
        return BaseEntity.produceEntity(EntityName, withState: state) as? Forum
    }
    
    override func fieldPairArray() -> [String] {
        return super.fieldPairArray() + ([
            stringForSingleKey(ForumService.ForumJsonKey.Title, andValue: title),
            stringForSingleKey(ForumService.ForumJsonKey.Description, andValue: desc),
            stringForSingleKey(ForumService.ForumJsonKey.ImageUrl, andValue: imageUrl)
        ].filter({$0 != nil}).map({$0!}))
    }

    override func applyState(state: [String:AnyObject]) {
        super.applyState(state)
        // forum
        title = state[ForumService.ForumJsonKey.Title] as? String
        desc = state[ForumService.ForumJsonKey.Description] as? String
        imageUrl = state[ForumService.ForumJsonKey.ImageUrl] as? String
    }
    
    var forumImage: UIImage? {
        
        get {
            return WebClient.Caches.imageCache.imageWithIdentifier(imageUrl)
        }
        
        set {
            if let imageUrl = imageUrl {
                WebClient.Caches.imageCache.storeImage(newValue, withIdentifier: imageUrl)
            }
        }
    }
    
    func fetchMessageList(completionHandler: (() -> Void)? = nil) {
        ForumService.sharedInstance().listMessagesInForum(self, offset: 0, resultSize: 5) { messages, error in
            if let error = error {
                Logger.error("Failed to get message list for forum: \(error)")
            }
            completionHandler?()
        }
    }

    
}