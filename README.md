# NotificationHandler

![Carthage Compatibility](https://img.shields.io/badge/Carthage-✔-f2a77e.svg?style=flat)
![License](https://img.shields.io/cocoapods/l/Lily.svg?style=flat)
![Platform](https://img.shields.io/cocoapods/p/Lily.svg?style=flat)

NotificationHandler is a neat Swift notification operations wrapper. With NotificationHandler, it's super easy to handle notifications with neat API. What's more, remove obersers is also properly handled.

Fetures include:

* Modern and clear method signature
* Implicit observer removal on controller dealloc.


## Usage

```
// with closure
self.notificationHandler.observe(notificationName) { (notification) -> Void in
    // do something...
}

// or with selector

self.notificaqtionHandler.observe(notificationName, selector: "SayHi")

```

This is the complete example. The removal of observer will be done when controller is deallocated.

##  NSObject Category

A NSObject Category is provided to give you direct access of controller show as above.

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

NotificationHandler using ARC and weak Collections base on Swift 1.2. It requires:

* iOS 8 or later.
* Xcode 7 or later.