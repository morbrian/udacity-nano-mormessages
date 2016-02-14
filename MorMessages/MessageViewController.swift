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
    
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var browserButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var messageTextField: UITextField!
    
    // layout hints
    let EstimatedRowHeight: CGFloat = 44
    
    // fetch controllers
    var fetchOffset = 0
    let ResultSize = 100
    let PreFetchTrigger = 50
    var insertedIndexPath: NSIndexPath?
    
    // central data management object
    var manager: MorMessagesManager!
    @IBOutlet weak var tableView: UITableView!
    var context: NSManagedObjectContext!
    
    // Forum associated with this view
    var forum: Forum!
    var subscription: Subscription?
    var serviceReachability: Reachability!
    var serviceReachabilityIndicator: UIBarButtonItem!
    
    var topRefreshView: RefreshView!
    
    // remember how far we moved the view after the keyboard displays
    private var viewShiftDistance: CGFloat? = nil
    
    // MARK: ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        serviceReachability = Reachability(hostName: ForumService.MorMessagesHostname);
        serviceReachability.startNotifier()
        navigationController?.navigationBar.tintColor = Constants.ThemeButtonTintColor
        serviceReachabilityIndicator = producesServiceReachabilityBarButtonItem()
        navigationItem.rightBarButtonItems = [
            produceDetailsBarButtonItem(),
            serviceReachabilityIndicator
        ]
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "networkReachabilityChanged:", name: kReachabilityChangedNotification, object: nil)
        
        if let navigationBar = navigationController?.navigationBar {
            navigationBar.translucent = false
            topRefreshView = produceRefreshViewWithHeight(navigationBar.bounds.height)
        }
        self.tableView.rowHeight = UITableViewAutomaticDimension;
        self.tableView.estimatedRowHeight = EstimatedRowHeight;
        context = CoreDataStackManager.sharedInstance().managedObjectContext
        do {
            try fetchedResultsController.performFetch()
        } catch _ {
            Logger.info("fetchedResultsController fetch failed")
        }
        fetchedResultsController.delegate = self
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "handleTap:")
        view.addGestureRecognizer(tapRecognizer)
        layoutBottomBar()
    }
    
    func networkReachabilityChanged(notification: NSNotification) {
        Logger.info("reachability changed")
        if serviceReachability.currentReachabilityStatus() != NotReachable {
            fetchRecent()
            if let subscription = subscription {
                self.activate(subscription)
            } else {
                self.subscribe()
            }
            serviceReachabilityIndicator.image = UIImage(named: Constants.GreenCheckImage)
            serviceReachabilityIndicator.tintColor = UIColor.greenColor()
        } else {
            serviceReachabilityIndicator.image = UIImage(named: Constants.RedxImage)
            serviceReachabilityIndicator.tintColor = UIColor.redColor()
            
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // register action if keyboard will show
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        
        Logger.info("view will appear");
        fetchRecent(self.scrollToBottom)
        if let subscription = subscription {
            self.activate(subscription)
        } else {
            self.subscribe()
        }
    }
    
    func subscribe() {
        manager.subscribeToForum(forum){ subscription, error in
            if let subscription = subscription {
                self.subscription = subscription
                self.activate(subscription)
            } else {
                Logger.error("Subscribe failed: \(error?.description)")
            }
        }
    }
    
    func activate(subscription: Subscription) {
        self.manager.activateSubscription(subscription) { error in
            if error != nil {
                Logger.error("Activation failed: \(error?.description)")
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        // unregister keyboard actions when view not showing
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func willMoveToParentViewController(parent: UIViewController?) {
        if parent == nil {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: kReachabilityChangedNotification, object: nil)
            if let subscription = subscription {
                manager.unsubscribe(subscription)
            }
        }
    }
    
    override func viewWillLayoutSubviews() {
        updateRefreshViewLayout()
    }
    
    func endTextEditing() {
        messageTextField?.endEditing(false)
    }
    
    func handleTap(sender: UIGestureRecognizer) {
        endTextEditing()
    }
    
    // MARK: Keyboard Handling
    
    // shift the bottom bar view up if text field being edited will be obstructed
    func keyboardWillShow(notification: NSNotification) {
        let senderOrigin =  view.convertPoint(contentView.bounds.origin, fromView: contentView)
        let bottomOfCurrentlyEditedItem =  senderOrigin.y + contentView.bounds.height
        if viewShiftDistance == nil {
            let keyboardHeight = getKeyboardHeight(notification)
            let topOfKeyboard = view.bounds.maxY - keyboardHeight
            // we only need to move the view if the keyboard will cover up the login button and text fields
            if topOfKeyboard < bottomOfCurrentlyEditedItem {
                    viewShiftDistance = bottomOfCurrentlyEditedItem - topOfKeyboard
                    self.contentView.bounds.offsetInPlace(dx: 0.0, dy: viewShiftDistance!)
            }
        }
    }
    
    // if bottom textfield just completed editing, shift the view back down
    func keyboardWillHide(notification: NSNotification) {
        if let shiftDistance = viewShiftDistance {
            self.contentView.bounds.offsetInPlace(dx: 0.0, dy: -shiftDistance)
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
    
    // MARK: Button and Sub-View Producers
    
    // figure out the best height for the activity spinner area
    private func produceRefreshViewWithHeight(spinnerAreaHeight: CGFloat) -> RefreshView {
        let refreshViewHeight = view.bounds.height
        let refreshView = RefreshView(frame: CGRect(x: 0, y: -refreshViewHeight, width: view.bounds.width, height: refreshViewHeight), spinnerAreaHeight: spinnerAreaHeight, scrollView: tableView)
        refreshView.translatesAutoresizingMaskIntoConstraints = false
        refreshView.delegate = self
        tableView.insertSubview(refreshView, atIndex: 0)
        return refreshView
    }
    
    private func updateRefreshViewLayout() {
        let refreshViewHeight = view.bounds.height
        topRefreshView.frame = CGRect(x: 0, y: -refreshViewHeight, width: view.bounds.width, height: refreshViewHeight)
        topRefreshView.updateLayout()
    }

    // return a button with details label
    private func produceDetailsBarButtonItem() -> UIBarButtonItem {
        let button = UIBarButtonItem(title: "Details", style: UIBarButtonItemStyle.Plain, target: self, action: "forumDetailsAction:")
        applyThemeToButton(button)
        return button
    }
    
    private func producesServiceReachabilityBarButtonItem() -> UIBarButtonItem {
        let stateImage = serviceReachability.currentReachabilityStatus() == NotReachable ?
            UIImage(named: Constants.RedxImage) :
            UIImage(named: Constants.GreenCheckImage)
        let stateColor = serviceReachability.currentReachabilityStatus() == NotReachable ?
            UIColor.redColor() :
            UIColor.greenColor()
        let button = UIBarButtonItem(image: stateImage, style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        button.tintColor = stateColor
        return button
    }
    
    private func applyThemeToButton(button: UIBarButtonItem?) {
        if let button = button {
            button.tintColor = Constants.ThemeButtonTintColor
        }
    }
    
    // action when "Details" button is tapped
    func forumDetailsAction(sender: AnyObject!) {
        performSegueWithIdentifier(Constants.ShowDetailsSegue, sender: self)
    }
    
    // segue preparations
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destination = segue.destinationViewController as? DetailsViewController {
            destination.manager = manager
            destination.forum = forum
        } else {
            Logger.error("Unrecognized Segue Destination Class For Segue: \(segue.identifier ?? nil)")
        }
        
    }
    
    func layoutBottomBar() {
        let sendable = messageTextField.text != ""
        if sendable {
            if sendButton.hidden {
                messageTextField.frame.size.width -= sendButton.frame.size.width
            }
            sendButton.hidden = false
            sendButton.enabled = true
        } else {
            if !sendButton.hidden {
                messageTextField.frame.size.width += sendButton.frame.size.width
            }
            sendButton.hidden = true
            sendButton.enabled = false
        }
    }
    
    @IBAction func editingChanged(sender: UITextField) {
        layoutBottomBar()
    }
    
    @IBAction func sendMessageOnEnter(sender: UITextField) {
        sendMessage()
    }
    
    @IBAction func sendMessageAction(sender: UIButton) {
        if messageTextField.text != "" {
            sendMessage()
        }
    }
    
    func sendMessage() {
        messageTextField.endEditing(true)
        if let text = messageTextField.text,
            forumUuid = forum.uuid {
                self.messageTextField.enabled = false
                self.manager.createMessageWithText(text, inForum: forumUuid) { message, error in
                    self.networkActivity(false)
                    self.messageTextField.enabled = true
                    if message != "" {
                        self.messageTextField.text = ""
                        self.layoutBottomBar()
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
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "modifiedTime", ascending: true)]
        
        fetchRequest.predicate = NSPredicate(format: "forum = %@", self.forum)
        
        // Create the Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.context, sectionNameKeyPath: nil, cacheName: nil)
        
        // Return the fetched results controller. It will be the value of the lazy variable
        return fetchedResultsController
    } ()
    
    func scrollToBottom() {
        if let sections = self.fetchedResultsController.sections
            where sections.count == 1 {
                let section = sections[0]
                if section.numberOfObjects > 0 {
                    self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: section.numberOfObjects - 1, inSection: 0),
                        atScrollPosition: UITableViewScrollPosition.Bottom,
                        animated: false)
                }
        }
    }
    // similar to "Newest" but not constrained by already downloaded dates
    func fetchRecent(completionHandler: (() -> Void)? = nil) {
        fetchWithOffset(0, greaterThan: ToolKit.DateKit.Epoch, completionHandler: completionHandler)
    }
    
    func fetchNewest(completionHandler: (() -> Void)? = nil) {
        let greaterThan = storedRange().newest
        fetchWithOffset(0, greaterThan: greaterThan, completionHandler: completionHandler)
    }
    
    func fetchOlder(completionHandler: (() -> Void)? = nil) {
        fetchWithOffset(fetchOffset, greaterThan: ToolKit.DateKit.Epoch, completionHandler: completionHandler)
    }
    
    func fetchWithOffset(fetchOffset: Int, greaterThan: NSDate, completionHandler: (() -> Void)? = nil) {
        let beforeCount = itemCount()
        networkActivity(true)
        manager.listMessagesInForum(forum, offset: fetchOffset, resultSize: ResultSize, greaterThan: greaterThan) { messages, error in
            dispatch_async(dispatch_get_main_queue()) {
                self.networkActivity(false)
                let afterCount = self.itemCount()
                
                self.fetchOffset += afterCount - beforeCount
                Logger.info("BEFORE(\(beforeCount)), AFTER(\(afterCount))")
                Logger.info("Fetched count(\(afterCount - beforeCount)) items, setting offset(\(self.fetchOffset))")

                completionHandler?()
            }
        }
    }
    
    func networkActivity(active: Bool, intrusive: Bool = true) {
        dispatch_async(dispatch_get_main_queue()) {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = active
        }
    }
    
    func itemCount() -> Int {
        if let sections = self.fetchedResultsController.sections
            where sections.count == 1 {
                return sections[0].numberOfObjects
        }
        return 0
    }
    
    // return the first and last items that we already downloaded
    func storedRange() -> (oldest: NSDate, newest: NSDate) {
        var oldest = ToolKit.DateKit.Epoch
        var newest = ToolKit.DateKit.Epoch
        if let sections = self.fetchedResultsController.sections
            where sections.count == 1 {
                let section = sections[0]
                if section.numberOfObjects > 0 {
                    if let objects = section.objects,
                        first = objects[0] as? Message,
                        last = objects[section.numberOfObjects - 1] as? Message,
                        firstId = last.modifiedTime,
                        lastId = first.modifiedTime {
                            oldest = lastId
                            newest = firstId
                    }
                }
        }
        return (oldest, newest)
    }
   
}

// MARK: - UITableViewDelegate

extension MessageViewController: UITableViewDelegate {
   //placeholder
}

// MARK: - TableViewDataSource

extension MessageViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func tableView(tableView: UITableView,
        cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
            let message = fetchedResultsController.objectAtIndexPath(indexPath) as! Message
            
            var reuseIdentifier: String?
            if let identity = manager.currentUser?.identity,
                createdBy = message.createdBy
                    where identity == createdBy {
                        reuseIdentifier = Constants.MessageCellViewRightIdentifier
            } else {
                reuseIdentifier = Constants.MessageCellViewLeftIdentifier
            }
            
            let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier!) as! MessageCellView
            cell.message = message
            return cell
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.None;
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

// MARK: - UIScrollViewDelegate

extension MessageViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        topRefreshView.scrollViewDidScroll(scrollView)
    }
    
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        topRefreshView.scrollViewWillEndDragging(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }
}

// MARK: - RefreshViewDelegate

extension MessageViewController: RefreshViewDelegate {
    func refreshViewDidRefresh(refreshView: RefreshView) {
        fetchOlder(refreshView.endRefreshing)
    }
}
