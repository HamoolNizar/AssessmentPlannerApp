//
//  AssessmentTableViewCell.swift
//  AssessmentPlannerApp
//
//  Created by Hamool Nizar on 5/12/20.
//  Copyright © 2020 Hamool Nizar. All rights reserved.
//

import UIKit

class AssessmentTableViewCell: UITableViewCell {
    
    var cellDelegate: AssessmentTableViewCellDelegate?
    var notes: String = "Not Available"
    
    @IBOutlet weak var moduleNameLabel: UILabel!
    @IBOutlet weak var assessmentNameLabel: UILabel!
    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var assessmentStatusView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    
    func commonInit(moduleName: String, assessmentName: String, assessmentStatus: UIColor, taskProgress: CGFloat, dueDate: Date, notes: String) {
//        var iconName = "ic-flag-green"
//        if priority == "Low" {
//            iconName = "ic-flag-green"
//        } else if priority == "Medium" {
//            iconName = "ic-flag-blue"
//        } else if priority == "High" {
//            iconName = "ic-flag-red"
//        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy HH:mm"
        
//        priorityIcon.image = UIImage(named: iconName)
        moduleNameLabel.text = moduleName
        assessmentNameLabel.text = assessmentName
        assessmentStatusView.backgroundColor = assessmentStatus
        dueDateLabel.text = "Due: \(formatter.string(from: dueDate))"
        self.notes = notes
    }
}

protocol AssessmentTableViewCellDelegate {
    func customCell(cell: AssessmentTableViewCell, sender button: UIButton, data data: String)
}
