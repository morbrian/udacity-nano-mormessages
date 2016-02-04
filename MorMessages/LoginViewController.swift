//
//  LoginViewController.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/22/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import UIKit

// LoginViewController
// Presents username / password enabling user to login to appliction.
// Displays error messages if login is not successful.
class LoginViewController: UIViewController {
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginStatusLabel: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    //@IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    
    // central data management object
    private var manager: MorMessagesManager!
    
    // remember how far we moved the view after the keyboard displays
    private var viewShiftDistance: CGFloat? = nil
    
    // network activity properties
    var activityInProgress = false
    private var spinnerBaseTransform: CGAffineTransform!

    // MARK: ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        manager = MorMessagesManager()
        navigationController?.navigationBar.hidden = true
        // TODO: Consider using GBDeviceInfo, although this check is sufficient for our simple needs
        if view.bounds.height <= CGFloat(Constants.DeviceiPhone5Height) {
            // for iPhone5 or smaller, make some of the fonts smaller
//            signupButton.titleLabel?.font = signupButton.titleLabel?.font.fontWithSize(CGFloat(16.0))
            loginStatusLabel.font = loginStatusLabel.font.fontWithSize(CGFloat(12.0))
        }
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "handleTap:")
        view.addGestureRecognizer(tapRecognizer)
        spinnerBaseTransform = self.imageView.transform
    }

    
    override func viewWillAppear(animated: Bool) {
        resetLoginStatusLabel()
        // register action if keyboard will show
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        // unregister keyboard actions when view not showing
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    // MARK: Keyboard Show/Hide Handling
    
    // shift the entire view up if bottom text field being edited
    func keyboardWillShow(notification: NSNotification) {
        var bottomOfLoginButton: CGFloat {
            let loginButtonOrigin =  view.convertPoint(loginButton.bounds.origin, fromView: loginButton)
            return loginButtonOrigin.y + loginButton.bounds.height
        }
        if viewShiftDistance == nil {
            let keyboardHeight = getKeyboardHeight(notification)
            let topOfKeyboard = view.bounds.maxY - keyboardHeight
            // we only need to move the view if the keyboard will cover up the login button and text fields
            if topOfKeyboard < bottomOfLoginButton {
                viewShiftDistance = bottomOfLoginButton - topOfKeyboard
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
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.CGRectValue().height
    }
    
    // MARK: IB Actions
    
    @IBAction func beginEditTextfield(sender: UITextField) {
        resetLoginStatusLabel()
    }
    
    @IBAction func performLogin(sender: UIButton) {
        endTextEditing()
        loginStatusLabel.hidden = true
        let username = usernameTextField.text
        let password = passwordTextField.text
        
        networkActivity(true)
        manager.authenticateByUsername(username!, withPassword: password!,
            completionHandler: handleAuthenticationResponse)
    }
    
    @IBAction func gotoAccountSignup(sender: UIButton) {
        Logger.error("Sign up not implemented yet.")
        //UIApplication.sharedApplication().openURL(NSURL(string: Constants.UdacitySignupUrlString)!)
    }

    // MARK: Segue Transition
    
    private func transitionSucessfulLoginSegue() {
        dispatch_async(dispatch_get_main_queue()) {
            self.performSegueWithIdentifier(Constants.SuccessfulLoginSegue, sender: self.manager)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destination = segue.destinationViewController as? ForumViewController,
            dataManager = sender as? MorMessagesManager {
                destination.manager = dataManager
        } else {
            Logger.error("Unrecognized Segue Destination Class For Segue: \(segue.identifier ?? nil)")
        }
    }
    
    // MARK: Support Helpers
    
    // provide acivity indicators and animations
    func networkActivity(active: Bool) {
        dispatch_async(dispatch_get_main_queue()) {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = active
            self.activityInProgress = active
            self.usernameTextField.enabled = !active
            self.passwordTextField.enabled = !active
            self.loginButton.enabled = !active
            //self.signupButton.enabled = !active
            if (active) {
                self.animate()
            } else if let transform = self.spinnerBaseTransform {
                self.imageView.transform = transform
            }
        }
    }
    
    // animate Udacity imageView while network activity
    func animate() {
        dispatch_async(dispatch_get_main_queue()) {
            UIView.animateWithDuration(0.001,
                delay: 0.0,
                options: UIViewAnimationOptions.CurveEaseInOut,
                animations: { self.imageView.transform =
                    CGAffineTransformConcat(self.imageView.transform, CGAffineTransformMakeRotation((CGFloat(60.0) * CGFloat(M_PI)) / CGFloat(180.0)) )},
                completion: { something in
                    if self.activityInProgress {
                        self.animate()
                    } else {
                        // TODO: this snaps to position at then end, we should perform the final animation.
                        self.imageView.transform = self.spinnerBaseTransform
                    }
            })
        }
    }
    
    func resetLoginStatusLabel() {
        loginStatusLabel?.text = ""
        loginStatusLabel?.hidden = true
    }
    
    func endTextEditing() {
        usernameTextField?.endEditing(false)
        passwordTextField?.endEditing(false)
    }
    
    // MARK: Gestures
    
    func handleTap(sender: UIGestureRecognizer) {
        endTextEditing()
    }
    
    // MARK: Authentication
    
    func handleAuthenticationResponse(success: Bool, error: NSError?) {
        Logger.info("should stop network activity")
        self.networkActivity(false)
        if success {
            self.passwordTextField.text = ""
            self.transitionSucessfulLoginSegue()
        } else {
            dispatch_async(dispatch_get_main_queue()) {
                if let reason = error {
                    self.loginStatusLabel?.text = "!! \(reason.localizedDescription)"
                } else {
                    self.loginStatusLabel?.text = "!! Login failed"
                }
                self.loginStatusLabel.hidden = false
            }
        }
    }
    
    func resetStateAfterUserLogout() {
        Logger.info("Logging out...")
        manager = MorMessagesManager()
        resetLoginStatusLabel()
    }
    
    @IBAction func segueToLoginScreen(segue: UIStoryboardSegue) {
        resetStateAfterUserLogout()
    }
}



