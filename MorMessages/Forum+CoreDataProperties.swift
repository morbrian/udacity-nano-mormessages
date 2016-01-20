//
//  Forum+CoreDataProperties.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/19/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Forum {

    @NSManaged var title: String?
    @NSManaged var desc: String?
    @NSManaged var imageUrl: String?
    @NSManaged var messages: [Message]

}
