//
//  MessageViewController.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/26/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import UIKit

class MessageViewController: UIViewController {
    
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var browserButton: UIButton!
    
    @IBOutlet weak var bottomBarView: UIView!
    @IBOutlet weak var messageTextView: UITextView!
    
    // central data management object
    var manager: MorMessagesManager!
    
    // Forum associated with this view
    var forum: Forum!
    
    // MARK: ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.tintColor = Constants.ThemeButtonTintColor
        navigationItem.rightBarButtonItem = produceAddBarButtonItem()
        messageTextView.delegate = self
    }
    
    // MARK: UIBarButonItem Producers

    // return a button with appropriate label for the adding forum on the navigation bar
    private func produceAddBarButtonItem() -> UIBarButtonItem? {
        let button = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: "addMessageAction:")
        applyThemeToButton(button)
        return button
    }
    
    private func applyThemeToButton(button: UIBarButtonItem?) {
        if let button = button {
            button.tintColor = Constants.ThemeButtonTintColor
        }
    }
    
    // action when "Add Forum" button is tapped
    func addMessageAction(sender: AnyObject!) {
        performSegueWithIdentifier(Constants.AddMessageSegue, sender: self)
    }
}

// MARK: UITextViewDelegate

extension MessageViewController: UITextViewDelegate {
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        if textView.text == Constants.DefaultMessageText {
            textView.text = ""
            textView.textColor = UIColor.blackColor()
        }
        return true
    }
    
    func textViewDidChange(textView: UITextView) {
        Logger.info("Text Did Change")

        // love you stackoverflow: http://stackoverflow.com/questions/50467/how-do-i-size-a-uitextview-to-its-content
        let fixedWidth = textView.frame.size.width
        let oldHeight = textView.frame.size.height
        //textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
        var newFrame = textView.frame
        newFrame.size = CGSize(width: fixedWidth, height: newSize.height)
        //newFrame.offsetInPlace(dx: 0.0, dy: raiseOffset)
        textView.frame = newFrame;
        
        
        // adjusting bottom bar....
//        let dy =  oldHeight - textView.frame.size.height
//        let textViewOrigin =  view.convertPoint(textView.bounds.origin, fromView: textView)
//        let bottomOfTextView =  textViewOrigin.y + textView.bounds.height
//        
//        let bottomOfView = view.bounds.origin.y + view.bounds.height
//
//        if bottomOfTextView > bottomOfView - 8.0 {
//            moveBottomBar(dy)
//        }
        

    }
    
    func moveBottomBar(dy: CGFloat) {
        //let fixedWidth = bottomBarView.frame.size.width
        let oldSize = bottomBarView.frame.size
        var newFrame = bottomBarView.frame
        newFrame.size = CGSize(width: oldSize.width, height: oldSize.height + dy)
        newFrame.offsetInPlace(dx: 0.0, dy: dy)
        
        bottomBarView.frame = newFrame;
    }
    
    func textViewShouldEndEditing(textView: UITextView) -> Bool {
        if textView.text == "" {
            textView.textColor = UIColor.lightGrayColor()
            textView.text = Constants.DefaultMessageText
        }
        return true
    }
    
}
