//
//  MessageViewController.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/26/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import UIKit
import CoreData

class MessageViewController: UIViewController {
    
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var browserButton: UIButton!
    
    @IBOutlet weak var bottomBarScroll: UIScrollView!
    @IBOutlet weak var messageTextView: UITextView!
    
    // fetch controllers
    var offset = 0
    var ResultSize = 100
    let PreFetchTrigger = 50
    var insertedIndexPath: NSIndexPath?
    
    // central data management object
    var manager: MorMessagesManager!
    @IBOutlet weak var tableView: UITableView!
    var context: NSManagedObjectContext!
    
    // Forum associated with this view
    var forum: Forum!
    
    // remember how far we moved the view after the keyboard displays
    private var viewShiftDistance: CGFloat? = nil
    private var bottomOfCurrentlyEditedItem: CGFloat? = nil
    
    // MARK: ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.tintColor = Constants.ThemeButtonTintColor
        navigationItem.rightBarButtonItem = produceDetailsBarButtonItem()
        resetMessageTextView()
        messageTextView.delegate = self
        context = CoreDataStackManager.sharedInstance().managedObjectContext
        do {
            try fetchedResultsController.performFetch()
        } catch _ {
            Logger.info("fetchedResultsController fetch failed")
        }
        fetchedResultsController.delegate = self
        fetchNewest()
    }
    override func viewWillAppear(animated: Bool) {
        // register action if keyboard will show
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        // unregister keyboard actions when view not showing
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    // MARK: Keyboard Handling

    func makeNoteOfBottomOfView(notedView: UIView) {
        let senderOrigin =  view.convertPoint(notedView.bounds.origin, fromView: notedView)
        bottomOfCurrentlyEditedItem =  senderOrigin.y + notedView.bounds.height
    }
    
    // shift the bottom bar view up if text field being edited will be obstructed
    func keyboardWillShow(notification: NSNotification) {
        if viewShiftDistance == nil {
            let keyboardHeight = getKeyboardHeight(notification)
            let topOfKeyboard = view.bounds.maxY - keyboardHeight
            // we only need to move the view if the keyboard will cover up the login button and text fields
            if let bottomOfCurrentlyEditedItem = bottomOfCurrentlyEditedItem
                where topOfKeyboard < bottomOfCurrentlyEditedItem {
                    viewShiftDistance = bottomOfCurrentlyEditedItem - topOfKeyboard
                    self.view.bounds.origin.y += viewShiftDistance!
            }
        }
    }
    
    // if bottom textfield just completed editing, shift the view back down
    func keyboardWillHide(notification: NSNotification) {
        if let shiftDistance = viewShiftDistance {
            self.view.bounds.origin.y -= shiftDistance
            viewShiftDistance = nil
        }
    }
    
    // return height of displayed keyboard
    private func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        Logger.info("we think the keyboard height is: \(keyboardSize.CGRectValue().height)")
        return keyboardSize.CGRectValue().height
    }
    
    // MARK: UIBarButonItem Producers

    // return a button with details label
    private func produceDetailsBarButtonItem() -> UIBarButtonItem? {
        let button = UIBarButtonItem(title: "Details", style: UIBarButtonItemStyle.Plain, target: self, action: "forumDetailsAction:")
        applyThemeToButton(button)
        return button
    }
    
    private func applyThemeToButton(button: UIBarButtonItem?) {
        if let button = button {
            button.tintColor = Constants.ThemeButtonTintColor
        }
    }
    
    // action when "Details" button is tapped
    func forumDetailsAction(sender: AnyObject!) {
        //performSegueWithIdentifier(Constants.ForumDetailsSegue, sender: self)
    }
    
    @IBAction func sendMessageAction(sender: UIButton) {
        if let text = messageTextView.text,
            forumId = forum.id {
                self.messageTextView.editable = false
            self.manager.createMessageWithText(text, inForum: forumId) { message, error in
                self.networkActivity(false)
                self.messageTextView.editable = true
                if message != nil {
                    self.resetMessageTextView()
                } else if let error = error {
                    ToolKit.showErrorAlert(viewController: self, title: "Send Failed", message: error.localizedDescription)
                } else {
                    ToolKit.showErrorAlert(viewController: self, title: "Send Failed", message: "We failed to send the message, but we aren't sure why.")
                }
            }
        } else {
            // the send button should be disabled, so this should never happen
            Logger.error("cannot send message, forum.id or message text is nil")
        }
    }
    
    func resetMessageTextView() {
        self.messageTextView.text = Constants.DefaultMessageText
        self.messageTextView.textColor = Constants.DefaultMessageTextPlaceHolderColor
    }
    
    // MARK: - Core Data Convenience
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    // Mark: - Fetched Results Controller
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        // Create the fetch request
        let fetchRequest = NSFetchRequest(entityName: Message.EntityName)
        
        // Add a sort descriptor. This enforces a sort order on the results that are generated
        // In this case we want the events sorted by id.
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        
        fetchRequest.predicate = NSPredicate(format: "forum = %@", self.forum)
        
        // Create the Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.context, sectionNameKeyPath: nil, cacheName: nil)
        
        // Return the fetched results controller. It will be the value of the lazy variable
        return fetchedResultsController
    } ()
    
    func fetchNewest() {
        var greaterThan = 0
        if let maxIndex = storedRange().maxElement() {
            greaterThan = maxIndex
        }
        fetchWithOffset(0, greaterThan: greaterThan)
    }
    
    func fetchOlder() {
        fetchWithOffset(offset, greaterThan: -1)
    }
    
    func fetchWithOffset(offset: Int, greaterThan: Int) {
        // TODO: make use of greater than
        networkActivity(true)
        manager.listMessagesInForum(forum, offset: offset, resultSize: ResultSize, greaterThan: greaterThan) { messages, error in
            
            self.networkActivity(false)
            if let count = messages?.count {
                self.offset += count
                Logger.info("Fetched count(\(count)) items, setting offset(\(offset))")
            }
        }
    }
    
    func networkActivity(active: Bool, intrusive: Bool = true) {
        dispatch_async(dispatch_get_main_queue()) {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = active
        }
    }
    
    // return the first and last items that we already downloaded
    func storedRange() -> Range<Int> {
        var oldest = 0
        var newest = 0
        if let sections = self.fetchedResultsController.sections
            where sections.count == 1 {
                let section = sections[0]
                if section.numberOfObjects > 0 {
                    if let objects = section.objects,
                        first = objects[0] as? Message,
                        last = objects[section.numberOfObjects - 1] as? Message,
                        firstId = last.id,
                        lastId = first.id {
                            oldest = Int(lastId)
                            newest = Int(firstId)
                    }
                }
        }
        return oldest...newest
    }
    
    func itemCount() -> Int? {
        if let sections = self.fetchedResultsController.sections
            where sections.count == 1 {
                let section = sections[0]
                return section.numberOfObjects
        } else {
            return nil
        }
    }
    
}

