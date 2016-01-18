//
//  Message+CoreDataProperties.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/17/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Message {

    @NSManaged var id: Int64
    @NSManaged var createdTime: NSTimeInterval
    @NSManaged var modifiedTime: NSTimeInterval
    @NSManaged var createdBy: String?
    @NSManaged var modifiedBy: String?
    @NSManaged var text: String?
    @NSManaged var imageUrl: String?
    @NSManaged var forum: Forum?

}
