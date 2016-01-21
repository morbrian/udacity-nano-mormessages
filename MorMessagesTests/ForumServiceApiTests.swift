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
        // create new forum
        createNewForum()
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
        let newForum = createNewForum()
        
        // get empty message list from new forum
        listSinglePageOfMessagesInForum(newForum!, expectedCount: 0)
        
        createMessageInForum(newForum!)
        
        // get empty message list from new forum
        listSinglePageOfMessagesInForum(newForum!, expectedCount: 1)
    }
    
    func testListMessagesWithOffsetAndResultSize() {
        // create new forum
        let newForum = createNewForum()
        
        // get empty message list from new forum
        listMessagesInForum(newForum!, expectedCount: 0)
        
        var expectedMessages = [Message]()
        for _ in 0..<10 {
            expectedMessages += [createMessageInForum(newForum!)!]
        }
        
        // get empty message list from new forum
        listMessagesInForum(newForum!, offset: 0, resultSize: 5, expectedCount: expectedMessages.count)
    }
    
    func createNewForum() -> Forum? {
        let expectation = expectationWithDescription("create new forum")
        var submittedForum = ForumServiceTestBase.randomSampleForum()
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
            submittedForum = forum!
        }
        justWait()
        return submittedForum
    }
    
    func listMessagesInForum(forum: Forum, offset: Int = 0, resultSize: Int = 50, expectedCount: Int) -> [Message]? {
        var resultMessages = [Message]()
        for i in 0..<(expectedCount/resultSize) {
            let response = listSinglePageOfMessagesInForum(forum, offset: i * resultSize, resultSize: resultSize, expectedCount: resultSize)
            XCTAssertNotNil(response, "message list response should not be nil")
            resultMessages += response!
        }
        XCTAssertEqual(resultMessages.count, expectedCount, "should return correct number of messages")
        return resultMessages
    }
    
    func listSinglePageOfMessagesInForum(forum: Forum, offset: Int = 0, resultSize: Int = 50, expectedCount: Int) -> [Message]? {
        let expectation = expectationWithDescription("get empty message list")
        let service = ForumService.sharedInstance()
        var resultMessages: [Message]?
        service.listMessagesInForum(forum, offset: offset, resultSize: resultSize) {
            messages, error in
            XCTAssertNil(error, "error should be nil")
            XCTAssertNotNil(messages, "messages should not be nil")
            XCTAssertEqual(expectedCount, messages!.count, "message list size should match expected")
            expectation.fulfill()
            resultMessages = messages
        }
        justWait()
        return resultMessages
    }

    func createMessageInForum(forum: Forum) -> Message? {
        let expectation = expectationWithDescription("create new message")
        let newMessage = ForumServiceTestBase.randomSampleMessage(forum)
        let service = ForumService.sharedInstance()
        var resultMessage: Message?
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
            resultMessage = message
        }
        justWait()
        return resultMessage
    }
    
}
