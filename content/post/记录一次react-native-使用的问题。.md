---
title: '记录一次React Native 使用的问题。'
date: Thu, 26 Apr 2018 17:25:02 +0000
draft: false
tags: ['iOS', 'Objective-C', 'React Native']
---

问题
--

最近在使用RN的过程中，发现了两个问题：

1.  模拟器CMD+R唤起Dev Menu的时候，一次性会出现两个menu，内容有时一样，有时不同。
2.  开启调试模式后，前几次开发还可以，后面就基本不可用了，一直提示: `Runtime is not ready for debugging. Make sure Packager server is running.` 按照网上能找到的办法试了也没有改观。今天功能开发告一段落，正好研究一下这个问题。

背景
--

在此之前，先大致介绍一下出问题的工程对RN的使用：

1.  swift作为主工程
2.  手动管理对RN的依赖
3.  RN部分应用于App的一部分新业务中

分析1
---

1.  我们从最简单的第一个问题开始，原理很简单，就是响应摇晃事件，发出通知，创建一个ActionSheet，加入一些必要的选项，进行显示。在追踪的时候发现，两个ActionSheet在只显示过一个RN页面的时候不会出现。在跟踪调试AtionSheet出现的过程中发现是因为同时存在两个RCTDevMenu实例，他们都相应了摇晃手势导致的。
2.  我追了一下他的创建，发现在重新加载页面，修改是否远程调试的时候都会创建，而调用init的函数调用栈表明它是在RCTCxxBridge的\_initModules中被调用的。而这两个操作确实会引起bridge的重新创建，加载，并不稀奇。难道是因为多次加载导致的内存问题？虽然感觉facebook不应该犯这样的错误，但还是试了一下全局只使用一个RCTDevMenu来响应摇晃手势，结果问题更诡异了，在这里就不展开了。整个事情到这里貌似陷入了僵局。

分析2
---

1.  第二个问题出现的很频繁，全局搜了一下显示的内容:`Runtime is not ready for debugging`，稍加调试，很容易定为到RCTWebSocketExcutor的sendMessage:onReply:，然后就发现是因为 \_socket.readyState 的状态变成了RCTSR\_CLOSING，试了几次都这样。
2.  看了RCTWebSocketExcutor的创建，跟RCTDevMenu一样也是做为React的module，在bridge初始化的时候注册，使用的时候通过RCTModuleData创建了实例。

睡前想到了原因
-------

在睡前突然想到，因为实在旧有的App上使用RN，所以每个RN页面其实都是一个单独的RCTRootView做为承载，而每个RCTRootView都有自己的bridge。如果有多个bridge同时存在，第一个问题就不难理解了。

赶紧试一试
-----

App中的RN页面都有共同的父类，于是我可以快速的让所有的RN页面公用一个bridge，在第一个页面初始化的时候创建。经过简单测试，果然测试用的ActionSheet不在重复出现，而且更开心的是，第二个问题也是这样引起的。

后续的总结
-----

#### Reatc如何加载module

> 1.  通过 RCT\_EXPORT\_MODULE() 将自己的class注册到全局列表RCTModuleClasses中
> 2.  RCTCxxBridge做为RCTBridge的batchedBridge初始化的时候，使用registerModulesForClasses方法，创建一个对应的RCTModuleData列表
> 3.  之后马上遍历RCTModuleData列表，通过调用instance方法，创建对应class的实例

#### Debug的基本沟通方法

1.  node创建一个1081端口的服务
2.  客户端通过这个端口从node获取打包好的代码
3.  调试的时候，客户端新建一个链接到node服务的webSocket端口，通过这个端口将调试信息传递到node server
4.  node 使用chrome打开代开链接到node的页面，加载调试信息，进行调试。

整个通道如下所示： App <-> Node <-> Debug\_In\_Chrome