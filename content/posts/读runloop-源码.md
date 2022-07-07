---
title: '读Runloop 源码'
date: Wed, 10 Jan 2018 09:53:23 +0000
draft: false
tags: ['iOS', 'Objective-C']
---

初始
==

在iOS开发中我们经常会遇到Runloop，对于runloop我们所知道的有以下几点:

1.  每个线程只有一个Runloop
2.  每个Runloop有多个mode
3.  每个mode可以加入多个源，可以是 NSTimer/NSPort/Block重的一种
4.  每个Runloop可以添加一些节点的观察者

iOS/MacOS的使用两个版本的Runloop，CGRunloop和NSRunloop，后者是前者的面向对象的封装，前者是开源的，我们将依次通过源码来解析以上所有的点。

深入
==

每个线程只有一个Runloop
---------------

获取CFRunloop的方式有两个： CFRunLoopGetCurrent 和 CFRunLoopGetMain，最终调用的都是\_CFRunLoopGet0。
```

CFRunLoopRef CFRunLoopGetMain(void)
{
    CHECK_FOR_FORK();
    static CFRunLoopRef __main = NULL; // no retain needed
    if (!__main)
        __main = _CFRunLoopGet0(pthread_main_thread_np()); // no CAS needed
    return __main;
}

CFRunLoopRef CFRunLoopGetCurrent(void)
{
    CHECK_FOR_FORK();
    CFRunLoopRef rl = (CFRunLoopRef)_CFGetTSD(__CFTSDKeyRunLoop);
    if (rl)
        return rl;
    return _CFRunLoopGet0(pthread_self());
}

CF_EXPORT CFRunLoopRef _CFRunLoopGet0(pthread_t t)
{
    // 注释点1
    if (pthread_equal(t, kNilPthreadT))
    {
        t = pthread_main_thread_np();
    }
    __CFLock(&loopsLock);

    // 注释点2
    if (!__CFRunLoops)
    {
        __CFUnlock(&loopsLock);
        CFMutableDictionaryRef dict = CFDictionaryCreateMutable(kCFAllocatorSystemDefault, 0, NULL, &kCFTypeDictionaryValueCallBacks);
        CFRunLoopRef mainLoop = __CFRunLoopCreate(pthread_main_thread_np());
        CFDictionarySetValue(dict, pthreadPointer(pthread_main_thread_np()), mainLoop);
        if (!OSAtomicCompareAndSwapPtrBarrier(NULL, dict, (void *volatile *)&__CFRunLoops))
        {
            CFRelease(dict);
        }
        CFRelease(mainLoop);
        __CFLock(&loopsLock);
    }

    //注释点3
    CFRunLoopRef loop = (CFRunLoopRef)CFDictionaryGetValue(__CFRunLoops, pthreadPointer(t));

    //注释点4
    __CFUnlock(&loopsLock);    
    if (!loop)
    {
        CFRunLoopRef newLoop = __CFRunLoopCreate(t);
        __CFLock(&loopsLock);
        loop = (CFRunLoopRef)CFDictionaryGetValue(__CFRunLoops, pthreadPointer(t));
        if (!loop)
        {
            CFDictionarySetValue(__CFRunLoops, pthreadPointer(t), newLoop);
            loop = newLoop;
        }
        // don't release run loops inside the loopsLock, because CFRunLoopDeallocate may end up taking it
        __CFUnlock(&loopsLock);
        CFRelease(newLoop);
    }

    //注释点5
    if (pthread_equal(t, pthread_self()))
    {
        _CFSetTSD(__CFTSDKeyRunLoop, (void *)loop, NULL);
        if (0 == _CFGetTSD(__CFTSDKeyRunLoopCntr))
        {
            _CFSetTSD(__CFTSDKeyRunLoopCntr, (void *)(PTHREAD_DESTRUCTOR_ITERATIONS - 1), (void (*)(void *))__CFFinalizeRunLoop);
        }
    }
    return loop;
} 

```


1.  如果没有指定线程，默认设置为主线程
2.  \_\_CFRunLoops 是全局静态的集合，保存线程和Runloop的对应关系。如果没有就创建。
3.  使用线程指针作为值从 \_\_CFRunLoops 获取对应的runloop
4.  如果不存在对应的runloop，就创建新的，并将新的runloop保存到 \_CFRunLoops 中
5.  将runloop存储到存放线程相关信息的一个表中

每个Runloop有多个mode
----------------

