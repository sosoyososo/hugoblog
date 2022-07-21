---
title: '测试 automaticallyAdjustsScrollViewInsets 对UI的影响'
date: Tue, 01 Nov 2016 06:24:15 +0000
draft: false
tags: ['iOS']
---

> 这个参数主要是对controller的view的subview中的UIScrollView元素起作用，我们使用最简单的结构来对这个参数进行测试。从文档可以知道与之相互作用的元素有：status bar, search bar, navigation bar, toolbar, or tab bar。其中status bar总是存在，toolbar是跟 UINavigationController 绑定在一起。这里简单讨论一下除了search bar之外的因素对它的影响。

单个因素影响
------

1.  从外到内依次是 UINavigationController UIViewController UIScrollView 的时候，contentInset = (top: 64, left: 0, bottom: 0, right: 0)
2.  从外到内依次是 UITabbarController UIViewController UIScrollView 的时候，contentInset = (top: 0, left: 0, bottom: 0, right: 0)

双因素影响
-----

1.  从外到内依次是 UINavigationController UITabbarController UIViewController UIScrollView 的时候，contentInset = (top: 0, left: 0, bottom: 0, right: 0)
2.  从外到内依次是 UITabbarController UINavigationController UIViewController UIScrollView 的时候，contentInset = (top: 64, left: 0, bottom: 49, right: 0)
3.  从外到内依次是 UINavigationController UIViewController UIScrollView ，并且显示toolBar的时候，contentInset = (top: 64, left: 0, bottom: 44.0, right: 0)

三因素影响
-----

1.  从外到内依次是 UITabbarController UINavigationController UIViewController UIScrollView , 加上 UIToolBar 的时候， contentInset = (top: 64.0, left: 0, bottom: 93.0, right: 0)，也就是 toolBar 打破了这个参数的作用

概述
--

从上面的测试来看，这个为了方便而加入的属性，因为涉及到的具体逻辑太多其实并不怎么方便，即使是组合相同，也需要特定的方式才能起作用，而且即使起作用了，也会因为额外的一些不当操作让其失效。

后续
--

另外一个类似感觉自作聪明的是navigationBar是否透明的设置。iOS7之后默认是半透明的，然后navigationController中viewController的内容从屏幕顶部开始；当设置为不透明的时候，内容从64像素也就是navigationBar下面开始。当然还有就是tintColor,它在不同的空间上有着完全不同的作用。iOS SDK中遍布这种你需要猜测或者一个个去测试的设定。 我总觉得这些复杂的设置，又没有在属性的描述文档中说清楚，就是一个个的坑等着人去跳。即使现在我们测试出了这些性质，但这并不是官方的，而是你自己猜测的，总归不是正途 ～