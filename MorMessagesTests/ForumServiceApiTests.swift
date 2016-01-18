//
//  ForumServiceApiTests.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/18/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import XCTest
@testable import MorMessages

class ForumServiceApiTests: ForumServiceTestBase {

    override func setUp() {
        doLogin(expectationWithDescription("login request"))
        justWait()
    }
    
    override func tearDown() {
        doLogout(expectationWithDescription("logout request"))
        justWait()
    }
    
    func testListForums() {
        let expectation = expectationWithDescription("login request")
        
        let service = ForumService.sharedInstance()
        service.listForums() {
            forums, error in
            XCTAssertNil(error, "error should be nil")
            XCTAssertNotNil(forums, "forums should not be nil")
            XCTAssertTrue(forums!.count > 0, "forums list should not be empty")
            expectation.fulfill()
        }
        
        justWait()
    }

    
}
