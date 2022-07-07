---
title: 'Swift 的时代？'
date: Fri, 30 Dec 2016 02:44:49 +0000
draft: false
tags: ['瞎逼逼']
---

最近关于Swift的讨论越来越多，第三方的工具不断完善，甚至在linux上已经出现了swift开发服务端的工具，好像swift一统天下的时刻马上就到了。但是，但是，偶尔的恍惚中，好像还能看到Obejctive-C所散发的强光，从不知多深的地方透射出来，让我们坚持最新最好的灵魂颤抖一下。那么，Objectice-C的时代真的结束了么 ？ 在这方面，我感觉在国内和国外完全呈现两种不同的态势。swift阵营所涌现出的大部分优秀的开源工具(比如Carthage，Alamofire等)都来自国外，这方面老外们甚为激进(比如AlamoFire现在最新的更新基本上都是对Swift3了，一些常规的工具比如大部分也是如此)，而反观国内，最近吵得最厉害的反而是Objectice-C相关，不论是各种Path还是心出来的腾讯OCS，都是基于对OC的动态化更深入的利用。 在iOS，从大势上讲，Swift确实代表着未来，但Objective-C却是iOS近十年，macOS近20年的历史沉淀，并不是说去掉就能去掉的。就目前来看，苹果在你选择Swift的时候，也只是对你隐藏了底层SDK是OC的这个事实，让你以为你是在用Swift版本的Cocoa SDK。这个从很多个方面可以验证，一个是Swift中为了兼容OC所引入的 @objc ，让你的使用swift类在底层转换成OC，另一个是在swift中有介绍明确说明了你使用Swift声明，并继承Cocoa 的类才能使用KVO，而Swift是没有这项技术的，还有则是你在调试的时候，偶尔出现的crash提示中也会提示crash的代码所在文件是 \*.mm的。