CFRunLoop是个结构体，定义如下：
```

struct __CFRunLoop
{
    CFRuntimeBase _base;
    pthread_mutex_t _lock; /* locked for accessing mode list */
    __CFPort _wakeUpPort;  // used for CFRunLoopWakeUp
    Boolean _unused;
    volatile _per_run_data *_perRunData; // reset for runs of the run loop
    pthread_t _pthread;
    uint32_t _winthread;
    CFMutableSetRef _commonModes;
    CFMutableSetRef _commonModeItems;
    CFRunLoopModeRef _currentMode;
    CFMutableSetRef _modes;
    struct _block_item *_blocks_head;
    struct _block_item *_blocks_tail;
    CFAbsoluteTime _runTime;
    CFAbsoluteTime _sleepTime;
    CFTypeRef _counterpart;
}; 

```
执行Runloop相关的调用有两个：CFRunLoopRun 和 CFRunLoopRunInMode，两者最终都调用了CFRunLoopRunSpecific：
```

//注释1
void CFRunLoopRun(void)
{ /* DOES CALLOUT */
    int32_t result;
    do
    {
        result = CFRunLoopRunSpecific(CFRunLoopGetCurrent(), kCFRunLoopDefaultMode, 1.0e10, false);
        CHECK_FOR_FORK();
    } while (kCFRunLoopRunStopped != result && kCFRunLoopRunFinished != result);
}

//注释2
SInt32 CFRunLoopRunInMode(CFStringRef modeName, CFTimeInterval seconds, Boolean returnAfterSourceHandled)
{ /* DOES CALLOUT */
    CHECK_FOR_FORK();
    return CFRunLoopRunSpecific(CFRunLoopGetCurrent(), modeName, seconds, returnAfterSourceHandled);
}


SInt32 CFRunLoopRunSpecific(CFRunLoopRef rl, CFStringRef modeName, CFTimeInterval seconds, Boolean returnAfterSourceHandled)
{ /* DOES CALLOUT */
    CHECK_FOR_FORK();
    if (__CFRunLoopIsDeallocating(rl))
        return kCFRunLoopRunFinished;
    __CFRunLoopLock(rl);

    //注释3
    CFRunLoopModeRef currentMode = __CFRunLoopFindMode(rl, modeName, false);
    if (NULL == currentMode || __CFRunLoopModeIsEmpty(rl, currentMode, rl->_currentMode))
    {
        Boolean did = false;
        if (currentMode)
            __CFRunLoopModeUnlock(currentMode);
        __CFRunLoopUnlock(rl);
        return did ? kCFRunLoopRunHandledSource : kCFRunLoopRunFinished;
    }

    //注释4    
    volatile _per_run_data *previousPerRun = __CFRunLoopPushPerRunData(rl);
    CFRunLoopModeRef previousMode = rl->_currentMode;
    rl->_currentMode = currentMode;
    int32_t result = kCFRunLoopRunFinished;

    //注释5
    if (currentMode->_observerMask & kCFRunLoopEntry)
        __CFRunLoopDoObservers(rl, currentMode, kCFRunLoopEntry);
    result = __CFRunLoopRun(rl, currentMode, seconds, returnAfterSourceHandled, previousMode);
    if (currentMode->_observerMask & kCFRunLoopExit)
        __CFRunLoopDoObservers(rl, currentMode, kCFRunLoopExit);

    //注释6
    __CFRunLoopModeUnlock(currentMode);
    __CFRunLoopPopPerRunData(rl, previousPerRun);
    rl->_currentMode = previousMode;
    __CFRunLoopUnlock(rl);
    return result;
} 

```


每个mode可以加入多个源
-------------

1.  CFRunLoopRun 是个无限循环，每个循环将当前的Runloop使用kCFRunLoopDefaultMode模式执行一次，知道结束或者停止。
2.  CFRunLoopRunInMode 就是直接调用 CFRunLoopRunSpecific
3.  获取名字指定的runloop mode，判断返回结果，然后保证mode内容非空
4.  保存runloop的currentMode，设置默认的runloop执行结果
5.  通知观察者 kCFRunLoopEntry 事件，执行一次 runloop，通知观察者 kCFRunLoopExit 事件
6.  释放相关数据，\_currentMode设置到当之前的值

