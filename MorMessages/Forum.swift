//
//  Forum.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/18/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import Foundation
import CoreData


class Forum: NSManagedObject {
    
    static let ForumEntityName = "Forum"
    
    // common
    @NSManaged var createdBy: String?
    @NSManaged var createdTime: NSTimeInterval
    @NSManaged var id: Int64
    @NSManaged var modifiedBy: String?
    @NSManaged var modifiedTime: NSTimeInterval
    // forum
    @NSManaged var title: String?
    @NSManaged var desc: String?
    @NSManaged var imageUrl: String?
    @NSManaged var messages: NSOrderedSet?

    class func createInManagedObjectContext(context: NSManagedObjectContext, state: [String:AnyObject]) -> Forum {
        var forum: Forum?
        context.performBlockAndWait {
            let newForum = NSEntityDescription.insertNewObjectForEntityForName(Forum.ForumEntityName, inManagedObjectContext: context) as! Forum
            newForum.applyState(state)
            CoreDataStackManager.sharedInstance().saveContext()
            forum = newForum
        }
        return forum!
    }
    
    class func fetchFromManagedObjectContext(context: NSManagedObjectContext, predicate: NSPredicate? = nil) -> [Forum] {
        let fetchRequest = NSFetchRequest(entityName: Forum.ForumEntityName)
        fetchRequest.predicate = predicate
        
        if let fetchResults = (try? context.executeFetchRequest(fetchRequest)) as? [Forum] {
            return fetchResults
        } else {
            Logger.error("Failed to find proper Forum array")
            return [Forum]()
        }
    }
    
    class func findExistingWithTitle(title: AnyObject?) -> Forum? {
        if let title = title as? String {
            let titlePredicate = NSPredicate(format: "title = %@", title)
            let results = fetchFromManagedObjectContext(CoreDataStackManager.sharedInstance().managedObjectContext, predicate: titlePredicate)
            
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
                return createInManagedObjectContext(CoreDataStackManager.sharedInstance().managedObjectContext, state: state)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

    func applyState(state: [String:AnyObject]) {
        //  common
        id = state[ForumService.ForumJsonKey.Id] as? Int64 ?? -1
        createdTime = DateToolkit.timeIntervalFromAnyObject(state[ForumService.ForumJsonKey.CreatedTime]) ?? NSTimeInterval()
        modifiedTime = DateToolkit.timeIntervalFromAnyObject(state[ForumService.ForumJsonKey.ModifiedTime]) ?? NSTimeInterval()
        createdBy = state[ForumService.ForumJsonKey.CreatedBy] as? String
        modifiedBy = state[ForumService.ForumJsonKey.ModifiedBy] as? String
        // forum
        title = state[ForumService.ForumJsonKey.Title] as? String
        desc = state[ForumService.ForumJsonKey.Description] as? String
        imageUrl = state[ForumService.ForumJsonKey.ImageUrl] as? String
    }
    
    func jsonData() -> NSData {
        let pairArray: [String] =  [
            (id == -1) ? nil : asKvpString(key: ForumService.ForumJsonKey.Id, value: NSNumber(longLong: id)),
            asKvpString(key: ForumService.ForumJsonKey.CreatedTime, value: DateToolkit.stringFromTimeInterval(createdTime)),
            asKvpString(key: ForumService.ForumJsonKey.ModifiedTime, value: DateToolkit.stringFromTimeInterval(modifiedTime)),
            asKvpString(key: ForumService.ForumJsonKey.CreatedBy, value: createdBy),
            asKvpString(key: ForumService.ForumJsonKey.ModifiedBy, value: modifiedBy),
            asKvpString(key: ForumService.ForumJsonKey.Title, value: title),
            asKvpString(key: ForumService.ForumJsonKey.Description, value: desc),
            asKvpString(key: ForumService.ForumJsonKey.ImageUrl, value: imageUrl)
            ].filter({$0 != nil}).map({$0!})
        
        var jsonString = "{"
        var first = true
        for pair in pairArray {
            jsonString += first ? pair : "," + pair
            first = false
        }
        jsonString += "}"
        Logger.info("JSON STRING: \(jsonString)")
        return (jsonString as NSString).dataUsingEncoding(NSUTF8StringEncoding)!
    }
    
    func asKvpString(key key: String, value: AnyObject?) -> String? {
        if let typedValue = value as? String {
            return "\"\(key)\":\"\(typedValue)\""
        } else if let typedValue = value as? Int {
            return "\"\(key)\":\(typedValue)"
        } else {
            return nil
        }
    }

}
