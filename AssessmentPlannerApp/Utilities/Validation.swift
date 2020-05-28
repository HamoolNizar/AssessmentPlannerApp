//
//  Validation.swift
//  AssessmentPlannerApp
//
//  Created by Hamool Nizar on 5/17/20.
//  Copyright © 2020 Hamool Nizar. All rights reserved.
//

import Foundation

class Validation {
    
    /// This function will validate the value whether its between 0 to 100
    ///
    /// - Parameter text: String.
    /// - Returns: Boolean value of True/False
    public func validateCentury(text: String) ->Bool {
        let value = Int(text)
        if (value! >= 0 && value! < 100) {
            return true
        } else {
            return false
        }
    }
}
