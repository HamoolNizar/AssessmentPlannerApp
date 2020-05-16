//
//  Task+CoreDataProperties.swift
//  AssessmentPlannerApp
//
//  Created by Hamool Nizar on 5/13/20.
//  Copyright © 2020 Hamool Nizar. All rights reserved.
//
//

import Foundation
import CoreData


extension Task {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Task> {
        return NSFetchRequest<Task>(entityName: "Task")
    }

    @NSManaged public var addToCalendar: Bool
    @NSManaged public var calendarIdentifier: String?
    @NSManaged public var dueDate: Date
    @NSManaged public var notes: String
    @NSManaged public var progress: Float
    @NSManaged public var startDate: Date
    @NSManaged public var taskName: String
    @NSManaged public var assessment: Assessment?

}
