//
//  Forum.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/18/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import Foundation
import CoreData


class Forum: BaseEntity {
    
    static let EntityName = "Forum"
    
    class func findExistingWithTitle(title: AnyObject?) -> Forum? {
        if let title = title as? String {
            let titlePredicate = NSPredicate(format: "title = %@", title)
            let results = fetchEntity(EntityName, usingPredicate: titlePredicate) as! [Forum]
            
            return (results.count > 0) ? results[0] : nil
        } else {
            return nil
        }
    }
    
    class func produceWithState(state: [String:AnyObject]?) -> Forum? {
        if let state = state {
            if let forum = findExistingWithTitle(state[ForumService.ForumJsonKey.Title]) {
                forum.applyState(state)
                return forum
            } else if state[ForumService.ForumJsonKey.Title] != nil {
                return createEntity(EntityName, withState: state) as? Forum
            } else {
                return nil
            }
        } else {
            return nil
        }
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

}
