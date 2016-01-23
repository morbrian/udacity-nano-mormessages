//
//  MorMessagesManager.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/22/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import Foundation

class MorMessagesManager {
    
    private var forumService: ForumService!
    
    // user currently using manager
    var currentUser: UserInfo?
    
    // authentication mechanism the user used to login
    private var authType: AuthenticationType = .NotAuthenticated
    
    
    init() {
        forumService = ForumService.sharedInstance()
    }
    
    // return true if the user has authenticated
    var authenticated: Bool {
        return currentUser != nil
    }
    
    // authenticate the user by username and password with the Udacity service.
    // username: udacity username
    // password: udacity password
    func authenticateByUsername(username: String, withPassword password: String,
        completionHandler: (success: Bool, error: NSError?) -> Void) {
            forumService.login(username: username, password: password){ identity, error in
                self.handleLoginResponse(username, authType: .MorMessagesUsernameAndPassword,
                    error: error, completionHandler: completionHandler)
            }
    }
    
    func whoami(completionHandler: (identity: String?, error: NSError?) -> Void) {
        forumService.whoami(completionHandler)
    }

    // handles response after login attempt
    // userIdentity: unique key identifying the now logged in user after success
    // authType: the type of authenticatio used
    private func handleLoginResponse(userIdentity: String?, authType: AuthenticationType, error: NSError?,
        completionHandler: (success: Bool, error: NSError?) -> Void) {
            if let error = error {
                completionHandler(success: false, error: error)
            } else if let userIdentity = userIdentity {
                currentUser = UserInfo(identity: userIdentity)
                completionHandler(success: true, error: nil)
            } else {
                completionHandler(success: false, error: nil)
            }
    }
}

// MARK: - Authentication Type

enum AuthenticationType {
    case NotAuthenticated
    case MorMessagesUsernameAndPassword
}