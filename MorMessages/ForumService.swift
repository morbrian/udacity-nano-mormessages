//
//  ForumService.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/17/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import Foundation

class ForumService {
    
    struct DateFormat {
        static let ISO8601 = "yyyy-MM-dd'T'HH:mm:ss.SZZZZZ"
    }
    
    struct Locale {
        static let EN_US_POSIX = "en_US_POSIX"
    }
    
    static var DateFormatter: NSDateFormatter {
        let dateFormatter = NSDateFormatter()
        let enUSPosixLocale = NSLocale(localeIdentifier: ForumService.Locale.EN_US_POSIX)
        dateFormatter.locale = enUSPosixLocale
        dateFormatter.dateFormat = ForumService.DateFormat.ISO8601
        return dateFormatter
    }
    
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
    
    private func dateFromString(string: String?) -> NSDate? {
        let dateFormatter = ForumService.DateFormatter
        if let string = string {
            return dateFormatter.dateFromString(string)
        } else {
            return nil
        }
    }
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
    }
    
    struct ForumJsonValue {
        static let Success = 0
        static let Error = 2
        static let Unauthorized = 3
    }
    
}

