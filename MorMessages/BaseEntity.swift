//
//  BaseEntity.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/18/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import Foundation
import CoreData
import UIKit


class BaseEntity: NSManagedObject {
    
    class func createEntity(entityName: String, withState state: [String:AnyObject],
        inManagedObjectContext context: NSManagedObjectContext = CoreDataStackManager.sharedInstance().managedObjectContext) -> BaseEntity {
        var entity: BaseEntity?
        context.performBlockAndWait {
            let newEntity = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: context) as! BaseEntity
            newEntity.applyState(state)
            if newEntity.uuid == nil || newEntity.uuid == "" {
                newEntity.uuid = NSUUID().UUIDString
            }
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
    
    class func findExistingEntity(entityName: String, withUuid uuid: AnyObject?) -> BaseEntity? {
        if let uuid = uuid as? String {
            let uuidPredicate = NSPredicate(format: "uuid = %@", uuid)
            let results = fetchEntity(entityName, usingPredicate: uuidPredicate)
            
            return (results.count > 0) ? results[0] : nil
        } else {
            return nil
        }
    }
    
    class func produceEntity(entityName: String, withState state: [String:AnyObject]?) -> BaseEntity? {
        if let state = state {
            if let entity = findExistingEntity(entityName, withUuid: state[ForumService.ForumJsonKey.Uuid]) {
                entity.applyState(state)
                CoreDataStackManager.sharedInstance().saveContext()
                return entity
            } else {
                return createEntity(entityName, withState: state)
            }
        } else {
            return nil
        }
    }
    
    func applyState(state: [String:AnyObject]) {
        //  common
        id = state[ForumService.ForumJsonKey.Id] as? NSNumber
        createdTime = ToolKit.DateKit.dateFromString(state[ForumService.ForumJsonKey.CreatedTime] as? String)
        modifiedTime = ToolKit.DateKit.dateFromString(state[ForumService.ForumJsonKey.ModifiedTime] as? String)
        createdBy = state[ForumService.ForumJsonKey.CreatedBy] as? String
        modifiedBy = state[ForumService.ForumJsonKey.ModifiedBy] as? String
        uuid = state[ForumService.ForumJsonKey.Uuid] as? String
    }
    
    func fieldPairArray() -> [String] {
        return [
            BaseEntity.stringForSingleKey(ForumService.ForumJsonKey.Id, andValue: id),
            BaseEntity.stringForSingleKey(ForumService.ForumJsonKey.CreatedTime, andValue: createdTime),
            BaseEntity.stringForSingleKey(ForumService.ForumJsonKey.ModifiedTime, andValue: modifiedTime),
            BaseEntity.stringForSingleKey(ForumService.ForumJsonKey.CreatedBy, andValue: createdBy),
            BaseEntity.stringForSingleKey(ForumService.ForumJsonKey.ModifiedBy, andValue: modifiedBy),
            BaseEntity.stringForSingleKey(ForumService.ForumJsonKey.Uuid, andValue: uuid)
        ].filter({$0 != nil}).map({$0!})
    }

    // returns a simple key : value pair suitable to be the field of a json object
    class func stringForSingleKey(key: String, andValue value: AnyObject?) -> String? {
        if let typedValue = value as? String {
            return "\"\(key)\":\(typedValue.jsonEscaped)"
        } else if let typedValue = value as? Int {
            return "\"\(key)\":\(typedValue)"
        } else if let typedValue = value as? NSDate {
            return "\"\(key)\":\(ToolKit.DateKit.DateFormatter.stringFromDate(typedValue).jsonEscaped)"
        } else {
            return nil
        }
    }
    
    func jsonData() -> NSData {
        return BaseEntity.jsonData(fieldPairArray())
    }
    
    class func jsonData(fieldPairArray: [String]) -> NSData {
        var jsonString = "{"
        var first = true
        for pair in fieldPairArray {
            jsonString += first ? pair : "," + pair
            first = false
        }
        jsonString += "}"
        return (jsonString as NSString).dataUsingEncoding(NSUTF8StringEncoding)!
    }
    
}

// MARK: Data Specific Mappings to View Items

extension BaseEntity {
    var ownerImageUrlString: String? {
        if let createdBy = self.createdBy {
            return ToolKit.produceRobohashUrlFromString(createdBy)?.absoluteString
        } else {
            return nil
        }
    }
    
    var ownerImage: UIImage? {
        
        get {
            return WebClient.Caches.imageCache.imageWithIdentifier(ownerImageUrlString)
        }
        
        set {
            if let ownerImageUrlString = ownerImageUrlString {
                WebClient.Caches.imageCache.storeImage(newValue, withIdentifier: ownerImageUrlString)
            }
        }
    }
}
