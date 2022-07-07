---
title: '初看 ReSwift'
date: Wed, 18 Jul 2018 09:57:07 +0000
draft: false
tags: ['iOS', 'swift']
---

概述
--

是Redux思想在的swift版本实现，类似的还有facebook对React版本实现flux。Redux是一种软件架构思想，跟MVC、MVP、MVVM性质一致，是为简化App状态而提出的编程原则。没有或者不遵守这些原则，App也能运行，也能完整，但开发和维护难度可能会比较大。

基本思想
----

对比MVC使用Model处理数据，View展示数据，Controller沟通两者，Redux则使用了另外一种解释： 1. 将整体业务分为Store，State，Action，Dispatch，Reducer，View几个模块 2. View接受用户操作，产生Action，传给store，由Dispatch传递给对应的Reducer来更新state，然后store通知view状态变化，view获取state，更新自身 3. 关键点，单独的store，单独的dispatcher，多个reducer(最终合成一个总的)，多个state（最终合成一个总的）

带来的好处
-----

1.  单向数据流，容易理解
2.  全局的store，避免很多内存错误(相对于MVC的导出相互引用)
3.  统一分发，统一处理，容易监控，便于相互查找，容易做缓存，容易做导航(等等等等～，其实放在一起处理本来就是超级大的优势，它所有的优势都是统一带来的)

坏处
--

1.  本身的架构导致需要将所有的内容都进行抽象，这需要花费更多的时间在业务分析和设计上。
2.  统一处理全局状态也带来更多更复杂问题，本来每个模块自由处理自身，现在需要更多关注全局。