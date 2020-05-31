//
//  Calculations.swift
//  AssessmentPlannerApp
//
//  Created by Hamool Nizar on 5/12/20.
//  Copyright © 2020 Hamool Nizar. All rights reserved.
//

import Foundation

public class Calculations {
    let now = Date()
    
    /// This function will calculate the difference between two dates.
    ///
    /// - Parameter start: Date.
    /// - Parameter end: Date.
    /// - Returns: Int value of date difference
    public func getDateDiff(_ start: Date, end: Date) -> Int {
        let currentCalendar = Calendar.current
        guard let start = currentCalendar.ordinality(of: .day, in: .era, for: start) else {
            return 0
        }
        guard let end = currentCalendar.ordinality(of: .day, in: .era, for: end) else {
            return 0
        }
        return end - start
    }
    
    /// This function will calculate the percentage for the remaining time.
    ///
    /// - Parameter start: Date.
    /// - Parameter end: Date.
    /// - Returns: Int value of percentage
    public func getRemainingTimePercentage(_ start: Date, end: Date) -> Int {
        let elapsed = getTimeDiffInSeconds(start, end: end)
        let remaining = getTimeDiffInSeconds(now, end: end)
        
        var percentage = 100
        
        if elapsed > 0 {
            percentage = 100 - Int(100 - ((remaining / elapsed) * 100))
        }
        
        return percentage
    }
    
    /// This function will calculate the difference between two dates retruns the difference in seconds.
    ///
    /// - Parameter start: Date.
    /// - Parameter end: Date.
    /// - Returns: Double value of date difference
    public func getTimeDiffInSeconds(_ start: Date, end: Date) -> Double {
        let difference: TimeInterval? = end.timeIntervalSince(start)

        if Double(difference!) < 0 {
            return 0
        }
        
        return Double(difference!)
    }
    
    /// This function will calculate the difference between two dates and returns days, hours and minutes separately.
    ///
    /// - Parameter start: Date.
    /// - Parameter end: Date.
    /// - Returns: Int value of difference in days, Int value of difference in hours, Int value of difference in minutes,
    public func getTimeDiff(_ start: Date, end: Date) -> (Int, Int, Int) {
        let difference: TimeInterval? = end.timeIntervalSince(start)
        
        let secondsInAnHour: Double = 3600
        let secondsInADay: Double = 86400
        let secondsInAMinute: Double = 60
        
        let diffInDays = Int((difference! / secondsInADay))
        let diffInHours = Int((difference! / secondsInAnHour))
        let diffInMinutes = Int((difference! / secondsInAMinute))
        
        var daysLeft = diffInDays
        var hoursLeft = diffInHours - (diffInDays * 24)
        var minutesLeft = diffInMinutes - (diffInHours * 60)
        
        if daysLeft < 0 {
            daysLeft = 0
        }
        
        if hoursLeft < 0 {
            hoursLeft = 0
        }
        
        if minutesLeft < 0 {
            minutesLeft = 0
        }
        
        return (daysLeft, hoursLeft, minutesLeft)
    }
    
    /// This function will calculate the percentage the assessment progress.
    ///
    /// - Parameter tasks: Tasks.
    /// - Returns: Int value of progress percentage
    public func getProjectProgress(_ tasks: [Task]) -> Int {
        var progressTotal: Float = 0
        var progress: Int = 0

        if tasks.count > 0 {
            for task in tasks {
                progressTotal += task.progress
            }
            progress = Int(progressTotal) / tasks.count
        }

        return progress
    }
}

