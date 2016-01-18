//
//  DateToolkit.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/18/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import Foundation

struct DateToolkit {
    
    struct DateFormat {
        static let ISO8601 = "yyyy-MM-dd'T'HH:mm:ss.SZZZZZ"
    }
    
    struct Locale {
        static let EN_US_POSIX = "en_US_POSIX"
    }
    
    static var DateFormatter: NSDateFormatter {
        let dateFormatter = NSDateFormatter()
        let enUSPosixLocale = NSLocale(localeIdentifier: DateToolkit.Locale.EN_US_POSIX)
        dateFormatter.locale = enUSPosixLocale
        dateFormatter.dateFormat = DateToolkit.DateFormat.ISO8601
        return dateFormatter
    }
    
    
    static func dateFromString(string: String?) -> NSDate? {
        let dateFormatter = DateToolkit.DateFormatter
        if let string = string {
            return dateFormatter.dateFromString(string)
        } else {
            return nil
        }
    }
    
    static func timeIntervalFromAnyObject(anyObject: AnyObject?) -> NSTimeInterval? {
        return dateFromString(anyObject as? String)?.timeIntervalSince1970
    }
    
    
    
}