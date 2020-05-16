//
//  Formatter.swift
//  AssessmentPlannerApp
//
//  Created by Hamool Nizar on 5/12/20.
//  Copyright © 2020 Hamool Nizar. All rights reserved.
//

import Foundation

public class Formatter {
    
    // Format date to "dd MMM yyyy HH:mm"
    
    public func formatDate(_ date: Date) -> String {
        let dateFormatter : DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy HH:mm"
        return dateFormatter.string(from: date)
    }
}
