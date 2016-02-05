//
//  ForumServiceTests.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/17/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import XCTest
@testable import MorMessages

class ForumServiceAuthenticationTests: ForumServiceTestBase {
    
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
    
    // this started failing when we switched to pure Basic Auth instead of FORM
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
            XCTAssertNotEqual(ForumServiceTestBase.Username, identity, "removed username")
            XCTAssertNil(error, "error should be nil")
            expectation.fulfill()
        }
        justWait()
    }
    
}

