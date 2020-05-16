//
//  DetailViewController.swift
//  AssessmentPlannerApp
//
//  Created by Hamool Nizar on 5/11/20.
//  Copyright © 2020 Hamool Nizar. All rights reserved.
//

import UIKit
import CoreData
import EventKit

class DetailViewController: UIViewController, NSFetchedResultsControllerDelegate, UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet weak var taskTableView: UITableView!
    @IBOutlet weak var moduleNameLabel: UILabel!
    @IBOutlet weak var assessmentNameLabel: UILabel!
    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var markLabel: UILabel!
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var assessmentProgressBar: CircularProgressBar!
    @IBOutlet weak var countdownTimerBar: CircularProgressBar!
    @IBOutlet weak var editTaskBtn: UIBarButtonItem!
    @IBOutlet weak var addTaskBtn: UIBarButtonItem!
    @IBOutlet weak var assessmentDetailsView: UIView!
    
    let formatter: Formatter = Formatter()
    let calculations: Calculations = Calculations()
    let colours: Colours = Colours()
    
    var detailViewController: DetailViewController? = nil
    var managedObjectContext: NSManagedObjectContext? = nil
//    var managedObjectContext: NSManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    let now = Date()
    let bool = true
    
    var selectedAssessment: Assessment? {
        didSet {
            // Update the view.
            configureView()
        }
    }
    
    override func awakeFromNib() {
//        super.awakeFromNib()
//        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
//
//        self.managedObjectContext = appDelegate.persistentContainer.viewContext
//
//        let nibName = UINib(nibName: "TaskTableViewCell", bundle: nil)
//        taskTableView.register(nibName, forCellReuseIdentifier: "TaskCell")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Configure the view
        configureView()
        //        self.taskTableView.delegate = self
        //        self.taskTableView.dataSource = self
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        self.managedObjectContext = appDelegate.persistentContainer.viewContext
        
        // initializing the custom cell
        let nibName = UINib(nibName: "TaskTableViewCell", bundle: nil)
        taskTableView.register(nibName, forCellReuseIdentifier: "TaskCell")
        print("viewDidLoad")
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Set the default selected row
        let indexPath = IndexPath(row: 0, section: 0)
        if taskTableView.hasRowAtIndexPath(indexPath: indexPath as NSIndexPath) {
            taskTableView.selectRow(at: indexPath, animated: true, scrollPosition: .bottom)
        }
        print("viewWillAppear")
    }
    
