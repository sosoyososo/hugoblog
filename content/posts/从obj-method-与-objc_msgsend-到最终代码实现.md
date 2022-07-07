---
title: '从[obj method] 与 objc_msgSend 到最终代码实现'
date: Sun, 28 Aug 2016 08:55:15 +0000
draft: false
tags: ['iOS', 'Objective-C', 'Program Language']
---

bjc代码，从源码文件到最终的二进制机器码，会经历：
```

1. clang 处理 objc代码，转objc代码到c源码
2. 编译c源码到机器码 

```
\[obj method\] 的objc方法会被clang转为c代码 objc\_msgSend(obj, SEL\_for\_method, args ...) 。 objc\_msgSend 是汇编实现的，会发现每个CPU平台都有对应实现，有几个作用:
```

1. 找到对应的实现，调用实现
2. 找不到实现，调用fallback 

```
NSObject 有方法:
```

- (IMP)methodForSelector:(SEL)aSelector;
+ (IMP)instanceMethodForSelector:(SEL)aSelector; 

```
所以objc\_msgSend(self, sel, args)相当于:
```

IMP imp =[self methodForSelector: sel];
imp(args); 

```
methodForSelector和instanceMethodForSelector的实现在runtime中也有一份实现，所以两份实现必定是一样的逻辑。所以objc\_msgSend的内容只是比这两个方法多了一个调用的动作。