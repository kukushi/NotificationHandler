//
//  NotificationHandler.swift
//  NotificationHandler
//
//  Created by kukushi on 3/1/15.
//  Copyright (c) 2015 kukushi. All rights reserved.
//

import UIKit

private var NotificationHandlerAssociationKey: UInt8 = 17

public extension NSObject {
    /// A lazy initialized `NotificationHandler` instance for NSObject and it's subclass
    var notificationHandler: NotificationHandler! {
        get {
            var controller = objc_getAssociatedObject(self, &NotificationHandlerAssociationKey) as? NotificationHandler
            if controller == nil {
                controller = NotificationHandler(observer: self)
                self.notificationHandler = controller
            }
            return controller
        }
        set(newValue) {
            objc_setAssociatedObject(self, &NotificationHandlerAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

/// The notification handler response for handing all the hard work of observe and unoberve notifications.
/// The basic usage is rather similar to the official `NSNotification Center`
public class NotificationHandler: NSObject {
    public typealias NotificationClosure = (NSNotification!) -> Void
    
    private weak var observer: NSObject!
    private var blockInfos = Set<NotificationInfo>()
    private var selectorInfos = Set<NotificationInfo>()
    private var lock = OS_SPINLOCK_INIT
    
    private var DefaultCenter: NSNotificationCenter {
        return NSNotificationCenter.defaultCenter()
    }
    
    // MARK: Initialization
    
    /**
    Create a notification handler instance using the observer. Observer is responded for hold that instance. Normally, you don't have to call this method manually.
    
    - parameter observer: The observer of the notification which will be weak referenced by that instance.
    
    - returns: An initialized instance
    */
    init (observer: NSObject) {
        self.observer = observer
    }
    
    deinit {
        unobserveAll()
    }
    
    // MARK: Observe with Closure
    
    /**
    Observe the notification using block and other given arguments.
    
    - parameter name:   the notification name to be observed.
    - parameter object: The name of the notification for which to register the observer; that is, only notifications with this name are delivered to the observer.If you pass nil, the notification center doesn’t use a notification’s name to decide whether to deliver it to the observer.
    - parameter queue:  The operation queue to which block should be added.If you pass nil, the block is run synchronously on the posting thread.
    - parameter block:  The block to be executed when the notification is received. The block is copied by the notification center and (the copy) held until the observer registration is removed.
    */
    public func observe(name: String?, object: NSObject? = nil, queue: NSOperationQueue? = nil, block: NotificationClosure) {
        let observer = DefaultCenter.addObserverForName(name, object: object, queue: queue, usingBlock: block)
        let info = NotificationInfo(observer: observer as! NSObject, name: name, object: object)
        
        
        OSSpinLockLock(&lock)
        
        blockInfos.insert(info)
        
        OSSpinLockUnlock(&lock)
    }
    
    // MARK: Observe with Selector
    
    /**
    Observe the notification using selector and other given arguments.
    
    - parameter notification: The name of the notification for which to register the observer; that is, only notifications with this name are delivered to the observer. If you pass nil, the notification center doesn’t use a notification’s name to decide whether to deliver it to the observer.
    - parameter object:       The object whose notifications the observer wants to receive; that is, only notifications sent by this sender are delivered to the observer. If you pass nil, the notification center doesn’t use a notification’s sender to decide whether to deliver it to the observer.
    - parameter selector:     Selector that specifies the message the receiver sends notificationObserver to notify it of the notification posting. The method specified by notificationSelector must have one and only one argument (an instance of NSNotification).
    */
    public func observe(notification: String?, object: NSObject? = nil, selector: Selector) {
        DefaultCenter.addObserver(self, selector: #selector(NotificationHandler.notificationReceived(_:)), name: notification, object: object)
        let notificationInfo = NotificationInfo(observer: self.observer, name: notification, selector: selector)
        selectorInfos.insert(notificationInfo)
    }
    
    /**
     The method used to redistribute notification to the real observer. This method is marked `private` instead of `public` because the language limitation.
     
     - parameter notification: Received notification.
     */
    public func notificationReceived(notification: NSNotification) {
        let name = notification.name
        for info in selectorInfos where info.selector != nil {
            #if DEBUG
                // Note: When rnning test case, that instance won't be deallocated even if the holder object have been deallocated which work totally fine in a normal project.
                // So in the debug mode, the observation will be removed if the oberser becom nil which will only happen in test case
                if removeNilObserver(info) {
                    return
                }
            #endif
            
            if name == info.name && info.observer.respondsToSelector(info.selector!) {
                info.observer.performSelector(info.selector!, withObject: notification)
            }
        }
    }
    
    private func removeNilObserver(info: NotificationInfo) -> Bool {
        if (info.observer == nil) {
            DefaultCenter.removeObserver(self)
            return true
        }
        return false
    }
    
    // MARK: Unobserve
    
    /**
    Unobserve the named notification observed by this instance.
    
    - parameter name:   the name of notification to be unobserved. Specify a notification name to remove only entries that specify this notification name. When nil, the receiver does not use notification names as criteria for removal.
    - parameter object: Sender to remove from the dispatch table. Specify a notification sender to remove only entries that specify this sender. When nil, the receiver does not use notification senders as criteria for removal.
    */
    public func unobserve(name: String?, object: NSObject? = nil) {
        OSSpinLockLock(&lock)
        
        let filterBlock = { [unowned self] (info: NotificationInfo) -> Bool in
            if info.name == name && info.object == object {
                self.DefaultCenter.removeObserver(info.observer, name: info.name, object: info.object)
                return false
            }
            return true
        }
        
        let filteredBlockInfos = self.blockInfos.filter(filterBlock)
        blockInfos = Set<NotificationInfo>(filteredBlockInfos)
        
        let filteredSelectorInfos = self.selectorInfos.filter(filterBlock)
        selectorInfos = Set<NotificationInfo>(filteredSelectorInfos)
        
        OSSpinLockUnlock(&lock)
        
    }
    
    /**
     Unobserve all the notifications observed by this instance.
     */
    public func unobserveAll() {
        for info in blockInfos {
            DefaultCenter.removeObserver(info.observer, name: info.name, object: info.object)
        }
        
        for info in selectorInfos {
            DefaultCenter.removeObserver(self, name: info.name, object: info.object)
        }
        
        OSSpinLockLock(&lock)
        
        blockInfos.removeAll(keepCapacity: false)
        
        OSSpinLockUnlock(&lock)
    }
}

/**
 *  Private data model used to store notification observation info
 */
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
