---
title: 'Objc load方法怎么被调用？(六)'
date: Mon, 23 Oct 2017 04:28:21 +0000
draft: false
tags: ['iOS', 'Objective-C']
---

前面一系列的内容都表明，load作为一个函数被调用，最初的来源是直接被加载到内存中的mach-o文件中的某个地址。我们从macho文件中去找一下，这个地址到底是怎么获取到的。 先看一下整体的结构，先随便找一个macho文件(我使用的是/usr/lib/libobjc.A.dylib)，使用machoview打开看一下结构: [![](http://www.karsa.info/blog/wp-content/uploads/2017/10/屏幕快照-2017-10-23-上午11.02.27.png)](http://www.karsa.info/blog/wp-content/uploads/2017/10/屏幕快照-2017-10-23-上午11.02.27.png) 可以看到这是个Universal Binary 文件，同时包含了三个架构的内容，细心的会发现有两个x86\_64，但其实还是有所不同，我们不偏题去讨论这个细节点，先只关注第一个x86\_64下面的macho结构。会发现大致可以分为： 1. Mach Header 对应 mach\_header\_64 ，说明一些必要的硬件信息 2. Load Commands，命令列表，指示在加载过程中需要执行的一些操作 3. Segment，包含文本段和数据段，\_\_TEXT段的\_\_text区域存着主体的汇编指令。有过有Objc类，会在—\_\_DATA段有类列表，协议列表，类别列表，selector列表等构建OC runtime 结构的信息。 4. Dynamic Loader Info，动态加载所需要的信息，动态加载将第三方代码在运行时加载到当前进程内存中，之后需要做一些额外的重定位操作，这些信息为重定位提供参数。 5. Segment Split Info，分段信息 6. Function Starts，函数在在代码段中起始点的列表， 7. Symbol Table， 8. Data In Code Entries，符号和符号位置信息的列表 9. Dynamic Symbol Table，符号和符号位置信息的列表 10.String Table，所有的字符串列表 11.Code Signature，代码文件签名内容 \_\_TEXT和\_\_DATA段中多个\_\_objc打头的区域中有很多类信息，系统根据这些信息是怎么构建类结构，并且将特定位置的指针添加上类型信息附加给类的呢？期待后续。。。