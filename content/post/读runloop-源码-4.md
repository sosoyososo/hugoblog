---
title: '读Runloop 源码'
date: Wed, 17 Jan 2018 06:31:58 +0000
draft: false
tags: ['iOS', 'Objective-C']
---

之前三篇我们大致走读一遍源码，我们在这里串联一下我们在源码中看到的一些小珠子。

原理总结
====

Mode Runloop Thread Source(Timer/source/block/observer)的关系
----------------------------------------------------------

runloop的运行必须指定mode,runloop的运行是处理这个mode相关的信息。thread根据需要，指定不同的mode，获取thread对应的runloop进行运行，处理加入到这个mode中的信息。根据API，每个thread只能一个runloop，但runloop内部的处理会涉及到其他thread，比如超时timer，比如其他的source，他们的触发是其他thread发送了mach msg,runloop接收到消息进行对应的处理。

Runloop的睡眠和唤醒
-------------

runloop处理某个mode的过程中，会等待mach msg的到来，这个等待会block当前线程的运行，也就是睡眠。这个等待在等待超时或者获得一个消息的时候结束，也就是runloop被唤醒，thread可以继续执行。睡眠时runloop的主动行为，正常的唤醒是其他thread发送mach msg导致，而超时是mach msg本身的逻辑，不涉及到其他thread。

Block
-----

block 带着 mode信息插入到runloop的一个链表中，在某个mode处理的时候，拿出这个mode下所有的block，进行调用。

Timer
-----

加入到runloop的timer是基于runloop的，是runloop每次运行的时候比较当前时间和timer触发时间，决定是否处罚相应操作。 内部使用的超时timer，在mach平台(apple系)下基于GCD timer,而在windows下基于windows下的WaitableTimer。

Source
------

source分为两种，一种是直接制定了回调函数的，在设置了isSignal之后，在runloop中被调用。另外一种还有一个相关的mach port，在获取到相关的mach msg的时候被回调。

Observer
--------

observer是在runloop运行的时候，在固定节点使用固定的参数进行调用。