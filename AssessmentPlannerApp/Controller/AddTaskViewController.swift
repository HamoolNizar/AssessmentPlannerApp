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
        
        // set end date picker maximum date to project end date
        dueDatePicker.maximumDate = selectedAssessment!.dueDate
        
        if !editingMode {
            // Set start date to current
            startDatePicker.minimumDate = now
            startDateLbl.text = formatter.formatDate(now)
            
            // Set end date to one hour ahead of current time
            var timeNow = Date()
            timeNow.addTimeInterval(TimeInterval(3600.00))
            dueDateLbl.text = formatter.formatDate(timeNow)
            dueDatePicker.minimumDate = timeNow
            
            // Setting the initial task progress
            progressSlider.value = 0.5
            progressLbl.text = "Tast Completion Progress - 50%"
        }
        
        configureView()
        // Disable add button
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

    @IBAction func startDatePickerValueChanged(_ sender: UIDatePicker) {
        
        startDateLbl.text = formatter.formatDate(sender.date)
        // Set end date minimum to one hour ahead the start date
        let dueDate = sender.date.addingTimeInterval(TimeInterval(3600.00))
        dueDatePicker.minimumDate = dueDate
        dueDateLbl.text = formatter.formatDate(dueDate)
        
    }
    
    @IBAction func dueDatePickerValueChanged(_ sender: UIDatePicker) {
        
        dueDateLbl.text = formatter.formatDate(sender.date)
        
        // Set start date maximum to one minute before the end date
        startDatePicker.maximumDate = sender.date.addingTimeInterval(-TimeInterval(3600.00))

    }
    
    @IBAction func cancelBtnHandler(_ sender: UIBarButtonItem) {
    
        dismissAddTaskPopOver()
    }
    
    
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
    
    // Handles the add button enable state
    func toggleAddButtonEnability() {
        if validate() {
            addTaskBtn.isEnabled = true;
        } else {
            addTaskBtn.isEnabled = false;
        }
    }
    
    // Dismiss Popover
    func dismissAddTaskPopOver() {
        dismiss(animated: true, completion: nil)
        popoverPresentationController?.delegate?.popoverPresentationControllerDidDismissPopover?(popoverPresentationController!)
    }
    
    // Check if the required fields are empty or not
    func validate() -> Bool {
        if !(taskNameTxtFld.text?.isEmpty)! && !(notesTxtFld.text?.isEmpty)! {
            return true
        }
        return false
    }
    
    // Creates an event in the EKEventStore
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
    
    // Removes an event from the EKEventStore
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
