//
//  Message.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/18/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import Foundation
import CoreData


class Message: NSManagedObject {
    // common
    @NSManaged var createdBy: String?
    @NSManaged var createdTime: NSTimeInterval
    @NSManaged var id: Int64
    @NSManaged var modifiedBy: String?
    @NSManaged var modifiedTime: NSTimeInterval
    // message
    @NSManaged var text: String?
    @NSManaged var imageUrl: String?
    @NSManaged var forum: Forum?
    
    func applyState(state: [String:AnyObject]) {
        //  common
        id = state[ForumService.ForumJsonKey.Id] as? Int64 ?? -1
        createdTime = DateToolkit.timeIntervalFromAnyObject(state[ForumService.ForumJsonKey.CreatedTime]) ?? NSTimeInterval()
        modifiedTime = DateToolkit.timeIntervalFromAnyObject(state[ForumService.ForumJsonKey.ModifiedTime]) ?? NSTimeInterval()
        createdBy = state[ForumService.ForumJsonKey.CreatedBy] as? String
        modifiedBy = state[ForumService.ForumJsonKey.ModifiedBy] as? String
        // message
        text = state[ForumService.ForumJsonKey.Text] as? String
        imageUrl = state[ForumService.ForumJsonKey.ImageUrl] as? String
    }

}
