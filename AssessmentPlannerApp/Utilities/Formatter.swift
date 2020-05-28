//
//  Formatter.swift
//  AssessmentPlannerApp
//
//  Created by Hamool Nizar on 5/12/20.
//  Copyright © 2020 Hamool Nizar. All rights reserved.
//

import Foundation

public class Formatter {
    
    /// This function will format date to "dd MMM yyyy HH:mm" format.
    ///
    /// - Parameter date: Dater.
    /// - Returns: String value of date
    public func formatDate(_ date: Date) -> String {
        let dateFormatter : DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy HH:mm"
        return dateFormatter.string(from: date)
    }
}
