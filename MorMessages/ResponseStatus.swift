//
//  ResponseStatus.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/23/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import Foundation

struct Status {
    
    var code: Int = -1
    var type: String = "unspecified type"
    var details: String = "details not provided"
    
    init?(jsonData: AnyObject?) {
        if let status = jsonData?.valueForKey(ForumService.ForumJsonKey.Status) as? NSDictionary
        {
            if let statusCode = status.valueForKey(ForumService.ForumJsonKey.Code) as? Int {
                code = statusCode
            }
            if let statusType = status.valueForKey(ForumService.ForumJsonKey.Type) as? String {
                type = statusType
            }
            if let statusDetails = status.valueForKey(ForumService.ForumJsonKey.Details) as? String {
                details = statusDetails
            }
        } else {
            return nil
        }
    }
}