//
//  NewForumViewController.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/24/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import UIKit

class NewForumViewController: UIViewController {
    
    @IBOutlet weak var forumTitleTextField: UITextField!
    
    @IBOutlet weak var forumDescTextView: UITextView!
   
    @IBOutlet weak var forumImageUrlTextField: UITextField!
    
    @IBOutlet weak var forumImagePreview: UIImageView!
    
    @IBOutlet weak var activityView: UIView!

    var storedImageUrl: String?
    
    // remember how far we moved the view after the keyboard displays
    private var viewShiftDistance: CGFloat? = nil
    private var bottomOfCurrentlyEditedItem: CGFloat? = nil
    
    // central data management object
    var manager: MorMessagesManager!
    
    // MARK: ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "handleTap:")
        view.addGestureRecognizer(tapRecognizer)
        forumDescTextView.delegate = self
        forumDescTextView.text = Constants.DefaultForumDescriptionText
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
    
    @IBAction func beginEditTextfield(sender: UITextField) {
        makeNoteOfBottomOfView(sender)
    }
    
    func makeNoteOfBottomOfView(notedView: UIView) {
        let senderOrigin =  view.convertPoint(notedView.bounds.origin, fromView: notedView)
        bottomOfCurrentlyEditedItem =  senderOrigin.y + notedView.bounds.height
    }
    
    @IBAction func endTextEditing() {
        forumTitleTextField?.endEditing(false)
        forumDescTextView?.endEditing(false)
        forumImageUrlTextField?.endEditing(false)
        bottomOfCurrentlyEditedItem = nil
    }
    
    // shift the entire view up if text field being edited will be obstructed
    func keyboardWillShow(notification: NSNotification) {
        if viewShiftDistance == nil {
            let keyboardHeight = getKeyboardHeight(notification)
            let topOfKeyboard = view.bounds.maxY - keyboardHeight
            // we only need to move the view if the keyboard will cover up the login button and text fields
            if let bottomOfCurrentlyEditedItem = bottomOfCurrentlyEditedItem
                where topOfKeyboard < bottomOfCurrentlyEditedItem {
                viewShiftDistance = bottomOfCurrentlyEditedItem - topOfKeyboard
                self.activityView.bounds.origin.y += viewShiftDistance!
            }
        }
    }
    
    // if bottom textfield just completed editing, shift the view back down
    func keyboardWillHide(notification: NSNotification) {
        if let shiftDistance = viewShiftDistance {
            self.activityView.bounds.origin.y -= shiftDistance
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

    @IBAction func updateImageUrlAction(sender: UITextField) {
        var urlString: String?
        if forumImageUrlTextField == sender {
            urlString = forumImageUrlTextField.text
        } else if let text = sender.text {
            forumImageUrlTextField.text = ""
            if let url = ToolKit.produceRobohashUrlFromString(text) {
                urlString = url.absoluteString
                forumImageUrlTextField.text = urlString
            }
        }
        if let storedImage = WebClient.Caches.imageCache.imageWithIdentifier(urlString) {
            forumImagePreview.image = storedImage
        } else {
            forumImagePreview.image = UIImage(named: Constants.ForumFetchingImage)
            networkActivity(true)
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
                if let urlString = urlString,
                    url = NSURL(string: urlString),
                    data = NSData(contentsOfURL: url) {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.networkActivity(false)
                        let newImage = UIImage(data: data)
                        if let storedImageUrl = self.storedImageUrl {
                            // remove the old value so we don't build up a store of unused images
                            // while the user is still editing the tite
                            WebClient.Caches.imageCache.storeImage(nil, withIdentifier: storedImageUrl)
                        }
                        self.storedImageUrl = urlString
                        WebClient.Caches.imageCache.storeImage(newImage, withIdentifier: urlString)
                        self.forumImagePreview.image = newImage
                    })
                }
            }
        }
        
        
    }
    
    // MARK: Gestures
    
    func handleTap(sender: UIGestureRecognizer) {
        endTextEditing()
    }
    
    // MARK: Actions
    
    @IBAction func cancelAction(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func doneWithAddForumAction(sender: AnyObject) {
        let title = forumTitleTextField.text ?? ""
        var desc = forumDescTextView.text ?? ""
        if desc == Constants.DefaultForumDescriptionText {
            desc = ""
        }
        var imageUrl = forumImageUrlTextField.text ?? ""
        
        forumImageUrlTextField.endEditing(false)
        let enteredUrlString = forumImageUrlTextField.text ?? ""
        
        // we check the basic syntax of the URL using the provided NSURL class,
        // then we verify the protocol is http(s) because these should be web pages not some other link,
        // finally we'll do a lightweight HEAD check with a request.
        if let url = ToolKit.produceValidUrlFromString(enteredUrlString) {
            
            let urlString = url.absoluteString
            self.networkActivity(true)
            WebClient().pingUrl(enteredUrlString) { reply, error in
                if reply {
                    self.forumImageUrlTextField.text = urlString
                    imageUrl = urlString
                    self.manager.createForumWithTitle(title, desc: desc, imageUrl: imageUrl) { forum, errror in
                        self.networkActivity(false)
                        if forum != nil {
                            dispatch_async(dispatch_get_main_queue()) {
                                self.dismissViewControllerAnimated(true, completion: nil)
                            }
                        } else if let error = error {
                            ToolKit.showErrorAlert(viewController: self, title: "Data Not Updated", message: error.localizedDescription)
                        } else {
                            ToolKit.showErrorAlert(viewController: self, title: "Data Not Updated", message: "We failed to store your updates, but we aren't sure why.")
                        }
                    }
                } else if let error = error {
                    self.networkActivity(false)
                    ToolKit.showErrorAlert(viewController: self, title: "Invalid Url", message: error.localizedDescription)
                }
            }
        } else {
            ToolKit.showErrorAlert(viewController: self, title: "Invalid Url", message: "Try entering a valid URL.")
        }
    }

    private func produceRequestForText(textString: String) -> NSURLRequest {
        
        if let validUrl = ToolKit.produceValidUrlFromString(textString),
            request = WebClient().createHttpRequestUsingMethod(WebClient.HttpGet, forUrlString: validUrl.absoluteString) {
                return request
        } else if let searchUrl = ToolKit.produceGoogleImageUrlFromSearchString(textString),
            request = WebClient().createHttpRequestUsingMethod(WebClient.HttpGet, forUrlString: searchUrl.absoluteString) {
                return request
        } else {
            let request = WebClient().createHttpRequestUsingMethod(WebClient.HttpGet,
                forUrlString: "https://images.google.com")
            return request!
        }
    }
    
    func networkActivity(active: Bool) {
        dispatch_async(dispatch_get_main_queue()) {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = active
        }
    }
}

// MARK: UITextViewDelegate

extension NewForumViewController: UITextViewDelegate {
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        makeNoteOfBottomOfView(textView)
        if textView.text == Constants.DefaultForumDescriptionText {
            textView.text = ""
            textView.textColor = forumTitleTextField.textColor
        }
        return true
    }
    
    func textViewShouldEndEditing(textView: UITextView) -> Bool {
        bottomOfCurrentlyEditedItem = nil
        if textView.text == "" {
            textView.textColor = UIColor.lightGrayColor()
            textView.text = Constants.DefaultForumDescriptionText
        }
        return true
    }

}
