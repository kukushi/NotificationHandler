//
//  NotificationHandlerTests.swift
//  NotificationHandlerTests
//
//  Created by Xing He on 11/4/15.
//  Copyright © 2015 Xing He. All rights reserved.
//

import XCTest
@testable import NotificationHandler

let NotificationCenter = NSNotificationCenter.defaultCenter()

class TestObject: NSObject {
    var count = 0
    override init () {
    }
    
    deinit {
    }
    
    func plusOne() {
        count += 1
    }
    
    func plusTwo(notification: NSNotification) {
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
    
    func testObserveWithBlock() {
        let notificationName =  __FUNCTION__
        testObject.notificationHandler.observe(notificationName) {[unowned self] notification in
            self.testObject.count += 1
        }
        
        NotificationCenter.postNotificationName(notificationName, object: nil)
        
        let expection = expectationWithDescription("")
        XCTAssert(self.testObject.count == 1)
        expection.fulfill()
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testObserveWithBlockMangTimes() {
        let notificationName =  __FUNCTION__
        testObject.notificationHandler.observe(notificationName) {[unowned self] notification in
            self.testObject.count += 1
        }
        
        for _ in Range(start: 0, end: 1000) {
            NotificationCenter.postNotificationName(notificationName, object: nil)
        }
        
        let expection = expectationWithDescription("")
        XCTAssert(self.testObject.count == 1000)
        expection.fulfill()
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testObserveWithSelector() {
        let notificationName =  __FUNCTION__
        testObject.notificationHandler.observe(notificationName, selector: "plusOne")
        
        NotificationCenter.postNotificationName(notificationName, object: nil)
        
        let expection = expectationWithDescription("")
        XCTAssert(self.testObject.count == 1)
        expection.fulfill()
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testObserveWithSelectorAndParameters() {
        let notificationName =  __FUNCTION__
        testObject.notificationHandler.observe(notificationName, selector: "plusTwo:")
        
        NotificationCenter.postNotificationName(notificationName, object: nil)
        
        let expection = expectationWithDescription("")
        XCTAssert(self.testObject.count == 2)
        expection.fulfill()
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testObserveWithSelectorManyTimes() {
        let notificationName =  __FUNCTION__
        testObject.notificationHandler.observe(notificationName, selector: "plusOne")
        
        for _ in Range(start: 0, end: 1000) {
            NotificationCenter.postNotificationName(notificationName, object: nil)
        }
        
        let expection = expectationWithDescription("")
        XCTAssert(self.testObject.count == 1000)
        expection.fulfill()
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testObserveWithSelectorAndBlock() {
        let notificationName =  __FUNCTION__
        testObject.notificationHandler.observe(notificationName, selector: "plusOne")
        testObject.notificationHandler.observe(notificationName) {[unowned self] notification in
            self.testObject.count += 1
        }
        NotificationCenter.postNotificationName(notificationName, object: nil)
        
        let expection = expectationWithDescription("")
        XCTAssert(self.testObject.count == 2)
        expection.fulfill()
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testUnobserveWithSelector() {
        let notificationName =  __FUNCTION__
        testObject.notificationHandler.observe(notificationName, selector: "plusOne")
        NotificationCenter.postNotificationName(notificationName, object: nil)
        
        let expection = expectationWithDescription("")
        XCTAssert(self.testObject.count == 1)
        expection.fulfill()
        
        testObject.notificationHandler.unobserve(notificationName)
        NotificationCenter.postNotificationName(notificationName, object: nil)
        
        let expection2 = expectationWithDescription("")
        XCTAssert(self.testObject.count == 1)
        expection2.fulfill()
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testObserverBecomeNilWithSelector() {
        let notificationName =  __FUNCTION__
        testObject.notificationHandler.observe(notificationName, selector: "plusOne")
        NotificationCenter.postNotificationName(notificationName, object: nil)
        
        let expection = expectationWithDescription("")
        XCTAssert(self.testObject.count == 1)
        expection.fulfill()
        
        testObject = nil
        
        NotificationCenter.postNotificationName(notificationName, object: nil)
        
        let expection2 = expectationWithDescription("")
        expection2.fulfill()
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    //    func testObserverBecomeNilWithBlock() {
    //        let notificationName =  __FUNCTION__
    //        testObject.NotificationHandler.observe(notificationName) {[unowned self] (notification) -> Void in
    //            self.testObject.count += 1
    //        }
    //        NotificationCenter.postNotificationName(notificationName, object: nil)
    //
    //        let expection = expectationWithDescription("")
    //        XCTAssert(self.testObject.count == 1)
    //        expection.fulfill()
    //
    //        testObject = nil
    //
    //        NotificationCenter.postNotificationName(notificationName, object: nil)
    //
    //        let expection2 = expectationWithDescription("")
    //        XCTAssert(self.testObject.count == 1)
    //        expection2.fulfill()
    //        waitForExpectationsWithTimeout(2, handler: nil)
    //    }
}