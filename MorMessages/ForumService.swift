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
    private var webSocket: WebSocket?
    private var basicAuthCredentials: String?
    
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
    
    func useBasicAuth(authCredentials: String) {
        basicAuthCredentials = WebClient.basicAuthFromCredentials(authCredentials)
        webClient = WebClient(basicAuthCredentials: basicAuthCredentials)
    }
    
    func login(username username: String, password: String, completionHandler:
        (identity: String?, error: NSError?) -> Void) {
            if username.isEmpty {
                completionHandler(identity: nil, error: ForumService.errorForCode(.UsernameRequired))
                return
            }
            if password.isEmpty {
                completionHandler(identity: nil, error: ForumService.errorForCode(.PasswordRequired))
                return
            }
            if let request = webClient.createHttpRequestUsingMethod(WebClient.HttpPost,
                forUrlString: ForumService.ForumAction.LoginUrl,
                includeHeaders: ForumService.StandardHeaders,
                withBody: ForumService.Credentials(username: username, password: password)) {
                    webClient.executeRequest(request)
                        { jsonData, error in
                            if let error = error {
                                completionHandler(identity: nil, error: error)
                            } else if let status = Status(jsonData: jsonData) {
                                if status.code == ForumJsonValue.Success {
                                    completionHandler(identity: username, error: nil)
                                } else {
                                    completionHandler(identity: nil, error: ForumService.errorForCode(.LoginFailed))
                                }
                            } else {
                                completionHandler(identity: nil, error: ForumService.errorForCode(.LoginFailed))
                            }
                    }
            } else {
                completionHandler(identity: nil, error: ForumService.errorForCode(.FailedToMakeRequest))
            }
    }
    
    func whoami(completionHandler: (identity: String?, error: NSError?) -> Void) {
        if let request = webClient.createHttpRequestUsingMethod(WebClient.HttpGet,
            forUrlString: ForumService.ForumAction.WhoamiUrl,
            includeHeaders: ForumService.StandardHeaders) {
                webClient.executeRequest(request) {
                    jsonData, error in
                    
                    if let status = jsonData?.valueForKey(ForumJsonKey.Status) as? NSDictionary,
                        statusCode = status.valueForKey(ForumJsonKey.Code) as? Int
                        where statusCode != ForumJsonValue.Success {
                            completionHandler(identity: nil, error: ForumService.errorForCode(.LoginFailed))
                    } else if let data = jsonData?.valueForKey(ForumJsonKey.Data) as? NSDictionary,
                        let username = data.valueForKey(ForumJsonKey.Username) as? String {
                            completionHandler(identity: username, error: nil)
                    } else {
                        completionHandler(identity: nil, error: ForumService.errorForCode(.LoginFailed))
                    }
                }
        } else {
            Logger.error("failed to attempt request")
            completionHandler(identity: nil, error: ForumService.errorForCode(.FailedToMakeRequest))
        }
    }
    
    func logout(completionHandler: (error: NSError?) -> Void) {
        
        if let request = webClient.createHttpRequestUsingMethod(WebClient.HttpDelete,
            forUrlString: ForumService.ForumAction.LogoutUrl,
            includeHeaders: ForumService.StandardHeaders) {
                
                webClient.executeRequest(request) {
                    jsonData, error in
                    
                    if error == nil {
                        completionHandler(error: nil)
                    } else {
                        completionHandler(error: ForumService.errorForCode(.LogoutFailed))
                    }
                }
        } else {
            Logger.error("failed to attempt request")
            completionHandler(error: ForumService.errorForCode(.FailedToMakeRequest))
        }
    }
    
    func createForum(forum: Forum, completionHandler: (forum: Forum?, error: NSError?) -> Void) {
        createForumWithBody(forum.jsonData(), completionHandler: completionHandler)
    }
    
    func createForumWithBody(body: NSData, completionHandler: (forum: Forum?, error: NSError?) -> Void) {
        if let request = webClient.createHttpRequestUsingMethod(WebClient.HttpPut,
            forUrlString: ForumService.ForumAction.ForumUrl,
            includeHeaders: ForumService.StandardHeaders,
            withBody: body) {
                webClient.executeRequest(request) {
                    jsonData, error in
                    dispatch_async(dispatch_get_main_queue()) {
                        if error != nil {
                            completionHandler(forum: nil, error: ForumService.errorForCode(.CreateFailed))
                        } else if let jsonData = jsonData as? [String:AnyObject],
                            let newForum = Forum.produceWithState(jsonData) {
                                completionHandler(forum: newForum, error: nil)
                        } else {
                            completionHandler(forum: nil, error: ForumService.errorForCode(.UnexpectedResponseData))
                        }
                    }
                }
        } else {
            Logger.error("failed to attempt request")
            completionHandler(forum: nil, error: ForumService.errorForCode(.FailedToMakeRequest))
        }
    }
    
    func listForums(offset offset: Int = 0, resultSize: Int = 100, greaterThan: NSDate = ToolKit.DateKit.Epoch,
        completionHandler: (forums: [Forum]?, error: NSError?) -> Void) {
        let params: [String:NSObject] = [ "offset":offset, "resultSize":resultSize,
            "greaterThan":ToolKit.DateKit.DateFormatter.stringFromDate(greaterThan) ]
        if let request = webClient.createHttpRequestUsingMethod(WebClient.HttpGet,
            forUrlString: ForumService.ForumAction.ForumUrl,
            includeHeaders: ForumService.StandardHeaders,
            includeParameters: params) {
                webClient.executeRequest(request) {
                    jsonData, error in
                    dispatch_async(dispatch_get_main_queue()) {
                        if let jsonArray = jsonData as? [[String:AnyObject]] {
                            // parse each forum and produce an array of only valid Forum objects
                            let forums = jsonArray.map(Forum.produceWithState).filter({$0 != nil}).map({$0!})
                            completionHandler(forums: forums, error: nil)
                        } else {
                            completionHandler(forums: nil, error: ForumService.errorForCode(.UnexpectedResponseData))
                        }
                    }
                }
        } else {
            completionHandler(forums: nil, error: ForumService.errorForCode(.FailedToMakeRequest))
        }
    }
    
    func listMessagesInForum(forum: Forum, offset: Int = 0, resultSize: Int = 100, greaterThan: NSDate = ToolKit.DateKit.Epoch,
        completionHandler: (messages: [Message]?, error: NSError?) -> Void) {
            let params: [String:NSObject] = [ "offset":offset, "resultSize":resultSize,
                "greaterThan":ToolKit.DateKit.DateFormatter.stringFromDate(greaterThan) ]
        if let forumUuid = forum.uuid,
            request = webClient.createHttpRequestUsingMethod(WebClient.HttpGet,
            forUrlString: ForumService.ForumAction.MessageUrl(forumUuid),
            includeHeaders: ForumService.StandardHeaders,
            includeParameters: params) {
                webClient.executeRequest(request) {
                    jsonData, error in
                    dispatch_async(dispatch_get_main_queue()) {
                        if let jsonArray = jsonData as? [[String:AnyObject]] {
                            // parse each message and produce an array of only valid Forum objects
                            let messages = jsonArray.map(Message.produceWithState).filter({$0 != nil}).map({$0!})
                            Logger.info("Requesed resultSize(\(resultSize)), Received(\(messages.count))")
                            completionHandler(messages: messages, error: nil)
                        } else {
                            completionHandler(messages: nil, error: ForumService.errorForCode(.UnexpectedResponseData))
                        }
                    }
                }
        } else {
            Logger.error("failed to attempt request")
            completionHandler(messages: nil, error: ForumService.errorForCode(.FailedToMakeRequest))
        }
    }
    
    func subscribeToForum(forum: Forum, completionHandler: (error: NSError?) -> Void) {
        if let forumUuid = forum.uuid {
            let request = NSMutableURLRequest(URL: NSURL(string:"\(ForumAction.ForumSocketUrl)/\(forumUuid)")!)
            if let basicAuthCredentials = basicAuthCredentials {
                request.addValue(basicAuthCredentials, forHTTPHeaderField: "Authorization")
            }
            webSocket = WebSocket(request: request)
            webSocket!.allowSelfSignedSSL = true
            webSocket!.event.message = { data in
                
                if let text = data as? String,
                    textData = text.dataUsingEncoding(NSUTF8StringEncoding) {
                    
                    let (jsonData, parsingError): (AnyObject?, NSError?) =
                    self.webClient.parseJsonFromData(textData)
                    
                    if let parsingError = parsingError {
                        Logger.debug(parsingError.description)
                        return
                    }
                    if let jsonData = jsonData as? [String:AnyObject],
                        let textMessage = Message.produceWithState(jsonData) {
                            Logger.info("given state(\(jsonData))")
                            Logger.info("processed message(\(textMessage))")
                    }
                } else {
                    Logger.info("WebSocket Received Unknown Thing: \(data)")
                }
            }
            completionHandler(error: nil)
            Logger.info("Completed Subscribe to Forum(\(forumUuid)) with URL: \(ForumAction.ForumSocketUrl)/\(forumUuid)")
        } else {
            Logger.error("unable to subscribe, specified forum has no 'id'")
            completionHandler(error: ForumService.errorForCode(.WebSocketSubscribeError))
        }
    }
    
    func unsubscribeFromForum(forum: Forum) {
        if let webSocket = webSocket {
            webSocket.close()
        }
        webSocket = nil
    }
    
    
    func createMessage(message: Message, completionHandler: (message: Message?, error: NSError?) -> Void) {
        if let forum = message.forum,
            forumUuid = forum.uuid {
                createMessageWithBody(message.jsonData(), inForum: forumUuid, completionHandler: completionHandler)
        } else {
            Logger.error("failed to attempt request, forumId not specified on new message")
            completionHandler(message: nil, error: ForumService.errorForCode(.FailedToMakeRequest))
        }
    }
    
    func createMessageWithBody(body: NSData, inForum forumUuid: String, completionHandler: (message: Message?, error: NSError?) -> Void) {
        if let request = webClient.createHttpRequestUsingMethod(WebClient.HttpPut,
                forUrlString: ForumService.ForumAction.MessageUrl(forumUuid),
                includeHeaders: ForumService.StandardHeaders,
                withBody: body) {
                    webClient.executeRequest(request) {
                        jsonData, error in
                        dispatch_async(dispatch_get_main_queue()) {
                            if error != nil {
                                completionHandler(message: nil, error: ForumService.errorForCode(.CreateFailed))
                            } else if let jsonData = jsonData as? [String:AnyObject],
                                let newMessage = Message.produceWithState(jsonData) {
                                    completionHandler(message: newMessage, error: nil)
                            } else {
                                completionHandler(message: nil, error: ForumService.errorForCode(.UnexpectedResponseData))
                            }
                        }
                    }
        } else {
            Logger.error("failed to attempt request")
            completionHandler(message: nil, error: ForumService.errorForCode(.FailedToMakeRequest))
        }
    }

    // Optional client functionality I may or may not implement:
    //
    //    ForumEntity getForumById(Long forumId);
    //    ForumEntity modifyForum(ForumEntity forum);
    //    void deleteForum(Long forumId);
    //    MessageEntity getMessageById(Long messageId);
}