// MARK: - TableViewDataSource

extension MessageViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func tableView(tableView: UITableView,
        cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
            let CellIdentifier = Constants.MessageCellViewIdentifier
            let message = fetchedResultsController.objectAtIndexPath(indexPath) as! Message
            let cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier) as! MessageCellView
            cell.configureCellWithMessage(message)
            return cell
    }
    
    func tableView(tableView: UITableView,
        commitEditingStyle editingStyle: UITableViewCellEditingStyle,
        forRowAtIndexPath indexPath: NSIndexPath) {
            
            switch (editingStyle) {
            case .Delete:
                // Here we get the actor, then delete it from core data
                let movie = fetchedResultsController.objectAtIndexPath(indexPath) as! Message
                sharedContext.deleteObject(movie)
                CoreDataStackManager.sharedInstance().saveContext()
                
            default:
                break
            }
    }
}

// MARK: - Fetched Results Controller Delegate

extension MessageViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }

    func controller(controller: NSFetchedResultsController,
        didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
        atIndex sectionIndex: Int,
        forChangeType type: NSFetchedResultsChangeType) {
            
            switch type {
            case .Insert:
                self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
                
            case .Delete:
                self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
                
            default:
                return
            }
    }

    func controller(controller: NSFetchedResultsController,
        didChangeObject anObject: AnyObject,
        atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType,
        newIndexPath: NSIndexPath?) {
            
            switch type {
            case .Insert:
                if let newIndexPath = newIndexPath {
                    self.tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Fade)
                    insertedIndexPath = newIndexPath
                }
                
            case .Delete:
                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
                
            case .Update:
                if let indexPath = indexPath,
                    cell = tableView.cellForRowAtIndexPath(indexPath) as? MessageCellView,
                    message = controller.objectAtIndexPath(indexPath) as? Message {
                        cell.configureCellWithMessage(message)
                    }
                
            case .Move:
                if let indexPath = indexPath {
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                }
                if let newIndexPath = newIndexPath {
                    tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Fade)
                }
            }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
        if let indexPath = insertedIndexPath {
            tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
            insertedIndexPath = nil
        }
    }

}

// MARK: UITextViewDelegate

extension MessageViewController: UITextViewDelegate {
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        makeNoteOfBottomOfView(textView)
        if textView.text == Constants.DefaultMessageText {
            textView.text = ""
            textView.textColor = UIColor.blackColor()
        }
        return true
    }
    
    func textViewDidChange(textView: UITextView) {
        Logger.info("Text Did Change")

        let fixedWidth = textView.frame.size.width
        let oldSize = textView.frame.size
        textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
        var newFrame = textView.frame
        newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
        let dy = oldSize.height - newSize.height
        print("dy(\(dy))")
        newFrame.offsetInPlace(dx: 0.0, dy: dy)
        textView.frame = newFrame;
    }
 
    func textViewShouldEndEditing(textView: UITextView) -> Bool {
        bottomOfCurrentlyEditedItem = nil
        if textView.text == "" {
            resetMessageTextView()
        }
        return true
    }
    
}
