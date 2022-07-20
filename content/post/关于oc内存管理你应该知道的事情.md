---
title: '关于OC内存管理你应该知道的事情'
date: Fri, 26 Dec 2014 03:54:14 +0000
draft: false
tags: ['Read Note']
---

这是我对OC语言本身回顾的第三弹，熟悉的人直接跳过。 **内存管理的原理** OC内存管理是基于Reference Counting的。具体来说，对于每个runtime中的Object，保存一个引用计数，它被其他对象使用的时候，根据需要增加引用计数，引用它的对象生命周期结束的时候，根据需要，减少引用计数。 **ARC和MRR的区别** OC的内存管理有两种MRR(manual retain-release)和ARC(Automatic Reference Counting).MRR是利用NSObject和Objcruntime联合提供的功能手动进行一个对象生命周期的管理，ARC和MRR使用相同的RC(Reference Counting)功能，但是系统会在编译的时候自动的在适当的位置插入内存释放代码，由runtime自动管理内存，在OC范围内你只需要申请内存。跟C层(比如core fundation)交互的时候，只需要使用指定关键字说明内存管理权限的变化就好。 **ARC和非ARC的默认内存处理** MRR中默认赋值是strong,而ARC中默认是strong。这里的默认包含property声明和普通变量生命。 @property NSObject o; NSObject \*o = b; 在MRR中<==> //实际上在MRR中这里会有warning，提示没有assign,retain或copy，会假设是assign @property (assign) NSObject o; \_\_weak NSObject \*o = b; 在ARC中则<==> @property (strong) NSObject o; \_\_strong NSObject \*o = b; _note:多线程方面property默认是atomic的。_  
**内存相关的关键字和方法** 释放内容 dealloc 增加引用计数 new copy alloc retain strong mutableCopy \_\_strong 减少引用计数 release 不保存引用计数 assign weak \_\_weak \_\_unsafe\_unretained \_\_autoreleasing 说明引用计数权限转移 \_\_bridge \_\_bridge\_transfer CFBridgingRelease \_\_bridge\_retained CFBridgingRetain 其他 \_\_block  
**和cocoa的结合** \_\_bridge 没有内存转移 CFBridgingRetain \_\_bridge\_retained的作用相同，将OC对象转换成CF指针，并且说明需要CF来管理后续内存 \_\_bridge\_transfer or CFBridgingRelease将CF返回的对象release，并使用ARC来管理对象的生命周期  
**AutoreleasePool** @autoreleasepool{} 替换NSAutoreleasePool,大部分情况下速度会有提升。在block执行结束后，会对所有autorelease的对象内存进行释放。 但是大部分情况下你不需要使用，因为开发iOS程序的AppKit和UIKit在处理每个事件循环中都会使用autorelease pool block。所以每次事件循环都会对autorelease对象释放内存。 以下情况你需要自己创建autoreleasepool: 1.非UI程序 2.使用很多临时变量的循环，每个循环需要使用 3.创建辅助线程，在开始执行的时候就必须首先创建autoreleasepool。