//    @objc
//    func insertNewObject(_ sender: Any) {
//        let context = self.fetchedResultsController.managedObjectContext
//        let newTask = Task(context: context)
//
//        // If appropriate, configure the new managed object.
//        // newTask.timestamp = Date()
//
//        // Save the context.
//        do {
//            try context.save()
//        } catch {
//            // Replace this implementation with code to handle the error appropriately.
//            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//            let nserror = error as NSError
//            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
//        }
//    }
    
    func configureView() {
        // Update the user interface for the detail item.
        if let assessment = selectedAssessment {
            if let moduleNameLbl = moduleNameLabel {
                moduleNameLbl.text = assessment.moduleName
            }
            if let assessmentNameLbl = assessmentNameLabel {
                assessmentNameLbl.text = assessment.assesstmentName
            }
            if let dueDateLbl = dueDateLabel {
                dueDateLbl.text = "Due Date: \(formatter.formatDate(assessment.dueDate as Date))"
            }
            if let valueLbl = valueLabel {
                valueLbl.text = "Contribution Value - \(assessment.value)%"
            }
            if let markLbl = markLabel {
                markLbl.text = "Awarded Mark - \(assessment.mark)"
            }
            if let levelLbl = levelLabel {
                levelLbl.text = "Level - \(assessment.level)"
            }
            
            let tasks = (assessment.tasks!.allObjects as! [Task])
            let assessmentProgress = calculations.getProjectProgress(tasks)
            let daysLeftProgress = calculations.getRemainingTimePercentage(assessment.startDate as Date, end: assessment.dueDate as Date)
            var daysRemaining = self.calculations.getDateDiff(self.now, end: assessment.dueDate as Date)
            
            if daysRemaining < 0 {
                daysRemaining = 0
            }
            
            DispatchQueue.main.async {
                let colours = self.colours.getProgressGradient(assessmentProgress)
                self.assessmentProgressBar?.customSubtitle = "Completed"
                self.assessmentProgressBar?.startGradientColor = colours[0]
                self.assessmentProgressBar?.endGradientColor = colours[1]
                self.assessmentProgressBar?.progress = CGFloat(assessmentProgress) / 100
            }
            
            DispatchQueue.main.async {
                let colours = self.colours.getProgressGradient(daysLeftProgress, negative: true)
                self.countdownTimerBar?.customTitle = "\(daysRemaining)"
                self.countdownTimerBar?.customSubtitle = "Days Left"
                self.countdownTimerBar?.startGradientColor = colours[0]
                self.countdownTimerBar?.endGradientColor = colours[1]
                self.countdownTimerBar?.progress =  CGFloat(daysLeftProgress) / 100
            }
        }
        
        if selectedAssessment == nil {
            //taskTableView.isHidden = true
            //assessmentDetailsView.isHidden = true
        }
    }
    
    // MARK: - Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addTask" {
            let controller = (segue.destination as! UINavigationController).topViewController as! AddTaskViewController
            controller.selectedAssessment = selectedAssessment
            if let controller = segue.destination as? UIViewController {
                controller.popoverPresentationController!.delegate = self
                controller.preferredContentSize = CGSize(width: 350, height: 600)
            }
        }
        
        if segue.identifier == "editTask" {
            if let indexPath = taskTableView.indexPathForSelectedRow {
                let object = fetchedResultsController.object(at: indexPath)
                let controller = (segue.destination as! UINavigationController).topViewController as! AddTaskViewController
                controller.editingTask = object as Task
                controller.selectedAssessment = selectedAssessment
            }
        }
        
        if segue.identifier == "showAssessmentNotes" {
            let controller = segue.destination as! NotesViewController
            controller.notes = selectedAssessment!.notes
            if let controller = segue.destination as? UIViewController {
                controller.popoverPresentationController!.delegate = self
                controller.preferredContentSize = CGSize(width: 300, height: 250)
            }
        }
    }
    
    // MARK: - Table View
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //        let sectionInfo = fetchedResultsController.sections![section]
        let sectionInfo = self.fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo
        
        if selectedAssessment == nil {
            assessmentDetailsView.isHidden = true
            assessmentProgressBar.isHidden = true
            countdownTimerBar.isHidden = true
            addTaskBtn.isEnabled = false
            editTaskBtn.isEnabled = false
            taskTableView.setEmptyMessage("Add a new Assessment to manage Tasks", UIColor.black)
            return 0
        }
        
        if sectionInfo.numberOfObjects == 0 {
            editTaskBtn.isEnabled = false
            taskTableView.setEmptyMessage("No tasks available for this Assessment", UIColor.black)
        }
        
        return sectionInfo.numberOfObjects
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as! TaskTableViewCell
        let task = fetchedResultsController.object(at: indexPath)
        configureCell(cell, withTask: task, index: indexPath.row)
        cell.cellDelegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
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
    
    func configureCell(_ cell: TaskTableViewCell, withTask task: Task, index: Int) {
        //        print("Related assessment", task.assessment)
        cell.commonInit(taskName: task.taskName, taskProgress: CGFloat(task.progress), startDate: task.startDate as Date, dueDate: task.dueDate as Date, notes: task.notes, taskNo: index + 1)
    }
    
    // MARK: - Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController<Task> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        if selectedAssessment != nil {
            // Setting a predicate
            let predicate = NSPredicate(format: "%K == %@", "assessment", selectedAssessment as! Assessment)
            fetchRequest.predicate = predicate
        }
        
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "startDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "\(UUID().uuidString)-assessment")
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
        
        return _fetchedResultsController!
    }
    
    var _fetchedResultsController: NSFetchedResultsController<Task>? = nil
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        taskTableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            taskTableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            taskTableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            taskTableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            taskTableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            configureCell(taskTableView.cellForRow(at: indexPath!)! as! TaskTableViewCell, withTask: anObject as! Task, index: indexPath!.row)
        case .move:
            configureCell(taskTableView.cellForRow(at: indexPath!)! as! TaskTableViewCell, withTask: anObject as! Task, index: indexPath!.row)
            taskTableView.moveRow(at: indexPath!, to: newIndexPath!)
        default:
            return
        }
        
        configureView()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        //        taskTableView.endUpdates()
        //        taskTableView.reloadData()
    }
    
    func showPopoverFrom(cell: TaskTableViewCell, forButton button: UIButton, forNotes notes: String) {
        let buttonFrame = button.frame
        var showRect = cell.convert(buttonFrame, to: taskTableView)
        showRect = taskTableView.convert(showRect, to: view)
        showRect.origin.y -= 5
        
        let controller = self.storyboard?.instantiateViewController(withIdentifier: "NotesViewController") as? NotesViewController
        controller?.modalPresentationStyle = .popover
        controller?.preferredContentSize = CGSize(width: 300, height: 250)
        controller?.notes = notes
        
        if let popoverPresentationController = controller?.popoverPresentationController {
            popoverPresentationController.permittedArrowDirections = .up
            popoverPresentationController.sourceView = self.view
            popoverPresentationController.sourceRect = showRect
            
            if let popoverController = controller {
                present(popoverController, animated: true, completion: nil)
            }
        }
    }
    
}

extension DetailViewController: TaskTableViewCellDelegate {
    func viewNotes(cell: TaskTableViewCell, sender button: UIButton, content data: String) {
        self.showPopoverFrom(cell: cell, forButton: button, forNotes: data)
    }
}


// Manually Inserting Sample Data

//extension DetailViewController: UITableViewDataSource {
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        // return tasks.count
//        return 5
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell") as! TaskTableViewCell
//
//        cell.taskNoLabel.text = "01"
//        cell.taskNameLabel.text = "No Name for Now"
//        cell.dueDateLabel.text = "12/12/2020"
//        cell.daysCountdownLabel.text = "0"
//
//        return cell
//    }
//}