// MARK: - Constants

extension ForumService {
    
    static let BaseUrl = "https://mormessages.morbrian.com:8443/mormessages/api/rest"
    static let BaseSocketUrl = "wss://mormessages.morbrian.com:8443/mormessages/api/websocket"
    
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
        static func MessageUrl(forumUuid: String) -> String {
            return ForumUrl + "/" + forumUuid + "/message"
        }
        static let ForumSocketUrl = "\(BaseSocketUrl)/forum"
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
        static let ForumUuid = "forumUuid"
        static let Title = "title"
        static let Description = "description"
        static let ImageUrl = "imageUrl"
        static let Id = "id"
        static let CreatedTime = "createdTime"
        static let CreatedBy = "createdByUid"
        static let ModifiedTime = "modifiedTime"
        static let ModifiedBy = "modifiedByUid"
        static let Uuid = "uuid"
    }
    
    struct ForumJsonValue {
        static let Success = 0
        static let Error = 2
        static let Unauthorized = 3
    }
    
}

// MARK: - Errors {

extension ForumService {
    
    private static let ErrorDomain = "ForumService"
    
    private enum ErrorCode: Int, CustomStringConvertible {
        case UnexpectedResponseData, ResponseCodeNotSuccess, InsufficientDataLength, UsernameRequired,
        PasswordRequired, MissingFacebookToken, LoginFailed, LogoutFailed, CreateFailed, FailedToMakeRequest,
        WebSocketSubscribeError
        
