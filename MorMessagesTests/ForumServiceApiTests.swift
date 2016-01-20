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
    
    func testCreateForum() {
        let expectation = expectationWithDescription("create forum")

        let submittedForum = ForumServiceTestBase.randomSampleForum()
        let service = ForumService.sharedInstance()
        service.createForum(submittedForum) {
            forum, error in
            XCTAssertNil(error, "error should be nil")
            XCTAssertNotNil(forum, "forum should not be nil")
            XCTAssertEqual(forum!.title, submittedForum.title, "title should be equal")
            XCTAssertEqual(forum!.uuid, submittedForum.uuid, "forum uuid should match")
            XCTAssertNotNil(forum!.id, "forum id should not be nil")
            XCTAssertTrue(forum!.id!.intValue > 0, "forum id should be greater than 0")
            expectation.fulfill()
        }
        
        justWait()
    }
    
    func testListForums() {
        let expectation = expectationWithDescription("list forums")
        
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
    
    func testListMessages() {
        // create new forum
        var expectation = expectationWithDescription("create new forum")
        var newForum = ForumServiceTestBase.randomSampleForum()
        let service = ForumService.sharedInstance()
        service.createForum(newForum) {
            forum, error in
            XCTAssertNil(error, "error should be nil")
            XCTAssertNotNil(forum, "forums should not be nil")
            newForum = forum!
            expectation.fulfill()
        }
        justWait()

        // get empty message list from new forum
        expectation = expectationWithDescription("get empty message list")
        service.listMessagesInForum(newForum) {
            messages, error in
            XCTAssertNil(error, "error should be nil")
            XCTAssertNotNil(messages, "messages should not be nil")
            XCTAssertEqual(0, messages!.count, "message list should be empty")
            expectation.fulfill()
        }
        justWait()
        
        expectation = expectationWithDescription("create new message")
        let newMessage = ForumServiceTestBase.randomSampleMessage(newForum)
        service.createMessage(newMessage) {
            message, error in
            XCTAssertNil(error, "error should be nil")
            XCTAssertNotNil(message, "message should not be nil")
            XCTAssertEqual(message!.text, newMessage.text, "message text should match")
            XCTAssertEqual(message!.imageUrl, newMessage.imageUrl, "message imageUrl should match")
            XCTAssertEqual(message!.uuid, newMessage.uuid, "message uuid should match")
            XCTAssertNotNil(message!.id, "message id should not be nil")
            XCTAssertTrue(message!.id!.intValue > 0, "message id should be greater than 0")
            expectation.fulfill()
        }
        justWait()
        
        // get empty message list from new forum
        expectation = expectationWithDescription("checking list after added message")
        service.listMessagesInForum(newForum) {
            messages, error in
            XCTAssertNil(error, "error should be nil")
            XCTAssertNotNil(messages, "messages should not be nil")
            XCTAssertEqual(1, messages!.count, "message list should contain one new message")
            expectation.fulfill()
        }
        justWait()
    }

    
}
