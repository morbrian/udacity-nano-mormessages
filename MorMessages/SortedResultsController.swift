//
//  SortedResultsController.swift
//  MorMessages
//
//  Created by Brian Moriarty on 2/15/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class SortedResultsController<T: BaseEntity> {
    
    // fetch controllers
    var fetchOffset = 0
    let ResultSize = 100
    let PreFetchTrigger = 50
    
    let entityName: String
    let ascending: Bool
    let predicate: NSPredicate?
    
    var context: NSManagedObjectContext!
    
    var pagedRequestDelegate: PageRequestDelegate?
    var delegate: NSFetchedResultsControllerDelegate? {
        didSet {
            fetchedResultsController.delegate = delegate
        }
    }
    
    init(entityName: String, ascending: Bool = true, predicate: NSPredicate? = nil, context: NSManagedObjectContext? = nil) {
        self.entityName = entityName
        self.ascending = ascending
        self.predicate = predicate
        if context != nil {
            self.context = context
        } else {
            self.context = CoreDataStackManager.sharedInstance().managedObjectContext
        }
    }
    
    // Mark: - Fetched Results Controller
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        // Create the fetch request
        let fetchRequest = NSFetchRequest(entityName: self.entityName)
        
        // Add a sort descriptor. This enforces a sort order on the results that are generated
        // In this case we want the events sored by id.
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "modifiedTime", ascending: self.ascending)]
        fetchRequest.predicate = self.predicate
        
        // Create the Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.context, sectionNameKeyPath: nil, cacheName: nil)
        
        // Return the fetched results controller. It will be the value of the lazy variable
        return fetchedResultsController
    } ()
    
    func performFetch() {
        do {
            try fetchedResultsController.performFetch()
        } catch _ {
            Logger.error("fetchedResultsController fetch failed")
        }
    }
    
    func objectAtIndexPath(indexPath: NSIndexPath) -> T {
        return fetchedResultsController.objectAtIndexPath(indexPath) as! T
    }
    
    // similar to "Newest" but not constrained by already downloaded dates
    func fetchRecent(completionHandler: (() -> Void)? = nil) {
        fetchWithOffset(0, greaterThan: ToolKit.DateKit.Epoch, completionHandler: completionHandler)
    }
    
    func fetchNewest(completionHandler: (() -> Void)? = nil) {
        let greaterThan = storedRange().newest
        fetchWithOffset(0, greaterThan: greaterThan, completionHandler: completionHandler)
    }
    
    func fetchOlder(completionHandler: (() -> Void)? = nil) {
        fetchWithOffset(fetchOffset, greaterThan: ToolKit.DateKit.Epoch, completionHandler: completionHandler)
    }
    
    
    func preFetchConditionFulfilledByIndex(index: Int) -> Bool {
        return (index == itemCount() - PreFetchTrigger)
    }

    func numberOfObjectsInSection(section: Int) -> Int {
        // if sections is nil here, it's probable programmer error, did you remember to call performFetch() ??
        return self.fetchedResultsController.sections![section].numberOfObjects
    }
    
    func fetchWithOffset(fetchOffset: Int, greaterThan: NSDate, completionHandler: (() -> Void)? = nil) {
        let beforeCount = itemCount()
        networkActivity(true)
        pagedRequestDelegate?.pagedItems(offset: fetchOffset, resultSize: ResultSize, greaterThan: greaterThan) {
            dispatch_async(dispatch_get_main_queue()) {
                self.networkActivity(false)
                let afterCount = self.itemCount()
                self.fetchOffset += afterCount - beforeCount
                
                Logger.info("before(\(beforeCount)), after(\(afterCount))")
                completionHandler?()
            }
        }
    }
    
    func networkActivity(active: Bool, intrusive: Bool = true) {
        dispatch_async(dispatch_get_main_queue()) {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = active
        }
    }
    
    func itemCount() -> Int {
        if let sections = self.fetchedResultsController.sections
            where sections.count == 1 {
                return sections[0].numberOfObjects
        }
        return 0
    }
    
    // return the first and last items that we already downloaded
    func storedRange() -> (oldest: NSDate, newest: NSDate) {
        var oldest = ToolKit.DateKit.Epoch
        var newest = ToolKit.DateKit.Epoch
        if let sections = self.fetchedResultsController.sections
            where sections.count == 1 {
                let section = sections[0]
                if section.numberOfObjects > 0 {
                    if let objects = section.objects,
                        first = objects[0] as? T,
                        last = objects[section.numberOfObjects - 1] as? T,
                        firstId = last.modifiedTime,
                        lastId = first.modifiedTime {
                            oldest = ascending ? lastId : firstId
                            newest = ascending ? firstId : lastId
                    }
                }
        }
        return (oldest, newest)
    }

}