//
//  NotificationControllerTests.swift
//  NotificationControllerTests
//
//  Created by Xing He on 11/4/15.
//  Copyright © 2015 Xing He. All rights reserved.
//

import XCTest
@testable import NotificationController

let NotificationCenter = NSNotificationCenter.defaultCenter()

class TestObject: NSObject {
    var count = 0
    override init () {}
    func plusOne() {
        count += 1
    }
}

class NotificationControllerTests: XCTestCase {
    var testObject: TestObject!
    
    override func setUp() {
        testObject = TestObject()
        super.setUp()
    }
    
    func testObserveWithBlock() {
        let notificationName =  __FUNCTION__
        testObject.notificationController.observe(notificationName) {[unowned self] notification in
            self.testObject.count += 1
        }
        
        NotificationCenter.postNotificationName(notificationName, object: nil)
        
        let expection = expectationWithDescription("")
        XCTAssert(self.testObject.count == 1)
        expection.fulfill()
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testObserveWithSelector() {
        let notificationName =  __FUNCTION__
        testObject.notificationController.observe(notificationName, selector: "plusOne")
        
        NotificationCenter.postNotificationName(notificationName, object: nil)
        
        let expection = expectationWithDescription("")
        XCTAssert(self.testObject.count == 1)
        expection.fulfill()
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testObserveWithSelectorAndBlock() {
        let notificationName =  __FUNCTION__
        testObject.notificationController.observe(notificationName, selector: "plusOne")
        testObject.notificationController.observe(notificationName) {[unowned self] notification in
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
        testObject.notificationController.observe(notificationName, selector: "plusOne")
        NotificationCenter.postNotificationName(notificationName, object: nil)
        
        let expection = expectationWithDescription("")
        XCTAssert(self.testObject.count == 1)
        expection.fulfill()
        
        testObject.notificationController.unobserve(notificationName)
        NotificationCenter.postNotificationName(notificationName, object: nil)
        
        let expection2 = expectationWithDescription("")
        XCTAssert(self.testObject.count == 1)
        expection2.fulfill()
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testObserverBecomeNilWithSelector() {
        let notificationName =  __FUNCTION__
        testObject.notificationController.observe(notificationName, selector: "plusOne")
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
}
