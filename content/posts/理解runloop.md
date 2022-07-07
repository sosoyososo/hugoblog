---
title: '理解Runloop'
date: Mon, 17 Jul 2017 03:01:32 +0000
draft: false
tags: ['iOS', 'Objective-C']
---

iOS中runloop广泛存在，事实上，在Apple的文档中说，系统创建的所有线程都有自己的Runloop，你不需要手动创建。Runloop存在的意义很简单，同样是官方文档也说明了，那就是在线程空闲的时候让它休眠，释放资源给其他的任务。他是如何做到的？在这里记录一下自己的理解。

循环什么
----

Runloop 物如其名，是个运行循环，循环的执行一系列任务。而执行什么任务，是由加入其中的事件源决定的，而所有加入到Runloop的事件源，组成了Runloop需要遍历的内容集合。Runloop遍历这个集合并不是按加入时间顺序，而是按照类型(timer->non-port-based input sources->port-based input source)。Runloop 遍历到一个事件源的时候，通过事件源获取到需要执行的任务，然后使用当前线程去执行。

怎么休眠
----

之前说Runloop执行有一定的顺序，其中一个就是执行 port-based input source 规定的任务，如果没有这种任务，Runloop会进入休眠。有四种情况会重新唤醒Runloop :
```

1. a port-based input source 事件源到来
2. 一个 Timer 事件
3. runloop超时
4. runloop被手动唤醒 

```


唤醒后
---

唤醒后的处理方式有三种:
```

1. 有Timer事件，就重启Runloop从处理timer开始
2. 如果有input source事件源，处理对应的任务，然后runloop一次循环结束
3. 手动唤醒并且没有超时，也重启Runloop从处理timer开始 

```


使用运行模式再分类
---------

除了输入源类型的分类，runloop还通过运行模式对事件源进行分组。在某个时间点，runloop只运行在一个特定的模式下，只遍历这个模式下的事件源。但运行模式也可以进行组合，就比如iOS中的Common runloop mode就是一个组合类型，加入到这个组的事件源，相当于是属于所有Common子模式的分组。Runloop当前的运行模式，是由执行runloop时候的调用所决定的(所以系统创建的runloop当然是系统决定运行模式，你自己创建的是你自己决定运行模式)。

运行模式
----

前面说过Common模式是一个组合默认，系统提供了Api可以修改这个组合，系统也提供了创建自定义的运行模式。 NSEventTrackingRunLoopMode 是一个特殊的运行模式，当用户在操作UI的时候，住线程的Runloop会进入这个模式。 默认使用的default模式不包含 NSEventTrackingRunLoopMode ，但 common 是包含这个模式的。

CADisplayLink
-------------

它是一个同步绘制动作和刷新率的特殊Timer，屏幕每次绘制的时候都会调用创建时候指定的任务。