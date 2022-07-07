---
title: '关于KVC你需要知道的'
date: Tue, 28 Apr 2015 03:42:14 +0000
draft: false
tags: ['Read Note']
---

之前对KVC不是很了解，记得笔记比较多(其实大部分就是翻译了一下，没自己的理解)，也就不贴出来了. 1.KVC为其他的一些技术提供底层支持，比如KVO，AppleScript的执行。 2.KVC的基础是对key的操作，在此基础上提供了对keyPath的实现，默认的keypath使用了点分key的方式，但点分key的方法和KVC是两个相互独立的技术点。KVC是使用key或者keypath定位到与当前对象相关的对象的某个属性，并使用对key的操作对它进行获取设置修改之类的操作。 3.KVC的主要实现是通过对NSObject/NSArray/NSMutableDictionary/NSDictionary/NSSet/NSOrderedSet的扩展实现的，具体在NSKeyValueCoding.h这个文件中。 4.对KVC方法的调用比如valueForKey:，在默认实现(NSObject的实现)下，首先通过搜索一系列的特定方法，变量，如果找到，就返回对应的值，如果是非obejct的值，还对这个值进行封装，如果没有找到，会调用默认的异常处理方法valueForUndefinedKey:,这个方法默认产生一个异常。 5.其他的KVC方法实现也是类似的，方法调用引起一下步骤:1.搜索特定类型的方法，变量，进行默认操作；2.如果没有找到，进行其他转义方法的搜索；3.如果所有方法都不行，就调用默认的异常方法产生一个异常。 6.除了操作特定的一个属性，KVC提供了访问对象集合的属性的方法。 7.KVC提供了对集合类型的一些操作，比如@avg/@count/@max/@min/@sum/@distinctUnionOfObjects/@unionOfObjects/@distinctUnionOfArrays/@unionOfArrays/@distinctUnionOfSets