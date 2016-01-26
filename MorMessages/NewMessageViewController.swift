//
//  NewMessageViewController.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/25/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import UIKit

class NewMessageViewController: UIViewController {
    
    @IBOutlet weak var browseButton: UIButton!
    @IBOutlet weak var webBrowserPanel: UIView!
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    // central data management object
    var manager: MorMessagesManager!
    
    // MARK: ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "handleTap:")
        view.addGestureRecognizer(tapRecognizer)
        searchBar.delegate = self
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
    
    @IBAction func useCurrentWebPage(sender: UIBarButtonItem) {
        //forumImageUrlTextField?.text = webView.request?.URL?.absoluteString
        webBrowserPanel.hidden = true
    }
    
    @IBAction func showWebView(sender: UIButton) {
//        forumImageUrlTextField.endEditing(false)
//        if let urlText = forumImageUrlTextField.text {
//            webView.loadRequest(produceRequestForText(urlText))
//        } else {
            webView.loadRequest(produceRequestForText("images"))
//        }
//        webBrowserPanel.hidden = false
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
        //        dispatch_async(dispatch_get_main_queue()) {
        //            self.activitySpinner?.spinnerActivity(active)
        //        }
    }
}

// MARK: - UISearchBarDelegate

extension NewMessageViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        if let searchText = searchBar.text {
            let request = produceRequestForText(searchText)
            webView.loadRequest(request)
        }
    }
}


