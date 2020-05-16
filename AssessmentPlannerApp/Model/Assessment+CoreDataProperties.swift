//
//  Assessment+CoreDataProperties.swift
//  AssessmentPlannerApp
//
//  Created by Hamool Nizar on 5/13/20.
//  Copyright © 2020 Hamool Nizar. All rights reserved.
//
//

import Foundation
import CoreData


extension Assessment {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Assessment> {
        return NSFetchRequest<Assessment>(entityName: "Assessment")
    }

    @NSManaged public var addToCalendar: Bool
    @NSManaged public var assesstmentName: String
    @NSManaged public var calendarIdentifier: String?
    @NSManaged public var dueDate: Date
    @NSManaged public var level: String
    @NSManaged public var mark: String
    @NSManaged public var moduleName: String
    @NSManaged public var notes: String
    @NSManaged public var startDate: Date
    @NSManaged public var value: String
    @NSManaged public var tasks: NSSet?

}

// MARK: Generated accessors for tasks
extension Assessment {

    @objc(addTasksObject:)
    @NSManaged public func addToTasks(_ value: Task)

    @objc(removeTasksObject:)
    @NSManaged public func removeFromTasks(_ value: Task)

    @objc(addTasks:)
    @NSManaged public func addToTasks(_ values: NSSet)

    @objc(removeTasks:)
    @NSManaged public func removeFromTasks(_ values: NSSet)

}
