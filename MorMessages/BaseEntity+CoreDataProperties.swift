//
//  BaseEntity+CoreDataProperties.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/18/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension BaseEntity {

    @NSManaged var createdBy: String?
    @NSManaged var createdTime: NSTimeInterval
    @NSManaged var id: Int64
    @NSManaged var modifiedBy: String?
    @NSManaged var modifiedTime: NSTimeInterval
    @NSManaged var uuid: String?

}
