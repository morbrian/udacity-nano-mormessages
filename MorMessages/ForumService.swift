//
//  ForumService.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/17/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import Foundation

class ForumService {
    
    private var webClient: WebClient!
    
    // singleton instance
    class func sharedInstance() -> ForumService {
        struct Static {
            static let instance = ForumService(client: WebClient())
        }
        return Static.instance
    }
    
    // Initialize service
    // client: insteance of a WebClient
    private init(client: WebClient) {
        self.webClient = client
    }
    
    func login(username username: String, password: String, completionHandler:
        (identity: String?, error: String?) -> Void) {
            if let request = webClient.createHttpRequestUsingMethod(WebClient.HttpPost,
                forUrlString: ForumService.ForumAction.LoginUrl,
                includeHeaders: ForumService.StandardHeaders,
                withBody: ForumService.Credentials(username: username, password: password)) {
                    
                    //{"status":{"code":0,"type":"SUCCESS","details":"sampleuser"},"data":null}
                    webClient.executeRequest(request)
                        { jsonData, error in
                            if let status = jsonData?.valueForKey(ForumJsonKey.Status) as? NSDictionary,
                                statusCode = status.valueForKey(ForumJsonKey.Code) as? Int
                                where statusCode != ForumJsonValue.Success {
                                    completionHandler(identity: nil, error: "login failed: \(statusCode)")
                            } else if error == nil {
                                completionHandler(identity: username, error: nil)
                            } else {
                                completionHandler(identity: nil, error: "login failed")
                            }
                    }
                    
            }
    }
    
    func whoami(completionHandler: (identity: String?, error: String?) -> Void) {
        if let request = webClient.createHttpRequestUsingMethod(WebClient.HttpGet,
            forUrlString: ForumService.ForumAction.WhoamiUrl,
            includeHeaders: ForumService.StandardHeaders) {
                webClient.executeRequest(request) {
                    jsonData, error in
                    
                    if let status = jsonData?.valueForKey(ForumJsonKey.Status) as? NSDictionary,
                        statusCode = status.valueForKey(ForumJsonKey.Code) as? Int
                        where statusCode != ForumJsonValue.Success {
                            completionHandler(identity: nil, error: "login failed: \(statusCode)")
                    } else if let data = jsonData?.valueForKey(ForumJsonKey.Data) as? NSDictionary,
                        let username = data.valueForKey(ForumJsonKey.Username) as? String {
                            completionHandler(identity: username, error: nil)
                    } else {
                        completionHandler(identity: nil, error: "login failed")
                    }
                }
        }
    }
    
    func logout(completionHandler: (error: String?) -> Void) {
        
        if let request = webClient.createHttpRequestUsingMethod(WebClient.HttpDelete,
            forUrlString: ForumService.ForumAction.LogoutUrl,
            includeHeaders: ForumService.StandardHeaders) {
                
                webClient.executeRequest(request) {
                    jsonData, error in
                    
                    if error == nil {
                        completionHandler(error: nil)
                    } else {
                        completionHandler(error: "logout failed")
                    }
                }
        }
    }
    
    func createForum(forum: Forum, completionHandler: (forum: Forum?, error: String?) -> Void) {
        if let request = webClient.createHttpRequestUsingMethod(WebClient.HttpPut,
            forUrlString: ForumService.ForumAction.ForumUrl,
            includeHeaders: ForumService.StandardHeaders,
            withBody: forum.jsonData()) {
                webClient.executeRequest(request) {
                    jsonData, error in
                    dispatch_async(dispatch_get_main_queue()) {
                        if error != nil {
                            completionHandler(forum: nil, error: "failed to create forum on server")
                        } else if let jsonData = jsonData as? [String:AnyObject],
                            let newForum = Forum.produceWithState(jsonData) {
                            completionHandler(forum: newForum, error: nil)
                        } else {
                            completionHandler(forum: nil, error: "server responded with invalid data")
                        }
                    }
            }
        }
    }
    
    func listForums(completionHandler: (forums: [Forum]?, error: String?) -> Void) {
        if let request = webClient.createHttpRequestUsingMethod(WebClient.HttpGet,
            forUrlString: ForumService.ForumAction.ForumUrl,
            includeHeaders: ForumService.StandardHeaders) {
                webClient.executeRequest(request) {
                    jsonData, error in
                    dispatch_async(dispatch_get_main_queue()) {
                        if let jsonArray = jsonData as? [[String:AnyObject]] {
                            // parse each forum and produce an array of only valid Forum objects
                            let forums = jsonArray.map(Forum.produceWithState).filter({$0 != nil}).map({$0!})
                            completionHandler(forums: forums, error: nil)
                        } else {
                            completionHandler(forums: nil, error: "invalid server response")
                        }
                    }
                }
        }
    }
    
