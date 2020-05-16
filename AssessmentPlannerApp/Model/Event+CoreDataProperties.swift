//
//  Event+CoreDataProperties.swift
//  AssessmentPlannerApp
//
//  Created by Hamool Nizar on 5/13/20.
//  Copyright © 2020 Hamool Nizar. All rights reserved.
//
//

import Foundation
import CoreData


extension Event {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Event> {
        return NSFetchRequest<Event>(entityName: "Event")
    }

    @NSManaged public var timestamp: Date?

}
