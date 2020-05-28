//
//  AddTaskViewController.swift
//  AssessmentPlannerApp
//
//  Created by Hamool Nizar on 5/11/20.
//  Copyright © 2020 Hamool Nizar. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import EventKit

class AddTaskViewController: UIViewController, UIPopoverPresentationControllerDelegate, UITextFieldDelegate {
    
    var tasks: [NSManagedObject] = []
    var selectedAssessment: Assessment?
    var editingMode: Bool = false
    let now = Date()
    var startDatePickerVisible = false
    var dueDatePickerVisible = false
    var taskProgressPickerVisible = false
    
    let formatter: Formatter = Formatter()
    
    @IBOutlet weak var taskNameTxtFld: UITextField!
    @IBOutlet weak var notesTxtFld: UITextField!
    @IBOutlet weak var progressLbl: UILabel!
    @IBOutlet weak var progressSlider: UISlider!
    @IBOutlet weak var startDateLbl: UILabel!
    @IBOutlet weak var startDatePicker: UIDatePicker!
    @IBOutlet weak var dueDateLbl: UILabel!
    @IBOutlet weak var dueDatePicker: UIDatePicker!
    @IBOutlet weak var addToCalendarSwitch: UISwitch!
    @IBOutlet weak var addTaskBtn: UIBarButtonItem!
    @IBOutlet weak var cancelBtn: UIBarButtonItem!
    
    
    var editingTask: Task? {
        didSet {
            // Update the view.
            editingMode = true
            configureView()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Setting the maximum for the due date as the assessment due date.
        dueDatePicker.maximumDate = selectedAssessment!.dueDate
        
        if !editingMode {
            /// Set initial start date current time.
            startDatePicker.minimumDate = now
            startDateLbl.text = formatter.formatDate(now)
            
            /// Set initial end date to one hour ahead of current time.
            var timeNow = Date()
            timeNow.addTimeInterval(TimeInterval(3600.00))
            dueDateLbl.text = formatter.formatDate(timeNow)
            dueDatePicker.minimumDate = timeNow
            
            /// Set initial progress slider value to 50%
            progressSlider.value = 0.5
            progressLbl.text = "Tast Completion Progress - 50%"
        }
        
        configureView()
        /// Disable add button
        toggleAddButtonEnability()
    }
    
    func configureView() {
        if editingMode {
            self.navigationItem.title = "Edit Task"
            self.navigationItem.rightBarButtonItem?.title = "Edit"
        }
        
        if let task = editingTask {
            if let taskName = taskNameTxtFld {
                taskName.text = task.taskName
            }
            if let notes = notesTxtFld {
                notes.text = task.notes
            }
            if let taskProgressLabel = progressLbl {
                taskProgressLabel.text = "Tast Completion Progress - \(Int(task.progress))%"
            }
            if let taskProgressSlider = progressSlider {
                taskProgressSlider.value = task.progress / 100
            }
            if let startDateLabel = startDateLbl {
                startDateLabel.text = formatter.formatDate(task.startDate as Date)
            }
            if let taskStartDatePicker = startDatePicker {
                taskStartDatePicker.date = task.startDate as Date
            }
            if let dueDateLabel = dueDateLbl {
                dueDateLabel.text = formatter.formatDate(task.dueDate as Date)
            }
            if let taskDueDatePicker = dueDatePicker {
                taskDueDatePicker.date = task.dueDate as Date
            }
            if let addToCalendar = addToCalendarSwitch {
                addToCalendar.setOn(task.addToCalendar, animated: true)
            }
        }
    }
    
    /// This function gets triggered when the start date date picker gets edited.
    /// This function will set the minimum of the due date lto one hour ahead the start date.
    ///
    /// - Parameter sender: start date UIDatePicker.
    @IBAction func startDatePickerValueChanged(_ sender: UIDatePicker) {
        
        startDateLbl.text = formatter.formatDate(sender.date)
        let dueDate = sender.date.addingTimeInterval(TimeInterval(3600.00))
        dueDatePicker.minimumDate = dueDate
        dueDateLbl.text = formatter.formatDate(dueDate)
        
    }
    
    /// This function gets triggered when the due date date picker gets edited.
    /// This function will set the maximum of the start date to one hour before the due date.
    ///
    /// - Parameter sender: due date UIDatePicker.
    @IBAction func dueDatePickerValueChanged(_ sender: UIDatePicker) {
        
        dueDateLbl.text = formatter.formatDate(sender.date)
        startDatePicker.maximumDate = sender.date.addingTimeInterval(-TimeInterval(3600.00))
        
    }
    
    /// This function close the popover view.
    ///
    /// - Parameter sender: Cancel UIBarButtonItem.
    @IBAction func cancelBtnHandler(_ sender: UIBarButtonItem) {
        
        dismissAddTaskPopOver()
    }
    
    /// This function gets triggered when the button is being clicked.
    /// Inside this function will take take all the data inserted and it will validate the values
    /// Then the function will create an task object with the data and it will be added to the task table in the coredata.
    ///
    /// - Parameter sender: Add Button.
    @IBAction func addTaskBtnHandler(_ sender: UIBarButtonItem) {
        
        if validate() {
            
            var calendarIdentifier = ""
            var addedToCalendar = false
            var eventDeleted = false
            let addToCalendarFlag = Bool(addToCalendarSwitch.isOn)
            let eventStore = EKEventStore()
            
            let taskName = taskNameTxtFld.text
            let notes = notesTxtFld.text
            let startDate = startDatePicker.date
            let dueDate = dueDatePicker.date
            let progress = Float(progressSlider.value * 100)
            
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            
            let managedContext = appDelegate.persistentContainer.viewContext
            let entity = NSEntityDescription.entity(forEntityName: "Task", in: managedContext)!
            
            var task = NSManagedObject()
            
            if editingMode {
                task = (editingTask as? Task)!
            } else {
                task = NSManagedObject(entity: entity, insertInto: managedContext)
            }
            
            if addToCalendarFlag {
                if editingMode {
                    if let task = editingTask {
                        if !task.addToCalendar {
                            if (EKEventStore.authorizationStatus(for: .event) != EKAuthorizationStatus.authorized) {
                                eventStore.requestAccess(to: .event, completion: {
                                    granted, error in
                                    calendarIdentifier = self.createEvent(eventStore, title: taskName!, startDate: startDate, endDate: dueDate)
                                })
                            } else {
                                calendarIdentifier = createEvent(eventStore, title: taskName!, startDate: startDate, endDate: dueDate)
                            }
                        }
                    }
                } else {
                    if (EKEventStore.authorizationStatus(for: .event) != EKAuthorizationStatus.authorized) {
                        eventStore.requestAccess(to: .event, completion: {
                            granted, error in
                            calendarIdentifier = self.createEvent(eventStore, title: taskName!, startDate: startDate, endDate: dueDate)
                        })
                    } else {
                        calendarIdentifier = createEvent(eventStore, title: taskName!, startDate: startDate, endDate: dueDate)
                    }
                }
                if calendarIdentifier != "" {
                    addedToCalendar = true
                }
            } else {
                if editingMode {
                    if let task = editingTask {
                        if task.addToCalendar {
                            if (EKEventStore.authorizationStatus(for: .event) != EKAuthorizationStatus.authorized) {
                                eventStore.requestAccess(to: .event, completion: { (granted, error) -> Void in
                                    eventDeleted = self.deleteEvent(eventStore, eventIdentifier: task.calendarIdentifier!)
                                })
                            } else {
                                eventDeleted = deleteEvent(eventStore, eventIdentifier: task.calendarIdentifier!)
                            }
                        }
                    }
                }
            }
            
            // Handle event creation state
            if eventDeleted {
                addedToCalendar = false
            }
            
            task.setValue(taskName, forKeyPath: "taskName")
            task.setValue(notes, forKeyPath: "notes")
            task.setValue(startDate, forKeyPath: "startDate")
            task.setValue(dueDate, forKeyPath: "dueDate")
            task.setValue(addToCalendarFlag, forKeyPath: "addToCalendar")
            task.setValue(progress, forKey: "progress")
            task.setValue(calendarIdentifier, forKey: "calendarIdentifier")
            
            print(task)
            selectedAssessment?.addToTasks((task as? Task)!)
            
            do {
                try managedContext.save()
                tasks.append(task)
            } catch _ as NSError {
                let alert = UIAlertController(title: "Error", message: "An error occured while saving the task.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        } else {
            let alert = UIAlertController(title: "Error", message: "Please fill the required fields.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        // Dismiss PopOver
        dismissAddTaskPopOver()
    }
    
    @IBAction func taskNameChange(_ sender: UITextField) {
        toggleAddButtonEnability()
    }
    
    @IBAction func notesChange(_ sender: UITextField) {
        toggleAddButtonEnability()
    }
    
    @IBAction func progressSliderChange(_ sender: UISlider) {
        let progress = Int(sender.value * 100)
        progressLbl.text = "Tast Completion Progress - \(progress)%"
    }
    
    /// This function will handle the add button enablity and disability
    func toggleAddButtonEnability() {
        if validate() {
            addTaskBtn.isEnabled = true;
        } else {
            addTaskBtn.isEnabled = false;
        }
    }
    
    /// This function is to close the popover view
    func dismissAddTaskPopOver() {
        dismiss(animated: true, completion: nil)
        popoverPresentationController?.delegate?.popoverPresentationControllerDidDismissPopover?(popoverPresentationController!)
    }
    
    /// This function will validate the textfields,  whether thery are empty or not
    ///
    /// - Returns: Boolean value of True / False
    func validate() -> Bool {
        if !(taskNameTxtFld.text?.isEmpty)! && !(notesTxtFld.text?.isEmpty)! {
            return true
        }
        return false
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
