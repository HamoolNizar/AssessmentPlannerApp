//
//  AddAssessmentViewController.swift
//  AssessmentPlannerApp
//
//  Created by Hamool Nizar on 5/11/20.
//  Copyright © 2020 Hamool Nizar. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import EventKit

class AddAssessmentViewController: UIViewController, UIPopoverPresentationControllerDelegate, UITextFieldDelegate {
    
    var assessments: [NSManagedObject] = []
    var datePickerVisible = false
    var editingMode: Bool = false
    let now = Date();
    
    let formatter: Formatter = Formatter()
    let validation: Validation = Validation()
    
    @IBOutlet weak var moduleNameTxtFld: UITextField!
    @IBOutlet weak var assessmentNameTxtFld: UITextField!
    @IBOutlet weak var levelSegementedControl: UISegmentedControl!
    @IBOutlet weak var valueTxtFld: UITextField!
    @IBOutlet weak var markTxtFld: UITextField!
    @IBOutlet weak var dueDatePicker: UIDatePicker!
    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var notesTxtFld: UITextField!
    @IBOutlet weak var addToCalendarSwitch: UISwitch!
    @IBOutlet weak var addAssessmentBtn: UIBarButtonItem!
    
    var editingAssessment: Assessment? {
        didSet {
            // Update the view.
            editingMode = true
            configureView()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dueDatePicker.minimumDate = now
        
        if !editingMode {
            /// Set initial end date to one hour ahead of current time
            var time = Date()
            time.addTimeInterval(TimeInterval(3600.00))
            dueDateLabel.text = formatter.formatDate(time)
            
            valueTxtFld.delegate = self
            markTxtFld.delegate = self
            
        }
        
        configureView()
        /// Disable add button
        toggleAddButtonEnability()
    }
    
    func configureView() {
        if editingMode {
            self.navigationItem.title = "Edit Assessment"
            self.navigationItem.rightBarButtonItem?.title = "Edit"
        }
        
        if let assessment = editingAssessment {
            if let moduleName = moduleNameTxtFld {
                moduleName.text = editingAssessment?.moduleName
            }
            if let assesstmentName = assessmentNameTxtFld {
                assesstmentName.text = editingAssessment?.assesstmentName
            }
            if let level = levelSegementedControl {
                level.selectedSegmentIndex = getEditingLevel(segmentIndex: editingAssessment?.level ?? "0")
            }
            if let value = valueTxtFld {
                value.text = editingAssessment?.value
            }
            if let mark = markTxtFld {
                mark.text = editingAssessment?.mark
            }
            if let dueDate = dueDateLabel {
                dueDate.text = formatter.formatDate(editingAssessment?.dueDate as! Date)
            }
            if let dueDatePicker = dueDatePicker {
                dueDatePicker.date = editingAssessment?.dueDate as! Date
            }
            if let notes = notesTxtFld {
                notes.text = editingAssessment?.notes
            }
            if let addToCalendar = addToCalendarSwitch {
                addToCalendar.setOn((editingAssessment?.addToCalendar)!, animated: true)
            }
        }
    }
    
    /// This function gets triggered when the date picker gets edited.
    /// This function will set the due date label according to the date picker.
    ///
    /// - Parameter sender: due date UIDatePicker.
    @IBAction func dueDatePickerValueChanged(_ sender: UIDatePicker) {
        dueDateLabel.text = formatter.formatDate(sender.date)
    }
    
    /// This function close the popover view.
    ///
    /// - Parameter sender: Cancel UIBarButtonItem.
    @IBAction func cancelBtnHandler(_ sender: UIBarButtonItem) {
        dismissAddAssessmentPopOver()
    }
    
    /// This function gets triggered when the button is being clicked.
    /// Inside this function will take take all the data inserted and it will validate the values
    /// Then the function will create an assesment object with the data and it will be added to the assesment table in the coredata.
    ///
    /// - Parameter sender: Add Button.
    @IBAction func addBtnHandler(_ sender: Any) {
        
        if validateTextField() {
            if validateTxtFldValues() {
                var calendarIdentifier = ""
                var addedToCalendar = false
                var eventDeleted = false
                let addToCalendarFlag = Bool(addToCalendarSwitch.isOn)
                let eventStore = EKEventStore()
                
                let moduleName = moduleNameTxtFld.text
                let assessmentName = assessmentNameTxtFld.text
                let level = getLevel(segmentIndex: levelSegementedControl.selectedSegmentIndex)
                let value = valueTxtFld.text
                let mark = markTxtFld.text
                let dueDate = dueDatePicker.date
                let notes = notesTxtFld.text
                
                
                guard let appDelegate =
                    UIApplication.shared.delegate as? AppDelegate else {
                        return
                }
                
                let managedContext = appDelegate.persistentContainer.viewContext
                let entity = NSEntityDescription.entity(forEntityName: "Assessment", in: managedContext)!
                
                var assessment = NSManagedObject()
                
                if editingMode {
                    assessment = (editingAssessment as? Assessment)!
                } else {
                    assessment = NSManagedObject(entity: entity, insertInto: managedContext)
                }
                
                if addToCalendarFlag {
                    if editingMode {
                        if let assessment = editingAssessment {
                            if !assessment.addToCalendar {
                                if (EKEventStore.authorizationStatus(for: .event) != EKAuthorizationStatus.authorized) {
                                    eventStore.requestAccess(to: .event, completion: {
                                        granted, error in
                                        calendarIdentifier = self.createEvent(eventStore, title: assessmentName!, startDate: self.now, endDate: dueDate)
                                    })
                                } else {
                                    calendarIdentifier = createEvent(eventStore, title: assessmentName!, startDate: now, endDate: dueDate)
                                }
                            }
                        }
                    } else {
                        if (EKEventStore.authorizationStatus(for: .event) != EKAuthorizationStatus.authorized) {
                            eventStore.requestAccess(to: .event, completion: {
                                granted, error in
                                calendarIdentifier = self.createEvent(eventStore, title: assessmentName!, startDate: self.now, endDate: dueDate)
                            })
                        } else {
                            calendarIdentifier = createEvent(eventStore, title: assessmentName!, startDate: now, endDate: dueDate)
                        }
                    }
                    if calendarIdentifier != "" {
                        addedToCalendar = true
                    }
                } else {
                    if editingMode {
                        if let assessment = editingAssessment {
                            if assessment.addToCalendar {
                                if (EKEventStore.authorizationStatus(for: .event) != EKAuthorizationStatus.authorized) {
                                    eventStore.requestAccess(to: .event, completion: { (granted, error) -> Void in
                                        eventDeleted = self.deleteEvent(eventStore, eventIdentifier: assessment.calendarIdentifier!)
                                    })
                                } else {
                                    eventDeleted = deleteEvent(eventStore, eventIdentifier: assessment.calendarIdentifier!)
                                }
                            }
                        }
                    }
                }
                
                // Handle event creation state
                if eventDeleted {
                    addedToCalendar = false
                }
                
                assessment.setValue(moduleName, forKeyPath: "moduleName")
                assessment.setValue(assessmentName, forKeyPath: "assesstmentName")
                assessment.setValue(level, forKeyPath: "level")
                assessment.setValue(value, forKeyPath: "value")
                assessment.setValue(mark, forKeyPath: "mark")
                assessment.setValue(notes, forKeyPath: "notes")
                
                if editingMode {
                    assessment.setValue(editingAssessment?.startDate, forKeyPath: "startDate")
                } else {
                    assessment.setValue(now, forKeyPath: "startDate")
                }
                
                assessment.setValue(dueDate, forKeyPath: "dueDate")
                assessment.setValue(addedToCalendar, forKeyPath: "addToCalendar")
                assessment.setValue(calendarIdentifier, forKey: "calendarIdentifier")
                
                print(assessment)
                
                do {
                    try managedContext.save()
                    assessments.append(assessment)
                } catch _ as NSError {
                    let alert = UIAlertController(title: "Error", message: "An error occured while saving the assessment.", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            } else {
                let alert = UIAlertController(title: "Error", message: "The Contribution Value and Awarded Mark should be between 0 to 100.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        } else {
            let alert = UIAlertController(title: "Error", message: "Please fill the required fields.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        // Dismiss PopOver
        dismissAddAssessmentPopOver()
        
        
    }
    
    /// This function gets the segement index from the segmented control and returns the the appropriate level.
    ///
    /// - Parameter segmentIndex: Int value of the segment index.
    /// - Returns: String value for the level
    func getLevel(segmentIndex: Int) -> String {
        var lvl = "3"
        switch segmentIndex {
        case 1:
            lvl = "4"
            return lvl
        case 2:
            lvl = "5"
            return lvl
        case 3:
            lvl = "6"
            return lvl
        case 4:
            lvl = "7"
            return lvl
        default:
            lvl = "3"
            return lvl
        }
    }
    
    /// This function gets the segement index from the assesment table in the coredata and returns the the appropriate level.
    ///
    /// - Parameter segmentIndex: String value of the segment index.
    /// - Returns: Int value for the level
    func getEditingLevel(segmentIndex: String) -> Int {
        var lvl = 0
        switch Int(segmentIndex) {
        case 4:
            lvl = 1
            return lvl
        case 5:
            lvl = 2
            return lvl
        case 6:
            lvl = 3
            return lvl
        case 7:
            lvl = 4
            return lvl
        default:
            lvl = 0
            return lvl
        }
    }
    
    @IBAction func moduleNameChange(_ sender: UITextField) {
        toggleAddButtonEnability()
    }
    
    @IBAction func assessmentNameChange(_ sender: UITextField) {
        toggleAddButtonEnability()
    }
    
    @IBAction func levelChange(_ sender: UISegmentedControl) {
        toggleAddButtonEnability()
    }
    
    @IBAction func valueChange(_ sender: UITextField) {
        toggleAddButtonEnability()
    }
    
    @IBAction func markChange(_ sender: UITextField) {
        toggleAddButtonEnability()
    }
    
    @IBAction func notesChange(_ sender: UITextField) {
        toggleAddButtonEnability()
    }
    
    
    /// This function will handle the add button enablity and disability
    func toggleAddButtonEnability() {
        if validateTextField() {
            addAssessmentBtn.isEnabled = true;
        } else {
            addAssessmentBtn.isEnabled = false;
        }
    }
    
    /// This function is to close the popover view
    func dismissAddAssessmentPopOver() {
        dismiss(animated: true, completion: nil)
        popoverPresentationController?.delegate?.popoverPresentationControllerDidDismissPopover?(popoverPresentationController!)
    }
    
    /// This function will validate the textfields,  whether thery are empty or not
    ///
    /// - Returns: Boolean value of True / False
    func validateTextField() -> Bool {
        if !(moduleNameTxtFld.text?.isEmpty)! && !(assessmentNameTxtFld.text?.isEmpty)! && !(valueTxtFld.text?.isEmpty)! && !(markTxtFld.text?.isEmpty)! && !(notesTxtFld.text?.isEmpty)! {
            return true
        }
        return false
    }
    
    /// This function will validate the textfields,  whether they are between 0 to 100
    ///
    /// - Returns: Boolean value True / False
    func validateTxtFldValues() -> Bool {
        if (validation.validateCentury(text: valueTxtFld.text!)) && (validation.validateCentury(text: markTxtFld.text!))  {
            return true
        }
        return false
    }
    
    /// This function gets the textfield and limit the input for the textfield for only numeric values.
    ///
    /// - Parameter textField: TextField.
    /// - Parameter range: NSRange.
    /// - Parameter string: Replacement string value.
    /// - Returns: Boolean value True / False
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
       if (textField == valueTxtFld || textField == markTxtFld) {
           let allowedCharacters = CharacterSet(charactersIn:"0123456789 ")//Numeric characters Only
           let characterSet = CharacterSet(charactersIn: string)
           return allowedCharacters.isSuperset(of: characterSet)
       }
       return true
    }
    
    /// This function will create an event in the calendar application of the device with the Assessment title, start data and end date.
    ///
    /// - Parameter eventStore: EKEventStore.
    /// - Parameter title: String.
    /// - Parameter startDate: Date.
    /// - Parameter endDate: Date .
    /// - Returns: String value for the  event identifier
    func createEvent(_ eventStore: EKEventStore, title: String, startDate: Date, endDate: Date) -> String {
        let event = EKEvent(eventStore: eventStore)
        var identifier = ""
        
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(event, span: .thisEvent)
            identifier = event.eventIdentifier
        } catch {
            let alert = UIAlertController(title: "Error", message: "Calendar event could not be created!", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        return identifier
    }
    
    /// This function will delete an event in the calendar application of the device using the event identifier.
    ///
    /// - Parameter eventStore: EKEventStore.
    /// - Parameter eventIdentifier: String value of the event Identifier.
    /// - Returns: Boolean value of True/False
    func deleteEvent(_ eventStore: EKEventStore, eventIdentifier: String) -> Bool {
        var success = false
        let eventToRemove = eventStore.event(withIdentifier: eventIdentifier)
        if eventToRemove != nil {
            do {
                try eventStore.remove(eventToRemove!, span: .thisEvent)
                success = true
            } catch {
                let alert = UIAlertController(title: "Error", message: "Calendar event could not be deleted!", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                success = false
            }
        }
        return success
    }
    
}
