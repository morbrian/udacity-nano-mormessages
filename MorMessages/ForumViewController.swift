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

    // central data management object
    var manager: MorMessagesManager!
    
    var topRefreshView: RefreshView!
    
    var sortedResultsController: SortedResultsController<Forum>!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sortedResultsController = SortedResultsController(entityName: Forum.EntityName, ascending: false)
        sortedResultsController.performFetch()
        sortedResultsController.delegate = self
        sortedResultsController.pagedRequestDelegate = self
        sortedResultsController.fetchRecent()
        
        navigationController?.navigationBar.hidden = false
        navigationItem.leftBarButtonItem = produceLogoutBarButtonItem()
        navigationItem.rightBarButtonItem = produceAddBarButtonItem()
        if let navigationBar = navigationController?.navigationBar {
            navigationBar.translucent = false
            topRefreshView = produceRefreshViewWithHeight(navigationBar.bounds.height)
        }
    }
    
    // MARK: Button and Sub-View Producers
    
    // figure out the best height for the activity spinner area
    private func produceRefreshViewWithHeight(spinnerAreaHeight: CGFloat) -> RefreshView {
        let refreshViewHeight = view.bounds.height
        let refreshView = RefreshView(frame: CGRect(x: 0, y: -refreshViewHeight, width: view.bounds.width, height: refreshViewHeight), spinnerAreaHeight: spinnerAreaHeight, scrollView: collectionView)
        refreshView.translatesAutoresizingMaskIntoConstraints = false
        refreshView.delegate = self
        collectionView.insertSubview(refreshView, atIndex: 0)
        return refreshView
    }
    
    private func updateRefreshViewLayout() {
        let refreshViewHeight = view.bounds.height
        topRefreshView.frame = CGRect(x: 0, y: -refreshViewHeight, width: view.bounds.width, height: refreshViewHeight)
        topRefreshView.updateLayout()
    }
    
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
        } else if let destination = segue.destinationViewController as? MessageViewController,
            forum = sender as? Forum {
                destination.forum = forum
                destination.manager = self.manager
        } else {
            // programmer error, should never happen in production
            Logger.error("Unrecognized Segue Destination Class For Segue: \(segue.identifier ?? nil)")
        }
    }
    
    // MARK: Layout Helpers
    
    override func viewWillLayoutSubviews() {
        calculateCollectionCellSize()
        updateRefreshViewLayout()
    }
    
    // calculates cell size based on cells-per-row for the current device orientation
    private func calculateCollectionCellSize() {
        if let collectionView = collectionView {
            let width = collectionView.frame.width / CGFloat(collectionCellCountPerRow) - CGFloat(CollectionCellSpacing)
            let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
            layout?.itemSize = CGSize(width: width, height: width)
        }
    }
    
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
    
}

// MARK: - PagedRequestDelegate

extension ForumViewController: PageRequestDelegate {
    
    func pagedItems(offset offset: Int, resultSize: Int, greaterThan: NSDate,
        completionHandler: (() -> Void)?) {
            manager.listForums(offset: offset, resultSize: resultSize, greaterThan: greaterThan) { items, error in
                dispatch_async(dispatch_get_main_queue()) {
                    completionHandler?()
                }
            }
    }
}

// MARK: - UICollectionViewDelegate

extension ForumViewController: UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
            self.performSegueWithIdentifier(Constants.ShowMessageListSegue, sender: sortedResultsController.objectAtIndexPath(indexPath))
    }
    
    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        if sortedResultsController.preFetchConditionFulfilledByIndex(indexPath.item) {
            sortedResultsController.fetchOlder()
        }
    }
}

// MARK: - UICollectionViewDataSource

extension ForumViewController: UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sortedResultsController.numberOfObjectsInSection(section)
    }
    
    func collectionView(collectionView: UICollectionView,
        cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
            
            // Here is how to replace the actors array using objectAtIndexPath
            let forum = sortedResultsController.objectAtIndexPath(indexPath)
            
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

// MARK: - UIScrollViewDelegate

extension ForumViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        topRefreshView.scrollViewDidScroll(scrollView)
    }
    
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        topRefreshView.scrollViewWillEndDragging(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }
}

// MARK: - RefreshViewDelegate

extension ForumViewController: RefreshViewDelegate {
    func refreshViewDidRefresh(refreshView: RefreshView) {
        sortedResultsController.fetchNewest(refreshView.endRefreshing)
    }
}
