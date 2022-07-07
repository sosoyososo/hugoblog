---
title: '再说OC的weak引用'
date: Wed, 19 Dec 2018 10:36:11 +0000
draft: false
tags: ['Objective-C']
---

一说再说是因为每次的理解都更加深入，也因为这块确实很有代表性。这次我们通过几个问题，分析具体场景来进行了解。

### 存储初始化

1.  OC runtime 初始化的时候，在\_objc\_init函数中，使用\_dyld\_objc\_notify\_register方法，在dyld中添加了观察者，每当新的framework加载的时候回调map\_images。
2.  map\_images方法间接调用一次arr\_init，arr\_init在全生命周期只会被调用一次。
3.  arr\_init 调用 SideTableInit 方法，初始化一个 StripedMap 对象。

### 存储

1.  全局唯一的StripedMap对象保存了所有weak引用相关所需要的数据；
2.  StripedMap 是一个桶结构，保存一个SideTable数组，每个key会简单的取余数数组长度，得到一个具体的index，对应到一个具体的SideTable；
3.  SideTable 本身是一个 struct，主要包括一个 RefcountMap 、 一个 weak\_table\_t 以及一个 spinlock\_t；
4.  spinlock\_t 就是多线程同步锁，RefcountMap 保存对象的引用计数，weak\_table\_t管理这个对象所有的弱引用；
5.  weak\_table\_t 主要保存了一个 weak\_entry\_t 列表以及其他一些辅助信息；
6.  weak\_entry\_t 保存某个对象所有的弱引用。优先保存到 inline\_referrers 指向的数组；如果存满，存到referrers指向的数组，这个数组在快满的时候，自动增长；

### 查找算法

1.  StripedMap 中查找对应的 SideTable，使用的是直接模除；
2.  weak\_table\_t 找到对应的 weak\_entry\_t，使用一个OC中普遍使用的快速hash算法(后面解释)；
3.  weak\_entry\_t 找到对应的引用是直接遍历两个数组；

### 快速hash算法

[原文](http://locklessinc.com/articles/fast_hash/) 通过对[原始算法](http://locklessinc.com/articles/prng/)的进行汇编级别的优化达到极致的快。 Apple参照这个算法分三步做了hash：

1.  数字二进制右移4位，结果跟原始值亦或作为后续处理；
2.  第一步的结果乘以一个很大的基数；
3.  第二步的结果进行反转之后，与第二步的结果进行亦或；（反转是指反转字节顺序）