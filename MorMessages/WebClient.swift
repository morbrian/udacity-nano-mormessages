//
//  WebClient.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/17/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import Foundation

// MARK: - Class WebClient

// WebClient
// Base Class for general interactions with any Web Service API that produces JSON data.
public class WebClient {
    
    var session: NSURLSession!
    
    init(basicAuthCredentials: String? = nil) {
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let cookieStorage = NSHTTPCookieStorage()
        cookieStorage.cookieAcceptPolicy = NSHTTPCookieAcceptPolicy.Always
        config.HTTPCookieStorage = cookieStorage
        if let basicAuthCredentials = basicAuthCredentials {
            config.HTTPAdditionalHeaders = ["Authorization" : basicAuthCredentials]
        }
        self.session = NSURLSession(configuration: config, delegate: SessionDelegate(), delegateQueue: nil)
    }
    
    public class func basicAuthFromCredentials(credentials: String)  -> String {
        let userPasswordData = credentials.dataUsingEncoding(NSUTF8StringEncoding)
        let base64EncodedCredential = userPasswordData!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions())
        return "Basic \(base64EncodedCredential)"
    }
    
    // optional data maniupation function
    // if set will modify the data before handing it off to the parser.
    // Common Use Case: some web services include extraneous content
    //                  before or after the desired JSON content in response data.
    public var prepareData: ((NSData) -> NSData?)?
    
    // encodeParameters
    // convert dictionary to parameterized String appropriate for use in an HTTP URL
    public static func encodeParameters(params: [String: AnyObject]) -> String {
        let queryItems = params.map { NSURLQueryItem(name:$0, value:"\($1)")}
        let components = NSURLComponents()
        components.queryItems = queryItems
        return components.percentEncodedQuery ?? ""
    }
    
    // createHttpRequestUsingMethod
    // Creates fuly configured NSURLRequest for making HTTP POST requests.
    // urlString: properly formatted URL string
    // withBody: body of the post request, not necessarily JSON or any particular format.
    // includeHeaders: field-name / value pairs for request headers.
    public func createHttpRequestUsingMethod(method: String, var forUrlString urlString: String, withBody body: NSData? = nil,
        includeHeaders requestHeaders: [String:String]? = nil,
        includeParameters requestParameters: [String:AnyObject]? = nil) -> NSURLRequest? {
            
            if (method == WebClient.HttpGet && body != nil) {
                Logger.error("Programmer Error: Http GET request created with non nil body.")
            }
            if ((method == WebClient.HttpPost || method == WebClient.HttpPut) && body == nil) {
                Logger.error("Programmer Error: Http \(method) request created but no content body specified")
            }
            
            if let requestParameters = requestParameters {
                urlString = "\(urlString)?\(WebClient.encodeParameters(requestParameters))"
            }
            
            if let requestUrl = NSURL(string: urlString) {
                var request = NSMutableURLRequest(URL: requestUrl)
                request.HTTPMethod = method
                if let requestHeaders = requestHeaders {
                    request = addRequestHeaders(requestHeaders, toRequest: request)
                }
                if let body = body {
                    request.HTTPBody = body
                }
                return request
            } else {
                return nil
            }
            
    }
    
    // executeRequest
    // Execute the request in a background thread, and call completionHandler when done.
    // Performs the work of checking for general errors and then
    // turning raw data into JSON data to feed to completionHandler.
    public func executeRequest(request: NSURLRequest, completionHandler: (jsonData: AnyObject?, error: NSError?) -> Void) {
        let task = session.dataTaskWithRequest(request) { data, response, error in
            // this is a general communication error
            if error != nil {
                Logger.debug(error!.description)
                completionHandler(jsonData: nil, error: error)
                return
            }
            
            if let response = response as? NSHTTPURLResponse
                where response.statusCode >= 400 {
                    var httpError: NSError?
                    if response.statusCode == 401 || response.statusCode == 403 {
                        httpError = WebClient.errorWithMessage("Authentication Failed", code: response.statusCode)
                    } else {
                        httpError = WebClient.errorWithMessage("unexpected http response (\(response.statusCode))", code: response.statusCode)
                    }
                    completionHandler(jsonData: nil, error: httpError)
                    return
            }
            
            let (jsonData, parsingError): (AnyObject?, NSError?) =
            self.parseJsonFromData(data!)
            
            if let parsingError = parsingError {
                completionHandler(jsonData: nil, error: parsingError)
                return
            }
            
            completionHandler(jsonData: jsonData, error: nil)
        }
        task.resume()
    }
    
    // quick check to see if URL is valid and responsive
    public func pingUrl(urlString: String, completionHandler: (reply: Bool, error: NSError?) -> Void) {
        if let request = createHttpRequestUsingMethod(WebClient.HttpHead, forUrlString: urlString) {
            let task = session.dataTaskWithRequest(request) { data, response, error in
                if let error = error {
                    Logger.debug(error.description)
                }
                completionHandler(reply: error == nil, error: error)
            }
            task.resume()
        } else {
            completionHandler(reply: false, error: WebClient.errorForCode(.UnableToCreateRequest))
        }
    }
    
    struct Caches {
        static let imageCache = ImageCache()
    }
    
    // MARK: - All purpose task method for images
    
    func taskForImageUrlString(urlString: String?, completionHandler: (imageData: NSData?, error: NSError?) ->  Void) -> NSURLSessionTask? {
        if let urlString = urlString, url = NSURL(string: urlString) {
            let request = NSURLRequest(URL: url)
            let task = session.dataTaskWithRequest(request) {data, response, downloadError in
                
                if let error = downloadError {
                    //let newError = TheMovieDB.errorForData(data, response: response, error: downloadError)
                    dispatch_async(dispatch_get_main_queue(), {
                        completionHandler(imageData: nil, error: error)
                    })
                } else {
                    dispatch_async(dispatch_get_main_queue(), {
                        completionHandler(imageData: data, error: nil)
                    })
                }
            }
            task.resume()
            return task
        } else {
            return nil
        }
    }
    
    // MARK: Private Helpers
    
    // Produces usable JSON object from the raw data.
    func parseJsonFromData(data: NSData) -> (jsonData: AnyObject?, error: NSError?) {
        var mutableData = data
        var parsingError: NSError? = nil
        if let prepareData = prepareData,
            modifiedData = prepareData(data) {
                mutableData = modifiedData
        }
        let jsonData: AnyObject?
        do {
            jsonData = try NSJSONSerialization.JSONObjectWithData(mutableData, options: NSJSONReadingOptions.AllowFragments)
        } catch let error as NSError {
            parsingError = error
            jsonData = nil
        }
        return (jsonData, parsingError)
    }
    
    // helper function adds request headers to request
    private func addRequestHeaders(requestHeaders: [String:String], toRequest request: NSMutableURLRequest) -> NSMutableURLRequest {
        let request = request
        for (field, value) in requestHeaders {
            request.addValue(value, forHTTPHeaderField: field)
        }
        return request
    }
}

