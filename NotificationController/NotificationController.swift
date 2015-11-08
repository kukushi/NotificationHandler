//
//  NotificationController.swift
//  NotificationController
//
//  Created by kukushi on 3/1/15.
//  Copyright (c) 2015 kukushi. All rights reserved.
//

import UIKit

private var notificationControllerAssociationKey: UInt8 = 17

public extension NSObject {
    /// A lazy initalized NotificationController isntance for NSObject and it's subclass
    var notificationController: NotificationController! {
        get {
            var controller = objc_getAssociatedObject(self, &notificationControllerAssociationKey) as? NotificationController
            if controller == nil {
                controller = NotificationController(observer: self)
                self.notificationController = controller
            }
            return controller
        }
        set(newValue) {
            objc_setAssociatedObject(self, &notificationControllerAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
}

public class NotificationController: NSObject {
    public typealias NotificationClosure = (NSNotification!) -> Void
    
    private weak var observer: NSObject!
    private var blockInfos = Set<NotificationInfo>()
    private var selectorInfos = Set<NotificationInfo>()
    private var lock = OS_SPINLOCK_INIT
    
    private var DefaultCenter: NSNotificationCenter {
        return NSNotificationCenter.defaultCenter()
    }
    
    // MARK: Initalization
    
    init (observer: NSObject) {
        self.observer = observer
    }
    
    deinit {
        unobserveAll()
    }
    
    // MARK: Observe with Closure
    public func observe(notification: String?, object: NSObject? = nil, queue: NSOperationQueue? = nil, block: NotificationClosure) {
        let observer = DefaultCenter.addObserverForName(notification, object: object, queue: queue, usingBlock: block)
        let info = NotificationInfo(observer: observer as! NSObject, name: notification, object: object)
        
        spinLock {
            self.blockInfos.insert(info)
        }
    }
    
    // MARK: Observe with Selector
    
    public func observe(notification: String?, object: NSObject? = nil, selector: Selector) {
        DefaultCenter.addObserver(self, selector: "notificationReceived:", name: notification, object: object)
        let notificationInfo = NotificationInfo(observer: self.observer, name: notification, selector: selector)
        selectorInfos.insert(notificationInfo)
    }
    
    public func notificationReceived(notification: NSNotification) {
        let name = notification.name
        for info in selectorInfos  where info.selector != nil {
            if name == info.name && info.observer.respondsToSelector(info.selector!) {
                info.observer.performSelector(info.selector!, withObject: info.object)
            }
        }
    }
    
    // MARK: Unobserve
    
    public func unobserve(notification: String?, object: NSObject? = nil) {
        spinLock {
            let filterBlock = { [unowned self] (info: NotificationInfo) -> Bool in
                if info.name == notification && info.object == object {
                    self.DefaultCenter.removeObserver(info.observer, name: info.name, object: info.object)
                    return false
                }
                return true
            }
            
            let filteredBlockInfos = self.blockInfos.filter(filterBlock)
            self.blockInfos = Set<NotificationInfo>(filteredBlockInfos)
            
            let filteredSelectorInfos = self.selectorInfos.filter(filterBlock)
            self.selectorInfos = Set<NotificationInfo>(filteredSelectorInfos)
        }
        
    }
    
    public func unobserveAll() {
        
        for info in blockInfos {
            DefaultCenter.removeObserver(info.observer, name: info.name, object: info.object)
        }
        
        spinLock {
            self.blockInfos.removeAll(keepCapacity: false)
        }
    }
    
    // MARK: Lock
    
    private func spinLock(closure: Void -> Void) {
        OSSpinLockLock(&lock)
        closure()
        OSSpinLockUnlock(&lock)
    }
}

private struct NotificationInfo: Hashable {
    weak var observer: NSObject!
    let name: String!
    let object: NSObject?
    let selector: Selector?
    
    init (observer: NSObject, name: String?, object: NSObject? = nil, selector: Selector? = nil) {
        self.observer = observer
        self.name = name
        self.object = object
        self.selector = selector
    }
    
    var hashValue: Int {
        return name.hash
    }
}

private func ==(lhs: NotificationInfo, rhs: NotificationInfo) -> Bool {
    return lhs.name == rhs.name && lhs.observer == rhs.observer
}