    func listMessagesInForum(forum: Forum, completionHandler: (messages: [Message]?, error: String?) -> Void) {
        if let forumId = forum.id,
            request = webClient.createHttpRequestUsingMethod(WebClient.HttpGet,
            forUrlString: ForumService.ForumAction.MessageUrl(forumId),
            includeHeaders: ForumService.StandardHeaders) {
                webClient.executeRequest(request) {
                    jsonData, error in
                    dispatch_async(dispatch_get_main_queue()) {
                        if let jsonArray = jsonData as? [[String:AnyObject]] {
                            // parse each forum and produce an array of only valid Forum objects
                            let messages = jsonArray.map(Message.produceWithState).filter({$0 != nil}).map({$0!})
                            completionHandler(messages: messages, error: nil)
                        } else {
                            completionHandler(messages: nil, error: "invalid server response")
                        }
                    }
                }
        }
    }
    
    func createMessage(message: Message, completionHandler: (message: Message?, error: String?) -> Void) {
        if let forum = message.forum,
            forumId = forum.id,
            request = webClient.createHttpRequestUsingMethod(WebClient.HttpPut,
                forUrlString: ForumService.ForumAction.MessageUrl(forumId),
                includeHeaders: ForumService.StandardHeaders,
                withBody: message.jsonData()) {
                    webClient.executeRequest(request) {
                        jsonData, error in
                        dispatch_async(dispatch_get_main_queue()) {
                            if error != nil {
                                completionHandler(message: nil, error: "failed to create forum on server")
                            } else if let jsonData = jsonData as? [String:AnyObject],
                                let newMessage = Message.produceWithState(jsonData) {
                                    completionHandler(message: newMessage, error: nil)
                            } else {
                                completionHandler(message: nil, error: "server responded with invalid data")
                            }
                        }
                    }
        } else {
            Logger.error("failed to attempt request for new message")
        }
    }

    // still want to support the exclusive filter
    //    List<MessageEntity> messageListFilteredById(Long forumId, Long lowId, Long highId);
    
//    ForumEntity getForumById(Long forumId);
//    ForumEntity modifyForum(ForumEntity forum);
//    void deleteForum(Long forumId);
//    MessageEntity getMessageById(Long messageId);
//    List<MessageEntity> messageList(Long forumId);
 
}

// MARK: - Constants

extension ForumService {
    
    static let BaseUrl = "http://localhost:8080/j2ee-websockets/api/rest"
    
    static let StandardHeaders: [String:String] = ["Content-Type":"application/json"]
    
    static func Credentials(username username: String, password: String) -> NSData {
        return "{ \"username\":\"\(username)\", \"password\":\"\(password)\" }".dataUsingEncoding(NSUTF8StringEncoding)!
    }
    
    struct ForumAction {
        static let AuthUrl = "\(BaseUrl)/auth"
        static let LoginUrl = "\(AuthUrl)/login"
        static let WhoamiUrl = "\(AuthUrl)/whoami"
        static let LogoutUrl = "\(AuthUrl)/logout"
        static let ForumUrl = "\(BaseUrl)/forum"
        static func MessageUrl(forumId: NSNumber) -> String {
            return ForumUrl + "/" + forumId.stringValue + "/message"
        }
    }
    
    struct ForumParameter {
        static let GreaterThanId = "greaterThanId"
        static let LessThanId = "lessThanId"
    }
    
    struct ForumJsonKey {
        static let Username = "username"
        static let Status = "status"
        static let Data = "data"
        static let Code = "code"
        static let Type = "type"
        static let Details = "details"
        static let Text = "text"
        static let ForumId = "forumId"
        static let Title = "title"
        static let Description = "description"
        static let ImageUrl = "imageUrl"
        static let Id = "id"
        static let CreatedTime = "createdTime"
        static let CreatedBy = "createdBy"
        static let ModifiedTime = "modifiedTime"
        static let ModifiedBy = "modifiedBy"
        static let Uuid = "uuid"
    }
    
    struct ForumJsonValue {
        static let Success = 0
        static let Error = 2
        static let Unauthorized = 3
    }
    
}

