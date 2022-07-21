---
title: '用 GCD 能做到的事情'
date: Sat, 27 Jan 2018 13:32:54 +0000
draft: false
tags: ['iOS', 'Objective-C']
---

一句话概括GCD的作用，就是简化多线程操作。而为了实现多线程简化，Apple为抽象常见的多线程操作为几个特定的场景，并且围绕这几个场景设计了GCD，来满足开发这日常需求。

串行和并发，同步和异步
-----------

> 涉及到类主要是 DispatchQueue

一组任务一个接一个的执行被称为穿行，并发则是多个任务同时执行。计算机按顺序执行函数的每个表达式就是同步执行，异步允许在表达式执行结果返回前执行下一个表达式。同步执行还可以在其他线程进行。所以同步和异步，串行和并发，在实质上说的是同一件事情，场景不同而已。
```

// queue 是串行还是并行的都无所谓
let queue: DispatchQueue = ...

// 在其他线程同步执行一个任务
queue.sync {
    task()
}

// 在其他线程异步执行一个任务
queue.async {
    task()
}

// 串行执行一些列任务
// serialQueue 是串行Queue
let serialQueue: DispatchQueue = ...
let tasks = ...
for i in 0..<tasks.count {  
    serialQueue.async {
        tasks[i]()
    }
}


// 并发执行一些列任务
// asynQueue 是并行Queue
let asynQueue: DispatchQueue = ...
let tasks = ...
for i in 0..<tasks.count {  
    asynQueue.async {
        tasks[i]()
    }
} 

```


延迟执行
----

> 涉及到的类型主要是 DispatchQueue DispatchTime DispatchWallTime


```

// queue 是串行还是并行的都无所谓
let queue: DispatchQueue = ...

// 延迟4秒执行任务
let time = DispatchTime.now() + DispatchTimeInterval.seconds(4)
queue.asyncAfter(deadline: time) {
    task()
} 

```


只执行一次
-----

> 涉及到的类型主要是 dispatch\_once\_t，函数 dispatch\_once


```

// Swift 中取消了dispatch once 相关的API，这里使用Objc来实现
static dispatch_once_t onceToken;
dispatch_once(&onceToken, ^{
    task()
}); 

```


组合任务
----

> 涉及到的新类型是 DispatchGroup

组合任务是为了在一些列任务执行结束之后获得通知。
```

// queue 是串行还是并行的都无所谓
let queue: DispatchQueue = ...
let tasks = ...

let group = DispatchGroup()
for i in 0..<tasks.count {
    group.enter()
    queue.async {
        tasks[i]()
       group.leave()
    }
}  
group.notify(queue: DispatchQueue.main) {
    notifyFinish()
} 

```


信号量
---

> 涉及到的新类型是 DispatchSemaphore

信号量是另外一种类型的锁，初始化的时候设置一个数量，表示资源数。每次调用wait，锁的数字减一，减到0之后，再调用wait的时候，就会等在这里，直到锁的数字大于0。wait和signal成对出现，signal使得锁的数字加一。
```

let resources = ...
let semaphore = DispatchSemaphore.init(value: resources.count) 
let tasks = ...

for i in o..<tasks.count {
    queue.async {
        semaphore.wait()
        let res = resources.popOne()
        tasks[i](res)
        resources.pushOne(res)
        semaphore.signal()
    }
} 

```


优先级
---

> 涉及到的新类型是 DispatchQoS DispatchQoS.QoSClass

### 队列级别

GCD会默认创建几个queue，可以通过main和global方法获取，其中global获取的时候可以指定一个优先级。其实当创建一个queue的时候就会要求指定优先级，优先级类型分为六个类型，每个类型又可以指定类型内部的相对优先级。

### 任务级别

iOS8开始，可以使用DispatchWorkItem来支持任务级别的优先级，swift使用它来替换OC中使用的dispatch\_block\_t。

系统事件监听
------

通过DispatchSource，dispatch提供了监听系统事件的功能。包括几种类型:

1.  文件操作事件
2.  mach msg 的发送和接收
3.  内存压力事件
4.  进程事件
5.  文件读取写入事件
6.  系统信号量监控
7.  定时器事件
8.  以及三个自定义事件


```

// dispatch 实现的定时器
let internalTimer = DispatchSource.makeTimerSource()
internalTimer.setEventHandler {
}
internalTimer.scheduleRepeating(deadline: DispatchTime.now() + 1, interval: 1) 

```


内存操作
----

> 可以配合 DispatchDataIterator 进行使用

DispatchData 提供将多段内存一年统一进行管理的功能。(应用层用的并不多，但系统底层特别是gcd的库中有广泛的使用)

IO操作
----

> 涉及到的新类型是 DispatchIO , 配合 DispatchData 进行使用

unix世界中一切都是文件，GCD同样对很常见的文件操作提供的简化多线程操作的API。这一系列的操作就是通过以DispatchIO为核心的一系列API进行实现的。

barrier(障碍物)
------------

在他之前添加的任务，先他执行，在他之后添加的任务，后他执行。通过DispatchWorkItem的flag来指定。