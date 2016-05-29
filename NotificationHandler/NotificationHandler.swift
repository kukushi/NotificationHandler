//
//  NotificationHandler.swift
//  NotificationHandler
//
//  Created by kukushi on 3/1/15.
//  Copyright (c) 2015 kukushi. All rights reserved.
//

import Foundation

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

/// The notification handler response for handing all the hard works of observing and unoberving notifications.
/// The basic usage is rather similar than the official `NSNotificationCenter`.
public class NotificationHandler: NSObject {
    public typealias NotificationClosure = (NSNotification!) -> Void
    
    private weak var observer: NSObject!
    private var blockInfos = Set<NotificationInfo>()
    private var selectorInfos = Set<NotificationInfo>()
    private var lock = pthread_mutex_t()
    
    private var DefaultCenter: NSNotificationCenter {
        return NSNotificationCenter.defaultCenter()
    }
    
    // MARK: Initialization
    
    /**
    Create a notification handler using the observer. Observer is responded for hold that instance. Normally, you don't need to call this method manually.
    
    - parameter observer: The observer will be weak referenced by that instance.
    
    - returns: An initialized instance
    */
    init (observer: NSObject) {
        pthread_mutex_init(&lock, nil)
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

        lockWith {
            blockInfos.insert(info)
        }
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
     The method used to redistribute notification to the real observer. This method is marked `public` instead of `private` because the language limitation.
     
     - parameter notification: Received notification.
     */
    public func notificationReceived(notification: NSNotification) {
        let name = notification.name
        for info in selectorInfos where info.selector != nil {
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
        
        lockWith {
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
        }
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

        lockWith {
            blockInfos.removeAll(keepCapacity: false)
        }
    }
    
    // MARK: Lock
    
    func lockWith(@noescape closure: Void -> Void) {
        pthread_mutex_lock(&lock);
        closure();
        pthread_mutex_unlock(&lock);
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
