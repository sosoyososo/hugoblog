---
title: '再说 Runloop'
date: Mon, 09 Oct 2017 09:48:12 +0000
draft: false
tags: ['iOS', 'Objective-C']
---

[之前](http://www.karsa.info/blog/?p=335)有说过对runloop的理解，再次回顾的时候，感觉并没有达到最初想要写这篇文字的目的:通过循环的是什么，休眠的是什么来弄清楚到底为什么会比较高效？现在总结于此:

1.  Runloop和Thread的关系 Runloop是运行于某个线程的一个循环，运行循环使用的是Thread的资源。
    
2.  Runloop 相关的结构 Runloop 主要包括 Runloop Source和 Runloop Object。 Runloop Source 是产生事件消息的消息源，在某个时间点，将一个发送事件给 Runloop Object。 Runloop Object 是 Runloop 本身，接受、管理Source发来的事件，运行循环，向观察者发送循环通知。
    
3.  Runloop 循环的是什么 Runloop最终循环的是Runloop Source 发送来的事件，接受到事件后，调用事件的处理函数。在循环的每个阶段发送 的循环通知。
    
4.  Runloop 的休眠和唤醒 Runloop 的休眠其实就是运行Runloop的Thread的休眠，Runloop的唤醒条件达到的时候，所唤醒的也是Thread本身。所以，Source的运行导致事件的产生，事件的产生会导致Runloop唤醒所在Thread来处理事件。