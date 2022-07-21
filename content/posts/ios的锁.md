---
title: 'iOS的锁'
date: Tue, 21 Jul 2020 08:44:56 +0000
draft: false
tags: ['iOS', 'Objective-C']
---

通用锁分类
-----

1.  互斥锁：睡眠等待锁，锁定后睡眠，将执行权交还，直到锁状态解除。
2.  自旋锁：循环检测锁，锁定后循环检测锁状态，直到锁状态解除。
3.  互斥锁和自旋锁是性能和效率的两个方向。

锁的场景和本质
-------

1.  我们使用锁的目的是得到代码临界区，在临界区中的代码会被保证独立执行。独立执行是指要么可以执行，并且一次性的完整的执行结束，要么就不可执行。
2.  这种情况我们主要发生在多任务(多线程)场景下。
3.  锁的本质是数据操作的原子化。比如获取锁的本质类似于原子化以下操作，有变量a，获取a的值，进行比较a==0,失败就返回，成功就设置a=1。这一系列的操作，有个对应的硬件语言叫做 test\_and\_set， 不同硬件有不同硬件的具体指令。
4.  自旋锁在加锁时候，test\_and\_set 失败的时候，就进行下一个循环。互斥锁在获取失败的时候，进行睡眠，交出执行权限。
5.  互斥锁的执行，离不开对线程的操作，等待结束，等待超时等。这就是用到系统信号量的时候。持有锁的线程运行结束，交出锁的所有权，需要使用信号量通知等待锁的线程，唤醒该线程继续执行。
6.  而分布式锁、读写锁、条件锁都是对互斥锁和自选锁的封装。
7.  更顶层的api，直接对线程进行分装，变成任务队列，这种情况也可以保证同步执行，部分避免了锁的使用。
8.  但同一块代码，被作为不同任务多次提交并行执行的时候，并非独立执行，还是需要锁。多次提交多同步队列，则是独立执行，不需要锁。

iOS常用的锁分类
---------

Foundation
----------

#### NSLock、NSRecursiveLock、NSCondition、NSConditionLock、NSDistributedLock(非开源，使用gunstep对Foundation的模仿)

1.  NSLock、NSRecursiveLock 底层是 pthread\_mutex
2.  NSCondition 底层是 pthread\_mutex 和 pthread\_cond
3.  NSConditionLock 底层是 NSCondition
4.  NSDistributedLock底层是 NSLock

runtime
-------

#### @synchronized

1.  转换成 objc\_sync\_enter、objc\_sync\_exit
2.  底层使用recursive\_mutex\_lock、recursive\_mutex\_unlock（OC runtime内部利用tls(thread local storage)实现的）

#### (runtime的)atomic(property)

1.  利用sidetable的lock
2.  sidetable的lock使用spinlock\_t
3.  spinlock\_t 是 oc runtime定义的 mutex\_tt
4.  内部使用os\_unfair\_lock

### GCD

#### dispatch\_semaphore

1.  底层使用 dispatch\_atomic、semaphore\_timedwait、semaphore\_wait、semaphore\_signal

#### dispatch\_queue

1.  将任务串行化

#### dispatch\_barrier\_async

1.  底层使用 \_dispatch\_continuation
2.  \_dispatch\_continuation 是GCD内部定义

#### dispatch\_group

1.  底层使用 os\_atomic\_rmw\_loop2o、os\_atomic\_rmw\_loop\_give\_up\_with\_fence、os\_atomic\_rmw\_loop\_give\_up、os\_atomic\_load2o

pthread
-------

#### pthread\_mutex 、pthread\_rwlock、pthread\_cond、pthread\_once

1.  每个版本的实现略有差异
2.  最新版主要使用spin\_lock配合semaphore\_signal使用。
3.  spin\_lock则使用了内核锁引用的不同机器版本的识别

系统底层锁
-----

#### OSSpinLock(被os\_unfair\_lock代替)

1.  底层使用循环和os\_atomic系列函数实现。 os\_atomic\_cmpxchgv 、 os\_atomic\_cmpxchg、os\_atomic\_cmpxchg2o、os\_atomic\_store2o、os\_atomic\_load2o、os\_atomic\_store。 配合ulock\_wait、unlock\_wake。
2.  os\_ 打头的一系列函数是pthread的宏定义，比如os\_atomic\_cmpxchgv对应了os\_atomic\_cmpxchgv,间接对应C++的atomic\_compare\_exchange\_strong\_explicit。

#### os\_unfair\_lock

1.  跟OSSpinLock使用同样的底层技术，细节处不一样。

#### OSAtomic

1.  使用c++的\_\_c11\_atomic\_系列函数。