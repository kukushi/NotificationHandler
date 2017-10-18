# NotificationHandler

![Carthage Compatibility](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)
[![Build Status](https://travis-ci.org/kukushi/NotificationHandler.svg?branch=0.0.2)](https://travis-ci.org/kukushi/NotificationHandler)

NotificationHandler nicely wrap almost all the `NSNotification` related operations with more friendly API.

Features include:

* Modern and clear method signature.
* Implicit observer removal on observer deallocation.

## Usage

```swift
// With closure
notificationHandler.observe(notificationName) { notification in
    // do something...
}

// With selector
notificationHandler.observe(notificationName, selector: #selector(Object.sayHi)
```

This is the complete example.

##  NSObject Category

A `NSObject` category is provided to give you direct access of handler, shown as above.

## Installation

### CocoaPods

In your Podfile (note that it require Cocoapods 0.36 or later):

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

pod 'NotificationHandler'
```

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager for Cocoa application.

To integrate NotificationHandler into your Xcode project using CocoaPods, specify it in your `Cartfile`:

```ogdl
github "kukushi/NotificationHandler"
```

## Requirements

NotificationHandler using ARC and weak collections base on Swift 2.2. It requires:

* iOS 8 or later.
* Xcode 7.3 or later.


## One more thing

🎉A little changes over NSNotificationCenter as mentioned by [Apple](https://developer.apple.com/library/prerelease/mac/releasenotes/Foundation/RN-Foundation/index.html#10_11NotificationCenter):

> NSNotificationCenter
>
> In OS X 10.11 and iOS 9.0 NSNotificationCenter and NSDistributedNotificationCenter will no longer send notifications to registered observers that may be deallocated. If the observer is able to be stored as a zeroing-weak reference the underlying storage will store the observer as a zeroing weak reference, alternatively if the object cannot be stored weakly (i.e. it has a custom retain/release mechanism that would prevent the runtime from being able to store the object weakly) it will store the object as a non-weak zeroing reference. This means that observers are not required to un-register in their deallocation method. The next notification that would be routed to that observer will detect the zeroed reference and automatically un-register the observer. If an object can be weakly referenced notifications will no longer be sent to the observer during deallocation; the previous behavior of receiving notifications during dealloc is still present in the case of non-weakly zeroing reference observers. Block based observers via the -[NSNotificationCenter addObserverForName:object:queue:usingBlock] method still need to be un-registered when no longer in use since the system still holds a strong reference to these observers. Removing observers (either weakly referenced or zeroing referenced) prematurely is still supported. CFNotificationCenterAddObserver does not conform to this behavior since the observer may not be an object.
>
> NSNotificationCenter and NSDistributedNotificationCenter will now provide a debug description when printing from the debugger that will list all registered observers including references that have been zeroed out for aiding in debugging notification registrations. This data is only valid per the duration of the breakpoint since the underlying store must account for multithreaded environments. Wildcard registrations for notifications where the name or object that was passed to the addObserver method family was null will be printed in the debug description as *.

tl;dr: On OS X 10.11 and iOS 9.0 or later, you don't have to un-register the notification if the observer can be stored weakly and the notification is registered using selector.