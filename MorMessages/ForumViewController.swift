//
//  ForumViewController.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/22/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import UIKit
import CoreData

class ForumViewController: UIViewController {

    let CollectionCellsPerRowLandscape = 5
    let CollectionCellsPerRowPortrait = 3
    
    // CODE: set as 2 in IB, not sure how to reference that value in code, so keep this in sync
    let CollectionCellSpacing = 2
    
    // fetch controllers
    var offset = 0
    var ResultSize = 100
    let PreFetchTrigger = 50

    // central data management object
    var manager: MorMessagesManager!
    
    @IBOutlet weak var collectionView: UICollectionView!
    var context: NSManagedObjectContext!
    
    // MARK: ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.hidden = false
        navigationItem.leftBarButtonItem = produceLogoutBarButtonItem()
        navigationItem.rightBarButtonItem = produceAddBarButtonItem()
        context = CoreDataStackManager.sharedInstance().managedObjectContext
        do {
            try fetchedResultsController.performFetch()
        } catch _ {
            Logger.info("fetchedResultsController fetch failed")
        }
        fetchedResultsController.delegate = self
        fetchNewest()
    }
    
    // MARK: UIBarButonItem Producers
    
    // return a button with appropriate label for the logout position on the navigation bar
    private func produceLogoutBarButtonItem() -> UIBarButtonItem? {
        let button = UIBarButtonItem(title: "Logout", style: UIBarButtonItemStyle.Done, target: self, action: "returnToLoginScreen:")
        applyThemeToButton(button)
        return button
    }
    
    // return a button with appropriate label for the adding forum on the navigation bar
    private func produceAddBarButtonItem() -> UIBarButtonItem? {
        let button = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: "addForumAction:")
        applyThemeToButton(button)
        return button
    }
    
    private func applyThemeToButton(button: UIBarButtonItem) {
        button.tintColor = Constants.ThemeButtonTintColor
    }
    
    // MARK: View Transitions
    
    // log out and pop to root login viewcontroller
    func returnToLoginScreen(sender: AnyObject) {
        manager.logout(){_ in }
        navigationController?.popToRootViewControllerAnimated(true)
        //performSegueWithIdentifier(Constants.ReturnToLoginScreenSegue, sender: self)
    }
    
    // action when "Add Forum" button is tapped
    func addForumAction(sender: AnyObject!) {
        performSegueWithIdentifier(Constants.AddForumSegue, sender: self)
    }
    
    // segue preparations
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destination = segue.destinationViewController as? NewForumViewController {
            destination.manager = manager
        }
    }
    
    // MARK: Layout Helpers
    
    override func viewWillLayoutSubviews() {
        calculateCollectionCellSize()
    }
    
    // calculates cell size based on cells-per-row for the current device orientation
    private func calculateCollectionCellSize() {
        if let collectionView = collectionView {
            let width = collectionView.frame.width / CGFloat(collectionCellCountPerRow) - CGFloat(CollectionCellSpacing)
            let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
            layout?.itemSize = CGSize(width: width, height: width)
        }
    }
    
    // MARK: - Core Data Convenience
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    // Mark: - Fetched Results Controller
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        // Create the fetch request
        let fetchRequest = NSFetchRequest(entityName: Forum.EntityName)
        
        // Add a sort descriptor. This enforces a sort order on the results that are generated
        // In this case we want the events sored by id.
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        
        // Create the Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.context, sectionNameKeyPath: nil, cacheName: nil)
        
        // Return the fetched results controller. It will be the value of the lazy variable
        return fetchedResultsController
    } ()
    
    private var defaultCount: Int?
    private var collectionCellCountPerRow: Int {
        let orientation = UIDevice.currentDevice().orientation
        switch orientation {
        case .LandscapeLeft, .LandscapeRight:
            defaultCount = CollectionCellsPerRowLandscape
            return CollectionCellsPerRowLandscape
        case .Portrait:
            defaultCount = CollectionCellsPerRowPortrait
            return CollectionCellsPerRowPortrait
        default:
            return defaultCount ?? CollectionCellsPerRowPortrait
        }
    }
    
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
        manager.listForums(offset: offset, resultSize: ResultSize, greaterThan: greaterThan) { forums, error in
            
            self.networkActivity(false)
            if let count = forums?.count {
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
                        first = objects[0] as? Forum,
                        last = objects[section.numberOfObjects - 1] as? Forum,
                        firstId = last.id,
                        lastId = first.id {
                            oldest = Int(firstId)
                            newest = Int(lastId)
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

// MARK: - UICollectionViewDelegate

extension ForumViewController: UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let forum = fetchedResultsController.objectAtIndexPath(indexPath) as? Forum {
            // TODO: i think we'll want to segue to messag lists from here right?
        }
    }
    
    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        if let itemCount = itemCount() {
            if indexPath.item == itemCount - PreFetchTrigger {
                fetchOlder()
            }
        }
    }
}

// MARK: - UICollectionViewDataSource

extension ForumViewController: UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView,
        cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
            
            // Here is how to replace the actors array using objectAtIndexPath
            let forum = fetchedResultsController.objectAtIndexPath(indexPath) as! Forum
            
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.ForumCellViewIdentifier, forIndexPath: indexPath) as! ForumCellView
            
            // reset the image so we won't see the wrong image during loading when cell is reused
            cell.imageView?.image = nil
            cell.forum = forum
            
            return cell
    }
}


// MARK: - Fetched Results Controller Delegate

extension ForumViewController:NSFetchedResultsControllerDelegate {
    
    func controller(controller: NSFetchedResultsController,
        didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
        atIndex sectionIndex: Int,
        forChangeType type: NSFetchedResultsChangeType) {
            
            switch type {
            case .Insert:
                self.collectionView.insertSections(NSIndexSet(index: sectionIndex))
                
            case .Delete:
                self.collectionView.deleteSections(NSIndexSet(index: sectionIndex))
                
            default:
                return
            }
    }
    
    //
    // This is the most interesting method. Take particular note of way the that newIndexPath
    // parameter gets unwrapped and put into an array literal: [newIndexPath!]
    //
    func controller(controller: NSFetchedResultsController,
        didChangeObject anObject: AnyObject,
        atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType,
        newIndexPath: NSIndexPath?) {
            
            switch type {
            case .Insert:
                if let index = newIndexPath {
                    collectionView.insertItemsAtIndexPaths([index])
                }
                
            case .Delete:
                if let index = indexPath {
                    collectionView.deleteItemsAtIndexPaths([index])
                }
                
            case .Update:
                if let index = indexPath,
                    cell = collectionView.cellForItemAtIndexPath(index) as? ForumCellView,
                    forum = controller.objectAtIndexPath(index) as? Forum {
                        cell.configureCellWithForum(forum)
                }
                
            case .Move:
                if let indexPath = indexPath, newIndexPath = newIndexPath {
                    collectionView.deleteItemsAtIndexPaths([indexPath])
                    collectionView.insertItemsAtIndexPaths([newIndexPath])
                }
            }
    }
    
}
