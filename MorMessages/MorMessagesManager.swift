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
    
    func logout(completionHandler: (error: NSError?) -> Void) {
        self.currentUser = nil
        forumService.logout(completionHandler)
    }
    
    func whoami(completionHandler: (identity: String?, error: NSError?) -> Void) {
        forumService.whoami(completionHandler)
    }
    
    func listForums(offset offset: Int = 0, resultSize: Int = 100, greaterThan: Int = 0,
        completionHandler: (forums: [Forum]?, error: NSError?) -> Void) {
            forumService.listForums(offset: offset, resultSize: resultSize, greaterThan: greaterThan,
                completionHandler: completionHandler)
    }
    
    func createForum(forum: Forum, completionHandler: (forum: Forum?, error: NSError?) -> Void) {
        forumService.createForum(forum, completionHandler: completionHandler)
    }
    
    func createForumWithTitle(title: String, desc: String, imageUrl: String,
        completionHandler: (forum: Forum?, error: NSError?) -> Void) {
        let state = [
            ForumService.ForumJsonKey.Title:title,
            ForumService.ForumJsonKey.Description:desc,
            ForumService.ForumJsonKey.ImageUrl:imageUrl
        ]
        var pairs = [String?]()
        for (key,value) in state {
            pairs += [BaseEntity.stringForSingleKey(key, andValue: value)]
        }
        let jsonBody = BaseEntity.jsonData(pairs.filter({$0 != nil}).map({$0!}))
        forumService.createForumWithBody(jsonBody, completionHandler: completionHandler)
    }
    
    func listMessagesInForum(forum: Forum, offset: Int = 0, resultSize: Int = 100, greaterThan: Int = 0,
        completionHandler: (messages: [Message]?, error: NSError?) -> Void) {
            forumService.listMessagesInForum(forum, offset: offset, resultSize: resultSize, greaterThan: greaterThan,
                completionHandler: completionHandler)
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