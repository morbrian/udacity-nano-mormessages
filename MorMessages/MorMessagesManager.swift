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
                self.handleLoginResponse(username, password: password, authType: .MorMessagesUsernameAndPassword,
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
    
    func listForums(offset offset: Int = 0, resultSize: Int = 100, greaterThan: NSDate = ToolKit.DateKit.Epoch,
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
    
    func createMessageWithText(text: String, inForum forumUuid: String, completionHandler: (message: Message?, error: NSError?) -> Void) {
        let state = [
            ForumService.ForumJsonKey.ForumUuid:forumUuid,
            ForumService.ForumJsonKey.Text:text
        ]
        var pairs = [String?]()
        for (key,value) in state {
            pairs += [BaseEntity.stringForSingleKey(key, andValue: value)]
        }
        let jsonBody = BaseEntity.jsonData(pairs.filter({$0 != nil}).map({$0!}))
        forumService.createMessageWithBody(jsonBody, inForum: forumUuid, completionHandler: completionHandler)
    }
    
    func listMessagesInForum(forum: Forum, offset: Int = 0, resultSize: Int = 100, greaterThan: NSDate = ToolKit.DateKit.Epoch,
        completionHandler: (messages: [Message]?, error: NSError?) -> Void) {
            forumService.listMessagesInForum(forum, offset: offset, resultSize: resultSize, greaterThan: greaterThan,
                completionHandler: completionHandler)
    }
    
    func subscribeToForum(forum: Forum, completionHandler: (subscription: Subscription?, error: NSError?) -> Void) {
        if let forumUuid = forum.uuid,
            userIdentity = currentUser?.identity {
            let subscription = Subscription(userIdentity: userIdentity, topicId: forumUuid)
            forumService.createSubscription(subscription, completionHandler: completionHandler)
        } else {
            completionHandler(subscription: nil, error: nil)
        }
    }
    
    func activateSubscription(subscription: Subscription, completionHandler: (error: NSError?) -> Void) {
        forumService.activateSubscription(subscription, completionHandler: completionHandler)
    }
    
    func maintainActiveSubscription() {
        forumService.maintainActiveSubscription()
    }
    
    func unsubscribe(subscription: Subscription) {
        forumService.unsubscribe(subscription)
    }

    // handles response after login attempt
    // userIdentity: unique key identifying the now logged in user after success
    // authType: the type of authenticatio used
    private func handleLoginResponse(userIdentity: String?, password: String?, authType: AuthenticationType, error: NSError?,
        completionHandler: (success: Bool, error: NSError?) -> Void) {
            if let error = error {
                completionHandler(success: false, error: error)
            } else if let userIdentity = userIdentity {
                currentUser = UserInfo(identity: userIdentity)
                if let password = password {
                    forumService.useBasicAuth("\(userIdentity):\(password)")
                }
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