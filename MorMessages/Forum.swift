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

    func applyState(data: [String:AnyObject]) {
        id = data[ForumService.ForumJsonKey.Id] as? Int64 ?? -1
        createdTime = data[ForumService.ForumJsonKey.CreatedTime] as? NSTimeInterval ?? NSTimeInterval()
        modifiedTime = data[ForumService.ForumJsonKey.ModifiedTime] as? NSTimeInterval ?? NSTimeInterval()
        createdBy = data[ForumService.ForumJsonKey.CreatedBy] as? String
        modifiedBy = data[ForumService.ForumJsonKey.ModifiedBy] as? String
        title = data[ForumService.ForumJsonKey.Title] as? String
        desc = data[ForumService.ForumJsonKey.Description] as? String
        imageUrl = data[ForumService.ForumJsonKey.ImageUrl] as? String
    }

}
