//
//  Forum.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/17/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import Foundation
import CoreData


class Forum: NSManagedObject {
    
    class func produceVerifiedForumWithState(state: [String:AnyObject]) -> Forum? {
        let forum = produceForumWithState(state)
        return (forum.id < 0) ? nil : forum
    }

    class func produceForumWithState(state: [String:AnyObject]) -> Forum {
        let forum = Forum()
        forum.id = state[ForumService.ForumJsonKey.Id] as? Int64 ?? -1
        forum.createdTime = DateToolkit.timeIntervalFromAnyObject(state[ForumService.ForumJsonKey.CreatedTime]) ?? NSTimeInterval()
        forum.modifiedTime = DateToolkit.timeIntervalFromAnyObject(state[ForumService.ForumJsonKey.ModifiedTime]) ?? NSTimeInterval()
        forum.createdBy = state[ForumService.ForumJsonKey.CreatedBy] as? String
        forum.modifiedBy = state[ForumService.ForumJsonKey.ModifiedBy] as? String
        forum.title = state[ForumService.ForumJsonKey.Title] as? String
        forum.desc = state[ForumService.ForumJsonKey.Description] as? String
        forum.imageUrl = state[ForumService.ForumJsonKey.ImageUrl] as? String
        return forum
    }

}
