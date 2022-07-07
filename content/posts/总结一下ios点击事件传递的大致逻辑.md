---
title: '总结一下iOS点击事件传递的大致逻辑'
date: Thu, 22 Sep 2016 07:18:08 +0000
draft: false
tags: ['iOS']
---

iOS中，点击事件从用户手机操作屏幕，设备收到信号后，传递给 UIKit， 由 UIKit 将屏幕的操作信号转化成 UIEvent ，放入一个事件队列，当前激活的应用程序(UIApplication)去从队列中取出事件并进行处理。 所以对于iOS开发者来说 UIApplication 是第一份接收到点击事件的，之后 UIApplication 通过 sendEvent 将事件对象分发出去，下一个接棒的是 UIWindow ，它使用同名方法进行事件分发。所以这两点可以分别进行整个 App 范围和一个 window 范围内的事件监控。 从window 开始，事件的处理就有差别了，但是大致的思路不变，就是找到最有可能响应事件的对象进行响应。如果找到的对象没有响应，事件沿着 responder chain 传递，直到被处理或者被抛弃。其中的差别在于寻找最优响应者，分为两种情况，如果有 first responder 最优响应者就是它了，如果没有，说明是普通的触屏事件，使用hit－test系统找到最终发生点击事件的view，用它作为第一响应着。 responder chain 在你使用 UIKit 的控件搭建 UI 的时候，由 UIKit 自动创建，同时注意 UITouch UIEvent 这些 iOS 中事件处理都是 UI 开头，就是说这些处理默认是限定在 UIKit 的framework 中的。更具体一点，从 UIResponder 开始的子类才有能力处理事件，而点击事件的发生是从 UIView 开始的子类才能发生，UIView 和 UIResponder 中间的东西可以作为响应链的中间处理环节，比如 UIViewController。 UIGestureRecognizer 是 NSObjct 的子类，所以本身并不是响应链的一环，只能附加到 UIView 上才能处理事件。 响应链的主要顺序是沿着 subview 到 superView 的继承顺序，最终到 window 再到 application ，如果是 controller 的 view 属性指向的 view， 它和 superView 中间会插入 controller。 事件的处理分为几个级别: 1. UIKit 定义的控件，比如 UIButton UIScrollView UITableView，你用这些控件，就已经默认使用了它的事件处理 2. 将 UIGestureRecognizer 的子类添加到 UIView 的对象上 3. 使用 touch begin move end cancel 的原始事件处理 这三个级别的处理方式也是 iOS 默认建议的使用优先级顺序，当高优先级的不能满足的时候使用下一个。