        var description: String {
            switch self {
            case UnexpectedResponseData: return "Unexpected Response Data"
            case ResponseCodeNotSuccess: return "Response Code Not Success"
            case InsufficientDataLength: return "Insufficient Data Length In Response"
            case UsernameRequired: return "Must specify a username"
            case PasswordRequired: return "Must specify a password"
            case MissingFacebookToken: return "Facebook Has Not Authenticated User"
            case LoginFailed: return "Login Failed"
            case LogoutFailed: return "Logout Failed"
            case CreateFailed: return "Create Failed"
            case FailedToMakeRequest: return "Failed To Make Request"
            case WebSocketSubscribeError: return "Failed to subscribe with WebSocket"
            }
        }
    }
    
    class ForumServiceError: NSError {
        override init(domain: String, code: Int, userInfo dict: [NSObject : AnyObject]? ) {
            super.init(domain: domain, code: code, userInfo: dict)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override var description: String {
            if let recognizedError = ErrorCode(rawValue: code) {
                return recognizedError.description
            } else {
                return "unrecognized error"
            }
        }
    }
    
    // createErrorWithCode
    // helper function to simplify creation of error object
    private static func errorForCode(code: ErrorCode) -> NSError {
        let userInfo = [NSLocalizedDescriptionKey : code.description]
        return ForumServiceError(domain: ForumService.ErrorDomain, code: code.rawValue, userInfo: userInfo)
    }
    
    private static func errorWithMessage(message: String, code: Int) -> NSError {
        let userInfo = [NSLocalizedDescriptionKey : message]
        return ForumServiceError(domain: ForumService.ErrorDomain, code: code, userInfo: userInfo)
    }
}

