//
//  BaseEntity.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/18/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import Foundation
import CoreData


class BaseEntity: NSManagedObject {
    
    class func createEntity(entityName: String, withState state: [String:AnyObject],
        inManagedObjectContext context: NSManagedObjectContext = CoreDataStackManager.sharedInstance().managedObjectContext) -> BaseEntity {
        var entity: BaseEntity?
        context.performBlockAndWait {
            let newEntity = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: context) as! BaseEntity
            newEntity.applyState(state)
            CoreDataStackManager.sharedInstance().saveContext()
            entity = newEntity
        }
        return entity!
    }
    
    class func fetchEntity(entityName: String, usingPredicate predicate: NSPredicate? = nil,
        fromManagedObjectContext context: NSManagedObjectContext = CoreDataStackManager.sharedInstance().managedObjectContext) -> [BaseEntity] {
        let fetchRequest = NSFetchRequest(entityName: entityName)
        fetchRequest.predicate = predicate
        
        if let fetchResults = (try? context.executeFetchRequest(fetchRequest)) as? [BaseEntity] {
            return fetchResults
        } else {
            Logger.error("Failed to find proper entity array")
            return [BaseEntity]()
        }
    }
    
    func applyState(state: [String:AnyObject]) {
        //  common
        id = state[ForumService.ForumJsonKey.Id] as? Int64 ?? -1
        createdTime = DateToolkit.timeIntervalFromAnyObject(state[ForumService.ForumJsonKey.CreatedTime]) ?? NSTimeInterval()
        modifiedTime = DateToolkit.timeIntervalFromAnyObject(state[ForumService.ForumJsonKey.ModifiedTime]) ?? NSTimeInterval()
        createdBy = state[ForumService.ForumJsonKey.CreatedBy] as? String
        modifiedBy = state[ForumService.ForumJsonKey.ModifiedBy] as? String
    }
    
    func fieldPairArray() -> [String] {
        return [
            (id == -1) ? nil : stringForSingleKey(ForumService.ForumJsonKey.Id, andValue: NSNumber(longLong: id)),
            stringForSingleKey(ForumService.ForumJsonKey.CreatedTime, andValue: DateToolkit.stringFromTimeInterval(createdTime)),
            stringForSingleKey(ForumService.ForumJsonKey.ModifiedTime, andValue: DateToolkit.stringFromTimeInterval(modifiedTime)),
            stringForSingleKey(ForumService.ForumJsonKey.CreatedBy, andValue: createdBy),
            stringForSingleKey(ForumService.ForumJsonKey.ModifiedBy, andValue: modifiedBy),
        ].filter({$0 != nil}).map({$0!})
    }

    // returns a simple key : value pair suitable to be the field of a json object
    func stringForSingleKey(key: String, andValue value: AnyObject?) -> String? {
        if let typedValue = value as? String {
            return "\"\(key)\":\"\(typedValue)\""
        } else if let typedValue = value as? Int {
            return "\"\(key)\":\(typedValue)"
        } else {
            return nil
        }
    }
    
    
    func jsonData() -> NSData {
        var jsonString = "{"
        var first = true
        for pair in fieldPairArray() {
            jsonString += first ? pair : "," + pair
            first = false
        }
        jsonString += "}"
        Logger.info("JSON STRING: \(jsonString)")
        return (jsonString as NSString).dataUsingEncoding(NSUTF8StringEncoding)!
    }

}
