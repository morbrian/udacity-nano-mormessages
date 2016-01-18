//
//  ForumServiceTests.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/17/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import XCTest
@testable import MorMessages

class ForumServiceTests: XCTestCase {
    
    static let Username = "sampleuser"
    static let Password = "changeme"
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testLoginShouldRespondWithIdentity() {
        let expectation = expectationWithDescription("login request")
        doLogin(expectation)
        justWait()
    }
    
    func testWhoamiShouldRespondWithIdentity() {
        doLogin(expectationWithDescription("login request"))
        justWait()
        
        doWhoami(expectationWithDescription("whoami request"))
        justWait()
    }
    
    func testLogoutShouldRemoveIdentity() {
        doLogin(expectationWithDescription("login request"))
        justWait()
        
        doWhoami(expectationWithDescription("whoami request"))
        justWait()
        
        doLogout(expectationWithDescription("logout request"))
        justWait()
        
        // verify logout actually cleared our identity
        let service = ForumService.sharedInstance()
        let expectation = expectationWithDescription("final whoami request")
        service.whoami() {
            identity, error in
            XCTAssertNotEqual(ForumServiceTests.Username, identity, "removed username")
            XCTAssertNil(error, "error should be nil")
            expectation.fulfill()
        }
        justWait()
    }
    
    func justWait() {
        waitForExpectationsWithTimeout(5) { error in
            XCTAssertNil(error, "Whoami Error")
        }
    }
    
    func doLogin(expectation: XCTestExpectation) {
        let service = ForumService.sharedInstance()
        service.login(username: ForumServiceTests.Username, password: ForumServiceTests.Password) {
            identity, error in
            XCTAssertNotNil(identity, "identity should not be nil")
            XCTAssertNil(error, "error should be nil")
            XCTAssertEqual(ForumServiceTests.Username, identity, "correct username")
            expectation.fulfill()
        }
    }
    
    func doWhoami(expectation: XCTestExpectation) {
        let service = ForumService.sharedInstance()
        service.whoami() {
            identity, error in
            XCTAssertNotNil(identity, "identity should not be nil")
            XCTAssertNil(error, "error should be nil")
            XCTAssertEqual(ForumServiceTests.Username, identity, "correct username")
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

