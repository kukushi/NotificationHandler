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
            objc_setAssociatedObject(self, &NotificationHandlerAssociationKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

/// The notification handler response for handing all the hard works of observing and unoberving notifications.
/// The basic usage is rather similar than the official `NSNotificationCenter`.
public class NotificationHandler: NSObject {
    public typealias NotificationClosure = (Notification) -> Void
    
    private weak var observer: NSObject!
    private var blockInfos = Set<Notification.Info>()
    private var selectorInfos = Set<Notification.Info>()
    private var lock = pthread_mutex_t()
    
    private var DefaultCenter: NotificationCenter {
        return NotificationCenter.default
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
    public func observe(_ name: Notification.Name?, object: NSObject? = nil, queue: OperationQueue? = nil, block: @escaping NotificationClosure) {
        let observer = DefaultCenter.addObserver(forName: name, object: object, queue: queue, using: block)
        let info = Notification.Info(observer: observer as! NSObject, name: name, object: object)

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
    public func observe(_ notification: Notification.Name?, object: NSObject? = nil, selector: Selector) {
        DefaultCenter.addObserver(self, selector: #selector(NotificationHandler.notificationReceived(_:)), name: notification, object: object)
        let notificationInfo = Notification.Info(observer: self.observer, name: notification, selector: selector)
        selectorInfos.insert(notificationInfo)
    }
    
    /**
     The method used to redistribute notification to the real observer. This method is marked `public` instead of `private` because the language limitation.
     
     - parameter notification: Received notification.
     */
    @objc public func notificationReceived(_ notification: Notification) {
        let name = notification.name
        for info in selectorInfos where info.selector != nil {
            let nameMatch = name == info.name
            let responsible = info.observer.responds(to: info.selector!)
            if nameMatch && responsible {
                info.observer.perform(info.selector!, with: notification)
            }
        }
    }
    
    private func removeNilObserver(_ info: Notification.Info) -> Bool {
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
    public func unobserve(_ name: Notification.Name?, object: NSObject? = nil) {
        
        lockWith {
            let filterBlock = { [unowned self] (info: Notification.Info) -> Bool in
                if info.name == name && info.object == object {
                    self.DefaultCenter.removeObserver(info.observer, name: info.name, object: info.object)
                    return false
                }
                return true
            }
            
            let filteredBlockInfos = self.blockInfos.filter(filterBlock)
            blockInfos = Set<Notification.Info>(filteredBlockInfos)
            
            let filteredSelectorInfos = self.selectorInfos.filter(filterBlock)
            selectorInfos = Set<Notification.Info>(filteredSelectorInfos)
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
            blockInfos.removeAll(keepingCapacity: false)
        }
    }
    
    // MARK: Lock
    
    private func lockWith(_ closure: () -> ()) {
        pthread_mutex_lock(&lock);
        closure();
        pthread_mutex_unlock(&lock);
    }
    
    private func notificationName(from string: String?) -> Notification.Name? {
        if let str = string {
            return Notification.Name(str)
        }
        return nil
    }
}

extension Notification {
    /**
     *  Private data model used to store notification observation info
     */
    fileprivate struct Info: Hashable {
        weak var observer: NSObject!
        let name: Notification.Name!
        let object: NSObject?
        let selector: Selector?
        
        init (observer: NSObject, name: Notification.Name?, object: NSObject? = nil, selector: Selector? = nil) {
            self.observer = observer
            self.name = name
            self.object = object
            self.selector = selector
        }
        
        var hashValue: Int {
            return name.rawValue.hash
        }
    }
}

fileprivate func ==(lhs: Notification.Info, rhs: Notification.Info) -> Bool {
    return lhs.name == rhs.name && lhs.observer == rhs.observer
}

