---
title: 'OC多线程技术选型你需要知道的'
date: Sat, 16 May 2015 05:35:24 +0000
draft: false
tags: ['Objective-C', 'Read Note']
---

OC本身是通用型的编程语言，是C的超集，主要应用于Apple的平台中，这意味着多线程技术选型的多样性，关于这些在Apple的文档中也有说明，在此作简单总结。(我们所有的讨论限制在Apple的平台里面) POSIX API 在Apple平台上，多线程的底层实现机制是Mach的线程，但你很少使用到它，相反你更多实用的是POSIX的API或者它的衍生工具，所以POSIX API可以被理解是我们多线程的最基础。这个接口是C级别的，提供真实的多线程操作。 NSThread NSThread可以被理解成POSIX API面向对象的封装，让POSIX API更容易使用了，但基本原理仍然没有改变，NSThread代表了一个真实的线程。 GCD GCD实际上是另外的一个独立的复杂的lib库，针对整个系统，接收每个应用程序提交的任务。封装了多项功能:1.系统监控:2.线程管理:3.任务调度:。通过这些功能，尽量最合理的利用系统资源，分配任务。 NSOperation NSOperation可以理解为对GCD的封装，不过因为早期的NSOperation使用的不是GCD技术，所以难免还遗留了一点过去的痕迹。 Runloop Runloop则是一个事件处理的循环，附着在一个线程上，对加入的任务进行调度。 一般对应用处理的实时性要求比较高的时候会用NSThread，比如视频处理，这对程序的精确性要求比较高，代码难度也高。 在一般的短暂性使用的时候会使用GCD,比如想在1秒钟后处理某任务，配合block，使用dispatch\_after函数就非常方便。 NSOperation则是更偏向于设计一个更大更眼睛的模块化功能，比如著名的AFNetworking。 Runloop使用的频率不是很高，但在处理用户输入的时候特别有效，所以在Cocoa中被UIApplication广泛使用。