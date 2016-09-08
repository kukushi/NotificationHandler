//
//  NotificationHandlerTests.swift
//  NotificationHandlerTests
//
//  Created by Xing He on 11/4/15.
//  Copyright © 2015 Xing He. All rights reserved.
//

import XCTest
@testable import NotificationHandler

let NotificationCenter = Foundation.NotificationCenter.default

class TestObject: NSObject {
    var count = 0
    override init () {
        // nothing to do...
    }
    
    func plusOne() {
        count += 1
    }
    
    func plusTwo(_ notification: Notification) {
        print("### Notification: \(notification)")
        count += 2
    }
}

class NotificationHandlerTests: XCTestCase {
    var testObject: TestObject!
    
    override func setUp() {
        testObject = TestObject()
        super.setUp()
    }
    
    // MARK: Block
    
    func testObserveWithBlock() {
        let notificationName = #function
        testObject.notificationHandler.observe(notificationName) {[unowned self] notification in
            self.testObject.count += 1
        }
        
        NotificationCenter.post(name: Notification.Name(rawValue: notificationName), object: nil)
        
        let expection = expectation(description: "")
        XCTAssert(self.testObject.count == 1)
        expection.fulfill()
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testObserveWithBlockMangTimes() {
        let notificationName = #function
        testObject.notificationHandler.observe(notificationName) {[unowned self] notification in
            self.testObject.count += 1
        }
        
        for _ in 0..<1000 {
            NotificationCenter.post(name: Notification.Name(rawValue: notificationName), object: nil)
        }
        
        let expection = expectation(description: "")
        XCTAssert(self.testObject.count == 1000)
        expection.fulfill()
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testObserverBecomeNilWithBlock() {
        let notificationName = #function
        testObject.notificationHandler.observe(notificationName) {[unowned self] (notification) -> Void in
            if self.testObject != nil {
                self.testObject.count += 1
            }
        }
        NotificationCenter.post(name: Notification.Name(rawValue: notificationName), object: nil)
        
        let expection = expectation(description: "")
        XCTAssert(testObject.count == 1)
        expection.fulfill()
        
        testObject = nil
        
        NotificationCenter.post(name: Notification.Name(rawValue: notificationName), object: nil)
        
        let expection2 = expectation(description: "")
        expection2.fulfill()
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    // MARK: Selector
    
    func testObserveWithSelector() {
        let notificationName = #function
        testObject.notificationHandler.observe(notificationName, selector: #selector(TestObject.plusOne))
        
        NotificationCenter.post(name: Notification.Name(rawValue: notificationName), object: nil)
        
        let expection = expectation(description: "")
        XCTAssert(self.testObject.count == 1)
        expection.fulfill()
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testObserveWithSelectorManyTimes() {
        let notificationName = #function
        testObject.notificationHandler.observe(notificationName, selector: #selector(TestObject.plusOne))
        
        for _ in 0..<1000 {
            NotificationCenter.post(name: Notification.Name(rawValue: notificationName), object: nil)
        }
        
        let expection = expectation(description: "")
        XCTAssert(self.testObject.count == 1000)
        expection.fulfill()
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testObserveWithSelectorAndParameters() {
        let notificationName = #function
        testObject.notificationHandler.observe(notificationName, selector: #selector(TestObject.plusTwo(_:)))
        
        NotificationCenter.post(name: Notification.Name(rawValue: notificationName), object: nil)
        
        let expection = expectation(description: "")
        XCTAssert(self.testObject.count == 2)
        expection.fulfill()
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testUnobserveWithSelector() {
        let notificationName = #function
        testObject.notificationHandler.observe(notificationName, selector: #selector(TestObject.plusOne))
        NotificationCenter.post(name: Notification.Name(rawValue: notificationName), object: nil)
        
        let expection = expectation(description: "")
        XCTAssert(self.testObject.count == 1)
        expection.fulfill()
        
        testObject.notificationHandler.unobserve(notificationName)
        NotificationCenter.post(name: Notification.Name(rawValue: notificationName), object: nil)
        
        let expection2 = expectation(description: "")
        XCTAssert(self.testObject.count == 1)
        expection2.fulfill()
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    // MARK: Block and Selector
    
    func testObserveWithSelectorAndBlock() {
        let notificationName = #function
        testObject.notificationHandler.observe(notificationName, selector: #selector(TestObject.plusOne))
        testObject.notificationHandler.observe(notificationName) {[unowned self] notification in
            self.testObject.count += 1
        }
        NotificationCenter.post(name: Notification.Name(rawValue: notificationName), object: nil)
        
        let expection = expectation(description: "")
        XCTAssert(testObject.count == 2)
        expection.fulfill()
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testObserverBecomeNilWithSelector() {
        let notificationName = #function
        testObject.notificationHandler.observe(notificationName, selector: #selector(TestObject.plusOne))
        NotificationCenter.post(name: Notification.Name(rawValue: notificationName), object: nil)
        
        let expection = expectation(description: "")
        XCTAssert(testObject.count == 1)
        expection.fulfill()
        
        testObject = nil
        
        NotificationCenter.post(name: Notification.Name(rawValue: notificationName), object: nil)
        
        
        let expection2 = expectation(description: "")
        expection2.fulfill()
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    override func tearDown() {
        super.tearDown()
    }
}
