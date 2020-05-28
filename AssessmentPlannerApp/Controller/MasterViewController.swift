//
//  MasterViewController.swift
//  AssessmentPlannerApp
//
//  Created by Hamool Nizar on 5/11/20.
//  Copyright © 2020 Hamool Nizar. All rights reserved.
//

import UIKit
import CoreData

class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var detailViewController: DetailViewController? = nil
    var managedObjectContext: NSManagedObjectContext? = nil
    
    let calculations: Calculations = Calculations()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        
        /// initializing the custom cell
        let nibName = UINib(nibName: "AssessmentTableViewCell", bundle: nil)
        tableView.register(nibName, forCellReuseIdentifier: "AssessmentCell")
        
        /// This is to test cell display using sample data
        //         addSampleDate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
        
        // Set the default selected row
        autoSelectTableRow()
    }
    
    
    // MARK: - Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showAssessmentDetails" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let object = fetchedResultsController.object(at: indexPath)
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.selectedAssessment = object as Assessment
            }
        }
        
        if segue.identifier == "addAssessment" {
            if let controller = segue.destination as? UIViewController {
                controller.popoverPresentationController!.delegate = self as? UIPopoverPresentationControllerDelegate
                controller.preferredContentSize = CGSize(width: 350, height: 600)
            }
        }
        
        if segue.identifier == "editAssessment" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let object = fetchedResultsController.object(at: indexPath)
                let controller = (segue.destination as! UINavigationController).topViewController as! AddAssessmentViewController
                controller.editingAssessment = object as Assessment
            }
        }
    }
    
    // MARK: - Table View
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let indexPath = tableView.indexPathForSelectedRow {
            let object = fetchedResultsController.object(at: indexPath)
            self.performSegue(withIdentifier: "showAssessmentDetails", sender: object)
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
        
        /// This is to test cell display
        //        return 5
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AssessmentCell", for: indexPath) as! AssessmentTableViewCell
        let assessment = fetchedResultsController.object(at: indexPath)
        configureCell(cell, withAssessment: assessment)
        return cell
        
        /// This is to test cell display
        //        let cell = tableView.dequeueReusableCell(withIdentifier: "AssessmentCell", for: indexPath) as! AssessmentTableViewCell
        //        cell.moduleNameLabel.text = "6COS0003241C"
        //        cell.assessmentNameLabel.text = "Coursework 1"
        //        cell.dueDateLabel.text = "Due: 18/05/2020"
        //        cell.assessmentStatusView.backgroundColor = UIColor(red: 50/255, green: 200/255, blue: 0/255, alpha: 1.00)
        //        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let context = fetchedResultsController.managedObjectContext
            context.delete(fetchedResultsController.object(at: indexPath))
            
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        autoSelectTableRow()
    }
    
    func configureCell(_ cell: AssessmentTableViewCell, withAssessment assessment: Assessment) {
        let assessmentProgress = calculations.getProjectProgress(assessment.tasks!.allObjects as! [Task])
        cell.commonInit(moduleName: assessment.moduleName, assessmentName: assessment.assesstmentName, assessmentStatus:  UIColor(red: 50/255, green: 200/255, blue: 0/255, alpha: 1.00), taskProgress: CGFloat(assessmentProgress), dueDate: assessment.dueDate, notes: assessment.notes)
    }
    
    // MARK: - Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController<Assessment> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest: NSFetchRequest<Assessment> = Assessment.fetchRequest()
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "startDate", ascending: false)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Master")
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
        // update UI
        autoSelectTableRow()
        
        return _fetchedResultsController!
    }    
    var _fetchedResultsController: NSFetchedResultsController<Assessment>? = nil
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            configureCell(tableView.cellForRow(at: indexPath!)! as! AssessmentTableViewCell, withAssessment: anObject as! Assessment)
        case .move:
            configureCell(tableView.cellForRow(at: indexPath!)! as! AssessmentTableViewCell, withAssessment: anObject as! Assessment)
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        default:
            return
        }
        
        // update UI
        autoSelectTableRow()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    /*
     // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
     
     func controllerDidChangeContent(controller: NSFetchedResultsController) {
     // In the simplest, most efficient, case, reload the table view.
     tableView.reloadData()
     }
     */
    
    /// This function is to automatically select a assesment when loading the application and when change occurs
    func autoSelectTableRow() {
        let indexPath = IndexPath(row: 0, section: 0)
        if tableView.hasRowAtIndexPath(indexPath: indexPath as NSIndexPath) {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .bottom)
            
            if let indexPath = tableView.indexPathForSelectedRow {
                let object = fetchedResultsController.object(at: indexPath)
                self.performSegue(withIdentifier: "showAssessmentDetails", sender: object)
            }
        } else {
            let empty = {}
            self.performSegue(withIdentifier: "showAssessmentDetails", sender: empty)
        }
    }
    
    /// Testing Purpose Only
    /// Add Sample Assessment for Testing
    func addSampleDate() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Assessment", in: context)
        let newAssessment = NSManagedObject(entity: entity!, insertInto: context)
        
        
        newAssessment.setValue("Module Name", forKey: "moduleName")
        newAssessment.setValue(6, forKey: "level")
        newAssessment.setValue("Assessment Name", forKey: "assesstmentName")
        newAssessment.setValue(50.0, forKey: "value")
        newAssessment.setValue(100.0, forKey: "mark")
        newAssessment.setValue("Nothing", forKey: "notes")
        newAssessment.setValue(Date(), forKey: "dueDate")
        newAssessment.setValue(Date(), forKey: "startDate")
        newAssessment.setValue(true, forKey: "addToCalendar")
        
        print(newAssessment)
    }
    
}


