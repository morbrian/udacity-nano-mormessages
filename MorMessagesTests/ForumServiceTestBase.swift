//
//  AuthenticationRequestAction.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/18/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import XCTest
@testable import MorMessages

class ForumServiceTestBase: XCTestCase {
    
    let Username = "sampleuser"
    let Password = "changeme"
    
    let sampleForums: [Forum] = [] //[ForumServiceAuthenticationTests.randomSampleForum()]

    class func randomSampleForum() -> Forum {
        let state: [String:AnyObject] = [
            ForumService.ForumJsonKey.Title : "title-\(NSUUID().UUIDString)",
            ForumService.ForumJsonKey.Description : "description-\(NSUUID().UUIDString)",
            ForumService.ForumJsonKey.ImageUrl : "https://robohash.org/\(NSUUID().UUIDString)"
        ]
        return Forum.produceWithState(state)!
    }
    
    class func randomSampleMessage(forum: Forum) -> Message {
        let state: [String:AnyObject] = [
            ForumService.ForumJsonKey.Text : "text-\(NSUUID().UUIDString)",
            ForumService.ForumJsonKey.ImageUrl : "imageUrl-\(NSUUID().UUIDString)"
        ]
        let message = Message.produceWithState(state)!
        message.forum = forum
        return message
    }
    
    func justWait() {
        waitForExpectationsWithTimeout(5) { error in
            XCTAssertNil(error, "Whoami Error")
        }
    }
    
    func doLogin(expectation: XCTestExpectation) {
        let service = ForumService.sharedInstance()
        service.login(username: Username, password: Password) {
            identity, error in
            XCTAssertNotNil(identity, "identity should not be nil")
            XCTAssertNil(error, "error should be nil")
            XCTAssertEqual(self.Username, identity, "correct username")
            expectation.fulfill()
        }
    }
    
    func doWhoami(expectation: XCTestExpectation) {
        let service = ForumService.sharedInstance()
        service.whoami() {
            identity, error in
            XCTAssertNotNil(identity, "identity should not be nil")
            XCTAssertNil(error, "error should be nil")
            XCTAssertEqual(self.Username, identity, "correct username")
            expectation.fulfill()
        }
    }
    
    func doLogout(expectation: XCTestExpectation) {
        let service = ForumService.sharedInstance()
        service.logout() {
            error in
            XCTAssertNil(error, "error should be nil")
            expectation.fulfill()
        }
    }

}