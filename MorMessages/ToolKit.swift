//
//  ToolKit.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/23/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import Foundation
import UIKit

class ToolKit {
    
    // informs user of error status
    static func showErrorAlert(viewController viewController: UIViewController, title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default) {
            action -> Void in
            // nothing to do
            })
        dispatch_async(dispatch_get_main_queue()) {
            viewController.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    // try to manipulate the given string into a valid URL, or return nil if it can't be done.
    static func produceValidUrlFromString(string: String) -> NSURL? {
        let stringWithScheme = string
        let url = NSURL(string: stringWithScheme)
        if let url = url,
            hostname = url.host
            where !hostname.isEmpty
                &&  (url.scheme.lowercaseString == WebClient.HttpScheme
                    || url.scheme.lowercaseString == WebClient.HttpsScheme) {
                    return url
        } else {
            return nil
        }
    }
    
    // turn the search text into a Bing search query URL
    static func produceBingUrlFromSearchString(searchString: String) -> NSURL? {
        let bingUrlString = "https://www.bing.com/search"
        let encodedSearch = WebClient.encodeParameters(["q":searchString])
        let queryString = encodedSearch.stringByReplacingOccurrencesOfString("%20", withString: "+")
        return NSURL(string: "\(bingUrlString)?\(queryString)")
    }
    
    // turn the search text into a Bing search query URL
    static func produceGoogleImageUrlFromSearchString(searchString: String) -> NSURL? {
        let bingUrlString = "https://www.google.com/search"
        let encodedSearch = WebClient.encodeParameters([
            "site":"",
            "tbm":"isch",
            "source":"hp",
            "q":searchString,
            "oq":searchString])
        let queryString = encodedSearch.stringByReplacingOccurrencesOfString("%20", withString: "+")
        return NSURL(string: "\(bingUrlString)?\(queryString)")
    }

    // use the md5 hash of the input string to produce a robohash
    static func produceRobohashUrlFromString(string: String) -> NSURL? {
        return NSURL(string: "https://robohash.org/\(string.md5)")
    }

    // use the md5 hash of the input string to produce a gravatar random image
    // category descriptions from gravatar website
    // identicon: a geometric pattern based on an email hash
    // monsterid: a generated 'monster' with different colors, faces, etc
    // wavatar: generated faces with differing features and backgrounds
    // retro: awesome generated, 8-bit arcade-style pixelated faces
    static let GravatarCategories = [ "identicon", "monsterid", "wavatar", "retro" ]
    static func produceGravatarImageUrlFromString(string: String, withFallback: String? = nil) -> NSURL? {
        var fallback = withFallback
        if fallback == nil {
            let index = Int(arc4random_uniform(UInt32(GravatarCategories.count)))
            fallback = GravatarCategories[index]
        }
        return NSURL(string: "https://secure.gravatar.com/avatar/\(string.md5)?d=\(fallback!)")
    }
    
    struct DateKit {
        
        static let Epoch = NSDate(timeIntervalSince1970: 0)
        
        struct DateFormat {
            static let ISO8601 = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        }

        struct Locale {
            static let EN_US_POSIX = "en_US_POSIX"
        }

        static var DateFormatter: NSDateFormatter {
            let dateFormatter = NSDateFormatter()
            let enUSPosixLocale = NSLocale(localeIdentifier: Locale.EN_US_POSIX)
            dateFormatter.locale = enUSPosixLocale
            dateFormatter.dateFormat = DateFormat.ISO8601
            return dateFormatter
        }

        // parse the string into a data object
        static func dateFromString(string: String?) -> NSDate? {
            if let string = string {
                return DateFormatter.dateFromString(string)
            } else {
                return nil
            }
        }
    }
    
}

// extend String with a property to get its md5 hash
//
// Thank you StackOverflow!
// http://stackoverflow.com/questions/24123518/how-to-use-cc-md5-method-in-swift-language
//
extension String  {
    var md5: String! {
        let str = self.cStringUsingEncoding(NSUTF8StringEncoding)
        let strLen = CC_LONG(self.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLen)
        
        CC_MD5(str!, strLen, result)
        
        let hash = NSMutableString()
        for i in 0..<digestLen {
            hash.appendFormat("%02x", result[i])
        }
        
        result.dealloc(digestLen)
        
        return String(format: hash as String)
    }
    
    var jsonEscaped: String! {
        let value = self
            .stringByReplacingOccurrencesOfString("\\", withString: "\\\\")
            .stringByReplacingOccurrencesOfString("\n", withString: "\\n")
            .stringByReplacingOccurrencesOfString("\r", withString: "\\r")
            .stringByReplacingOccurrencesOfString("\"", withString: "\\\"")
        return "\"\(value)\""
    }
    
    var jsonUnescaped: String! {
        let value = self.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "\""))
        return value
            .stringByReplacingOccurrencesOfString("\\\"", withString: "\"")
            .stringByReplacingOccurrencesOfString("\\r", withString: "\r")
            .stringByReplacingOccurrencesOfString("\\n", withString: "\n")
            .stringByReplacingOccurrencesOfString("\\\\", withString: "\\")
    }
}