// MARK: - Constants

extension WebClient {
    
    static let JsonContentType = "application/json"
    static let HttpHeaderAccept = "Accept"
    static let HttpHeaderContentType = "Content-Type"
    static let HttpScheme = "http"
    static let HttpsScheme = "https"
    static let HttpHead = "HEAD"
    static let HttpPost = "POST"
    static let HttpGet = "GET"
    static let HttpPut = "PUT"
    static let HttpDelete = "DELETE"
}

// MARK: - Error Handling

extension WebClient {
    
    private static let ErrorDomain = "WebClient"
    
    enum ErrorCode: Int, CustomStringConvertible {
        case UnableToCreateRequest
        
        var description: String {
            switch self {
            case UnableToCreateRequest: return "Could Not Create Request"
                // TODO: why does xcode warn me that default will never be executed?
                //default: return "Unknown Error"
            }
        }
    }
    
    // createErrorWithCode
    // helper function to simplify creation of error object
    static func errorForCode(code: ErrorCode) -> NSError {
        let userInfo = [NSLocalizedDescriptionKey : code.description]
        return NSError(domain: WebClient.ErrorDomain, code: code.rawValue, userInfo: userInfo)
    }
    
    static func errorWithMessage(message: String, code: Int) -> NSError {
        let userInfo = [NSLocalizedDescriptionKey : message]
        return NSError(domain: WebClient.ErrorDomain, code: code, userInfo: userInfo)
    }
}


// learned from: http://stackoverflow.com/questions/34327857/ios9-self-signed-certificate-and-app-transport-security
class SessionDelegate: NSObject, NSURLSessionDelegate {
    func URLSession(session: NSURLSession,
        didReceiveChallenge challenge: NSURLAuthenticationChallenge,
        completionHandler: (NSURLSessionAuthChallengeDisposition,
        NSURLCredential?) -> Void) {
            if let serverTrust = challenge.protectionSpace.serverTrust {
                completionHandler(NSURLSessionAuthChallengeDisposition.UseCredential,NSURLCredential(forTrust: serverTrust))
            }
    }
}