添加相关事件源相关的调用有 CFRunLoopAddSource CFRunLoopAddTimer 和 CFRunLoopPerformBlock，其中block是直接放到一个链表中，其余两者在kCFRunLoopCommonModes下都是存储到\_commonModeItems中，其他时候处理略有不同, CFRunLoopAddTimer 是插入到对应mode的\_timers中，而CFRunLoopAddSource则更复杂，分了两种情况，根据source的类型分别插入对应mode的\_sources0和\_sources1中：
```

static Boolean __CFRunLoopDoTimer(CFRunLoopRef rl, CFRunLoopModeRef rlm, CFRunLoopTimerRef rlt) {
    ...
    __CFRepositionTimerInMode(rlm, rlt, false);
    ...
}

static void __CFRepositionTimerInMode(CFRunLoopModeRef rlm, CFRunLoopTimerRef rlt, Boolean isInArray) {
    ...
     CFMutableArrayRef timerArray = rlm->_timers;
    if (!timerArray)
        return;
    ...
    CFArrayInsertValueAtIndex(timerArray, newIdx, rlt);
    ... 
}

void CFRunLoopAddSource(CFRunLoopRef rl, CFRunLoopSourceRef rls, CFStringRef modeName) {
    ...
    if (0 == rls->_context.version0.version)
    {
        CFSetAddValue(rlm->_sources0, rls);
    }
    else if (1 == rls->_context.version0.version)
    {
        CFSetAddValue(rlm->_sources1, rls);
        __CFPort src_port = rls->_context.version1.getPort(rls->_context.version1.info);
        if (CFPORT_NULL != src_port)
        {
            CFDictionarySetValue(rlm->_portToV1SourceMap, (const void *)(uintptr_t)src_port, rls);
            __CFPortSetInsert(src_port, rlm->_portSet);
        }
    }
    ...
} 

```


每个Runloop可以添加一些节点的观察者
---------------------

添加观察者使用 CFRunLoopAddObserver ：
```

void CFRunLoopAddObserver(CFRunLoopRef rl, CFRunLoopObserverRef rlo, CFStringRef modeName)
{
    CHECK_FOR_FORK();
    CFRunLoopModeRef rlm;
    if (__CFRunLoopIsDeallocating(rl))
        return;        
    if (!__CFIsValid(rlo) || (NULL != rlo->_runLoop && rlo->_runLoop != rl))
        return;
    __CFRunLoopLock(rl);

     //注释1
    if (modeName == kCFRunLoopCommonModes)
    {
        CFSetRef set = rl->_commonModes ? CFSetCreateCopy(kCFAllocatorSystemDefault, rl->_commonModes) : NULL;
        if (NULL == rl->_commonModeItems)
        {
            rl->_commonModeItems = CFSetCreateMutable(kCFAllocatorSystemDefault, 0, &kCFTypeSetCallBacks);
        }
        CFSetAddValue(rl->_commonModeItems, rlo);        
        if (NULL != set)
        {
            CFTypeRef context[2] = {rl, rlo};
            /* add new item to all common-modes */
            CFSetApplyFunction(set, (__CFRunLoopAddItemToCommonModes), (void *)context);
            CFRelease(set);
        }
    }
    else
    //注释2
    {
        rlm = __CFRunLoopFindMode(rl, modeName, true);
        if (NULL != rlm && NULL == rlm->_observers)
        {
            rlm->_observers = CFArrayCreateMutable(kCFAllocatorSystemDefault, 0, &kCFTypeArrayCallBacks);
        }
        if (NULL != rlm && !CFArrayContainsValue(rlm->_observers, CFRangeMake(0, CFArrayGetCount(rlm->_observers)), rlo))
        {
            Boolean inserted = false;
            for (CFIndex idx = CFArrayGetCount(rlm->_observers); idx--;)
            {
                CFRunLoopObserverRef obs = (CFRunLoopObserverRef)CFArrayGetValueAtIndex(rlm->_observers, idx);
                if (obs->_order <= rlo->_order)
                {
                    CFArrayInsertValueAtIndex(rlm->_observers, idx + 1, rlo);
                    inserted = true;
                    break;
                }
            }
            if (!inserted)
            {
                CFArrayInsertValueAtIndex(rlm->_observers, 0, rlo);
            }
            rlm->_observerMask |= rlo->_activities;
            __CFRunLoopObserverSchedule(rlo, rl, rlm);
        }
        if (NULL != rlm)
        {
            __CFRunLoopModeUnlock(rlm);
        }
    }
    __CFRunLoopUnlock(rl);
} 

```


1.  如果是 kCFRunLoopCommonModes ，就加入到 \_commonModeItems中，\_commonModeItems不存在就创建新的\_commonModeItems，然后加入
2.  找到对应的mode，如有必要为他创建新的\_observers，判断\_observers中不包含要加入的观察者，有序插入观察者。