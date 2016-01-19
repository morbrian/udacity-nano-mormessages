//
//  Message.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/18/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import Foundation
import CoreData


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
            stringForSingleKey(ForumService.ForumJsonKey.Text, andValue: text),
            stringForSingleKey(ForumService.ForumJsonKey.ImageUrl, andValue: imageUrl)
            ].filter({$0 != nil}).map({$0!}))
    }
    
    override func applyState(state: [String:AnyObject]) {
        super.applyState(state)
        // forum
        text = state[ForumService.ForumJsonKey.Text] as? String
        imageUrl = state[ForumService.ForumJsonKey.ImageUrl] as? String
    }
    
    

}
