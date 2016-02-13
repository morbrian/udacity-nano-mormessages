//
//  Subscription.swift
//  MorMessages
//
//  Created by Brian Moriarty on 2/12/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import Foundation

struct Subscription {
    var subscriptionId: String?
    var userIdentity: String?
    var topicId: String?
    var expirationTime: String?
    var duration: NSNumber?
    
    init(userIdentity: String, topicId: String) {
        self.userIdentity = userIdentity
        self.topicId = topicId
    }
    
    init(data: [String:AnyObject]) {
        subscriptionId = data[ForumService.ForumJsonKey.SubscriptionId] as? String ?? ""
        userIdentity = data[ForumService.ForumJsonKey.UserIdentity] as? String ?? ""
        topicId = data[ForumService.ForumJsonKey.TopicId] as? String ?? ""
        expirationTime = data[ForumService.ForumJsonKey.ExpirationTime] as? String ?? ""
        duration = data[ForumService.ForumJsonKey.Duration] as? NSNumber ?? nil
    }
    
    func fieldPairArray() -> [String] {
        return [
            BaseEntity.stringForSingleKey(ForumService.ForumJsonKey.SubscriptionId, andValue: subscriptionId),
            BaseEntity.stringForSingleKey(ForumService.ForumJsonKey.UserIdentity, andValue: userIdentity),
            BaseEntity.stringForSingleKey(ForumService.ForumJsonKey.TopicId, andValue: topicId),
            BaseEntity.stringForSingleKey(ForumService.ForumJsonKey.ExpirationTime, andValue: expirationTime),
            BaseEntity.stringForSingleKey(ForumService.ForumJsonKey.Duration, andValue: duration)
            ].filter({$0 != nil}).map({$0!})
    }
    
    func jsonData() -> NSData {
        return BaseEntity.jsonData(fieldPairArray())
    }
}
