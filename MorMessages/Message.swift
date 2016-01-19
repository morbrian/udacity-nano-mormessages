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

    override func applyState(state: [String:AnyObject]) {
        super.applyState(state)
        // forum
        text = state[ForumService.ForumJsonKey.Text] as? String
        imageUrl = state[ForumService.ForumJsonKey.ImageUrl] as? String
    }

}
