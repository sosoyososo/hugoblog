---
title: '读Runloop 源码'
date: Fri, 12 Jan 2018 15:54:16 +0000
draft: false
tags: ['iOS', 'Objective-C']
---

运行原理篇
=====

加到到runloop中的内容分为4类:block,timer,source,observer,我们分别看一下他们的加入和触发过程。

Block
-----

### 加入


```

void CFRunLoopPerformBlock(CFRunLoopRef rl, CFTypeRef mode, void (^block)(void))
{
    CHECK_FOR_FORK();
    //注释1
    if (CFStringGetTypeID() == CFGetTypeID(mode))
    {
        mode = CFStringCreateCopy(kCFAllocatorSystemDefault, (CFStringRef)mode);
        __CFRunLoopLock(rl);
        // ensure mode exists
        CFRunLoopModeRef currentMode = __CFRunLoopFindMode(rl, (CFStringRef)mode, true);
        if (currentMode)
            __CFRunLoopModeUnlock(currentMode);
        __CFRunLoopUnlock(rl);
    }
    else if (CFArrayGetTypeID() == CFGetTypeID(mode))
    {
        CFIndex cnt = CFArrayGetCount((CFArrayRef)mode);
        const void **values = (const void **)malloc(sizeof(const void *) * cnt);
        CFArrayGetValues((CFArrayRef)mode, CFRangeMake(0, cnt), values);
        mode = CFSetCreate(kCFAllocatorSystemDefault, values, cnt, &kCFTypeSetCallBacks);
        __CFRunLoopLock(rl);
        // ensure modes exist
        for (CFIndex idx = 0; idx < cnt; idx++)
        {
            CFRunLoopModeRef currentMode = __CFRunLoopFindMode(rl, (CFStringRef)values[idx], true);
            if (currentMode)
                __CFRunLoopModeUnlock(currentMode);
        }
        __CFRunLoopUnlock(rl);
        free(values);
    }
    else if (CFSetGetTypeID() == CFGetTypeID(mode))
    {
        CFIndex cnt = CFSetGetCount((CFSetRef)mode);
        const void **values = (const void **)malloc(sizeof(const void *) * cnt);
        CFSetGetValues((CFSetRef)mode, values);
        mode = CFSetCreate(kCFAllocatorSystemDefault, values, cnt, &kCFTypeSetCallBacks);
        __CFRunLoopLock(rl);
        // ensure modes exist
        for (CFIndex idx = 0; idx < cnt; idx++)
        {
            CFRunLoopModeRef currentMode = __CFRunLoopFindMode(rl, (CFStringRef)values[idx], true);
            if (currentMode)
                __CFRunLoopModeUnlock(currentMode);
        }
        __CFRunLoopUnlock(rl);
        free(values);
    }
    else
    {
        mode = NULL;
    }

    //注释2
    block = Block_copy(block);

    //注释3
    if (!mode || !block)
    {
        if (mode)
            CFRelease(mode);
        if (block)
            Block_release(block);
        return;
    }
    __CFRunLoopLock(rl);

    //注释4
    struct _block_item *new_item = (struct _block_item *)malloc(sizeof(struct _block_item));
    new_item->_next = NULL;
    new_item->_mode = mode;
    new_item->_block = block;
    if (!rl->_blocks_tail)
    {
        rl->_blocks_head = new_item;
    }
    else
    {
        rl->_blocks_tail->_next = new_item;
    }
    rl->_blocks_tail = new_item;
    __CFRunLoopUnlock(rl);
} 

```


1.  根据传入mode的不同类型，都保证执行block的mode存在，如果不存在就创建
2.  将block拷贝一份
3.  如果mode没有创建成功或者block不存在就直接退出
4.  将block加入到runloop的block链表的尾端(\_blocks\_tail是结尾)

> 加入到所有mode的block在runloop的中存储在同一个链表中，在每次运行的时候判断当前的mode，选择合适的执行然后删除。

### 执行


```

static Boolean __CFRunLoopDoBlocks(CFRunLoopRef rl, CFRunLoopModeRef rlm)
{ // Call with rl and rlm locked
    if (!rl->_blocks_head)
        return false;
    if (!rlm || !rlm->_name)
        return false;

     // 注释1        
    Boolean did = false;
    struct _block_item *head = rl->_blocks_head;
    struct _block_item *tail = rl->_blocks_tail;
    rl->_blocks_head = NULL;
    rl->_blocks_tail = NULL;
    CFSetRef commonModes = rl->_commonModes;
    CFStringRef curMode = rlm->_name;
    __CFRunLoopModeUnlock(rlm);
    __CFRunLoopUnlock(rl);
    struct _block_item *prev = NULL;
    struct _block_item *item = head;

    // 注释2
    while (item)
    {
        struct _block_item *curr = item;
        item = item->_next;
        Boolean doit = false;

          // 注释3
        if (CFStringGetTypeID() == CFGetTypeID(curr->_mode)) 
        {
            doit = CFEqual(curr->_mode, curMode) || (CFEqual(curr->_mode, kCFRunLoopCommonModes) && CFSetContainsValue(commonModes, curMode));
        }
        else
        {
            doit = CFSetContainsValue((CFSetRef)curr->_mode, curMode) || (CFSetContainsValue((CFSetRef)curr->_mode, kCFRunLoopCommonModes) && CFSetContainsValue(commonModes, curMode));
        }

        // 注释4
        if (!doit)
            prev = curr;                     
        if (doit)
        {
            if (prev)
                prev->_next = item;
            if (curr == head)
                head = item;
            if (curr == tail)
                tail = prev;
            void (^block)(void) = curr->_block;
            CFRelease(curr->_mode);
            free(curr);
            if (doit)
            {
                __CFRUNLOOP_IS_CALLING_OUT_TO_A_BLOCK__(block);
                did = true;
            }
            Block_release(block); // do this before relocking to prevent deadlocks where some yahoo wants to run the run loop reentrantly from their dealloc
        }
    }    
    __CFRunLoopLock(rl);
    __CFRunLoopModeLock(rlm);    

    // 注释5
    if (head)
    {
        tail->_next = rl->_blocks_head;
        rl->_blocks_head = head;
        if (!rl->_blocks_tail)
            rl->_blocks_tail = tail;
    }
    return did;
} 

```


1.  将链表摘离出来单独操作
2.  遍历链表
3.  block的mode就是当前mode或者当前是commonmode且在commonmode包含当前mode
4.  如果需要执行，把当前block从链表移除，并执行block
5.  将摘离出来并处理过的链表还原到runloop

Timer
-----

### 加入


```

void CFRunLoopAddTimer(CFRunLoopRef rl, CFRunLoopTimerRef rlt, CFStringRef modeName)
{
    CHECK_FOR_FORK();
    if (__CFRunLoopIsDeallocating(rl))
        return;
    if (!__CFIsValid(rlt) || (NULL != rlt->_runLoop && rlt->_runLoop != rl))
        return;
    __CFRunLoopLock(rl);


    if (modeName == kCFRunLoopCommonModes)
    {            
        CFSetRef set = rl->_commonModes ? CFSetCreateCopy(kCFAllocatorSystemDefault, rl->_commonModes) : NULL;      
         // 注释1
        if (NULL == rl->_commonModeItems)
        {
            rl->_commonModeItems = CFSetCreateMutable(kCFAllocatorSystemDefault, 0, &kCFTypeSetCallBacks);
        }
        CFSetAddValue(rl->_commonModeItems, rlt);

         // 注释2
        if (NULL != set)
        {
            CFTypeRef context[2] = {rl, rlt};
            /* add new item to all common-modes */
            CFSetApplyFunction(set, (__CFRunLoopAddItemToCommonModes), (void *)context);
            CFRelease(set);
        }
    }
    else
    {   
         // 注释3
        CFRunLoopModeRef rlm = __CFRunLoopFindMode(rl, modeName, true);
        if (NULL != rlm)
        {
            if (NULL == rlm->_timers)
            {
                CFArrayCallBacks cb = kCFTypeArrayCallBacks;
                cb.equal = NULL;
                rlm->_timers = CFArrayCreateMutable(kCFAllocatorSystemDefault, 0, &cb);
            }
        }

        // 注释4
        if (NULL != rlm && !CFSetContainsValue(rlt->_rlModes, rlm->_name))
        {
              // 注释5
            __CFRunLoopTimerLock(rlt);
            if (NULL == rlt->_runLoop)
            {
                rlt->_runLoop = rl;
            }
            else if (rl != rlt->_runLoop)
            {
                __CFRunLoopTimerUnlock(rlt);
                __CFRunLoopModeUnlock(rlm);
                __CFRunLoopUnlock(rl);
                return;
            }

            // 注释6
            CFSetAddValue(rlt->_rlModes, rlm->_name);

              // 注释7                        
            __CFRunLoopTimerUnlock(rlt);
            __CFRunLoopTimerFireTSRLock();
            __CFRepositionTimerInMode(rlm, rlt, false);
            __CFRunLoopTimerFireTSRUnlock();


            if (!_CFExecutableLinkedOnOrAfter(CFSystemVersionLion))
            {
                // Normally we don't do this on behalf of clients, but for
                // backwards compatibility due to the change in timer handling...
                if (rl != CFRunLoopGetCurrent())
                    CFRunLoopWakeUp(rl);
            }
        }
        if (NULL != rlm)
        {
            __CFRunLoopModeUnlock(rlm);
        }
    }
    __CFRunLoopUnlock(rl);
} 

```


1.  如果需要加入的是commonmodes,runloop的\_commonModeItems不存在就创建一个新的，将timer加入到\_commonModeItems中
2.  如果runloop中已有commonmodes，将timer加入到所有commonmodes所包含的mode中
3.  找到(如有必要创建新的)mode
4.  判断timer的存储的mode列表不包含当前的mode
5.  设置timer的runloop，如果已存在的runloop跟当前不一致就结束添加过程
6.  将当前mode的名字添加到timer的\_rlModes列表中
7.  设置timer，并在当前mode中的timer进行排序

> timer会包含runloop信息和所有可以触发它的mode，在执行的时候进行判断

### 执行


```

static Boolean __CFRunLoopDoTimers(CFRunLoopRef rl, CFRunLoopModeRef rlm, uint64_t limitTSR)
{ /* DOES CALLOUT */
    Boolean timerHandled = false;
    CFMutableArrayRef timers = NULL;
    //注释1
    for (CFIndex idx = 0, cnt = rlm->_timers ? CFArrayGetCount(rlm->_timers) : 0; idx < cnt; idx++)
    {
        CFRunLoopTimerRef rlt = (CFRunLoopTimerRef)CFArrayGetValueAtIndex(rlm->_timers, idx);

        if (__CFIsValid(rlt) && !__CFRunLoopTimerIsFiring(rlt))
        {
            if (rlt->_fireTSR <= limitTSR)
            {
                if (!timers)
                    timers = CFArrayCreateMutable(kCFAllocatorSystemDefault, 0, &kCFTypeArrayCallBacks);
                CFArrayAppendValue(timers, rlt);
            }
        }
    }

    //注释2
    for (CFIndex idx = 0, cnt = timers ? CFArrayGetCount(timers) : 0; idx < cnt; idx++)
    {
        CFRunLoopTimerRef rlt = (CFRunLoopTimerRef)CFArrayGetValueAtIndex(timers, idx);
        Boolean did = __CFRunLoopDoTimer(rl, rlm, rlt);
        timerHandled = timerHandled || did;
    }
    if (timers)
        CFRelease(timers);
    return timerHandled;
} 

```


1.  遍历mode中所有的timer，找出当前可以触发的timer
2.  遍历以上timer列表，进行触发


```

static Boolean __CFRunLoopDoTimer(CFRunLoopRef rl, CFRunLoopModeRef rlm, CFRunLoopTimerRef rlt)
{ /* DOES CALLOUT */
    Boolean timerHandled = false;
    uint64_t oldFireTSR = 0;

    /* Fire a timer */
    CFRetain(rlt);
    __CFRunLoopTimerLock(rlt);

    //注释1
    if (__CFIsValid(rlt) && rlt->_fireTSR <= mach_absolute_time() && !__CFRunLoopTimerIsFiring(rlt) && rlt->_runLoop == rl)
    {
        void *context_info = NULL;
        void (*context_release)(const void *) = NULL;
        if (rlt->_context.retain)
        {
            context_info = (void *)rlt->_context.retain(rlt->_context.info);
            context_release = rlt->_context.release;
        }
        else
        {
            context_info = rlt->_context.info;
        }
        Boolean doInvalidate = (0.0 == rlt->_interval);

        //注释2
        __CFRunLoopTimerSetFiring(rlt);
        // Just in case the next timer has exactly the same deadlines as this one, we reset these values so that the arm next timer code can correctly find the next timer in the list and arm the underlying timer.
        rlm->_timerSoftDeadline = UINT64_MAX;
        rlm->_timerHardDeadline = UINT64_MAX;
        __CFRunLoopTimerUnlock(rlt);
        __CFRunLoopTimerFireTSRLock();
        oldFireTSR = rlt->_fireTSR;
        __CFRunLoopTimerFireTSRUnlock();

        //注释3
        __CFArmNextTimerInMode(rlm, rl);

        __CFRunLoopModeUnlock(rlm);
        __CFRunLoopUnlock(rl);
        //注释4
        __CFRUNLOOP_IS_CALLING_OUT_TO_A_TIMER_CALLBACK_FUNCTION__(rlt->_callout, rlt, context_info);
        CHECK_FOR_FORK();

         //注释5
        if (doInvalidate)
        {
            CFRunLoopTimerInvalidate(rlt); /* DOES CALLOUT */
        }
        if (context_release)
        {
            context_release(context_info);
        }
        __CFRunLoopLock(rl);
        __CFRunLoopModeLock(rlm);
        __CFRunLoopTimerLock(rlt);
        timerHandled = true;
        //注释5
        __CFRunLoopTimerUnsetFiring(rlt);
    }
    if (__CFIsValid(rlt) && timerHandled)
    {                 
        /* This is just a little bit tricky: we want to support calling
         * CFRunLoopTimerSetNextFireDate() from within the callout and
         * honor that new time here if it is a later date, otherwise
         * it is completely ignored. */
        if (oldFireTSR < rlt->_fireTSR)
        {            
            /* Next fire TSR was set, and set to a date after the previous
            * fire date, so we honor it. */
            __CFRunLoopTimerUnlock(rlt);
            // The timer was adjusted and repositioned, during the
            // callout, but if it was still the min timer, it was
            // skipped because it was firing.  Need to redo the
            // min timer calculation in case rlt should now be that
            // timer instead of whatever was chosen.
            //注释5
            __CFArmNextTimerInMode(rlm, rl);
        }
        else
        {
              //注释6
            uint64_t nextFireTSR = 0LL;
            uint64_t intervalTSR = 0LL;
            if (rlt->_interval <= 0.0)
            {
            }
            else if (TIMER_INTERVAL_LIMIT < rlt->_interval)
            {
                intervalTSR = __CFTimeIntervalToTSR(TIMER_INTERVAL_LIMIT);
            }
            else
            {
                intervalTSR = __CFTimeIntervalToTSR(rlt->_interval);
            }
            if (LLONG_MAX - intervalTSR <= oldFireTSR)
            {
                nextFireTSR = LLONG_MAX;
            }
            else
            {
                if (intervalTSR == 0)
                {
                    // 15304159: Make sure we don't accidentally loop forever here
                    CRSetCrashLogMessage("A CFRunLoopTimer with an interval of 0 is set to repeat");
                    HALT;
                }
                uint64_t currentTSR = mach_absolute_time();
                nextFireTSR = oldFireTSR;
                while (nextFireTSR <= currentTSR)
                {
                    nextFireTSR += intervalTSR;
                }
            }


            CFRunLoopRef rlt_rl = rlt->_runLoop;
            if (rlt_rl)
            {
                CFRetain(rlt_rl);
                CFIndex cnt = CFSetGetCount(rlt->_rlModes);
                STACK_BUFFER_DECL(CFTypeRef, modes, cnt);
                CFSetGetValues(rlt->_rlModes, (const void **)modes);
                // To avoid A->B, B->A lock ordering issues when coming up
                // towards the run loop from a source, the timer has to be
                // unlocked, which means we have to protect from object
                // invalidation, although that's somewhat expensive.
                for (CFIndex idx = 0; idx < cnt; idx++)
                {
                    CFRetain(modes[idx]);
                }
                __CFRunLoopTimerUnlock(rlt);
                //注释6
                for (CFIndex idx = 0; idx < cnt; idx++)
                {
                    CFStringRef name = (CFStringRef)modes[idx];
                    modes[idx] = (CFTypeRef)__CFRunLoopFindMode(rlt_rl, name, false);
                    CFRelease(name);
                }
                __CFRunLoopTimerFireTSRLock();

                //注释7
                rlt->_fireTSR = nextFireTSR;
                rlt->_nextFireDate = CFAbsoluteTimeGetCurrent() + __CFTimeIntervalUntilTSR(nextFireTSR);

                //注释8
                for (CFIndex idx = 0; idx < cnt; idx++)
                {
                    CFRunLoopModeRef rlm = (CFRunLoopModeRef)modes[idx];
                    if (rlm)
                    {
                        __CFRepositionTimerInMode(rlm, rlt, true);
                    }
                }
                __CFRunLoopTimerFireTSRUnlock();

                for (CFIndex idx = 0; idx < cnt; idx++)
                {
                    __CFRunLoopModeUnlock((CFRunLoopModeRef)modes[idx]);
                }
                CFRelease(rlt_rl);
            }
            else
            {
                __CFRunLoopTimerUnlock(rlt);
                __CFRunLoopTimerFireTSRLock();
                rlt->_fireTSR = nextFireTSR;
                rlt->_nextFireDate = CFAbsoluteTimeGetCurrent() + __CFTimeIntervalUntilTSR(nextFireTSR);
                __CFRunLoopTimerFireTSRUnlock();
            }
        }
    }
    else
    {
        __CFRunLoopTimerUnlock(rlt);
    }
    CFRelease(rlt);
    return timerHandled;
} 

```


1.  判断已经到了当前timer的触发时间，并且可以被触发
2.  设置为正在触发中
3.  调整当前mode的timer源触发时间
4.  设置触发结束
5.  正如英文注释所说，如果重置了当前timer的触发时间，就再调整一次mode的timer源触发时间
6.  找到定时器所有的mode
7.  设置timer下一个触发时间
8.  在所有mode中，对timer进行重新排位

> 从这里可以看到，加入runloop的timer其实就是基于runloop循环的判断时间点进行触发。

#### 问题

1.  为什么timer里面存储了多个mode，mode里面存储了多个timer，mode里面又有一个timer源，这到底是毛意思啊？

> timer加入到runloop，实际上是加入到一个确定的mode中，runloop的运行也是多个mode的交叉运行，在某个mode运行的时候，只会查看当前mode中的timer是否需要被触发。而加入mode的timer可以是多个，所以mode中会有一个timer列表。 同时timer是可以被加入到runloop的多个mode中去的，所以timer中也维护了一个mode名字的列表，以便在一个mode中触发的时候，更新他在所有mode中的位置 mode中的timer则是一个额外的逻辑，这个timer用来在当前mode中所有timer被触发之后设置mode的\_timerFired参数为true。我们在 \_\_CFArmNextTimerInMode 中会看到，在mac/ios中会使用GCD计时器作为触发源。

Observer
--------

### 加入


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


> 可以看到加入的方式跟timer类似，commonmode的时候加入到\_commonModeItems，同时加入commonmode的所有mode中 加入其他mode，实际是有序的加入到mode的\_observers中

### 执行


```

static void __CFRunLoopDoObservers(CFRunLoopRef rl, CFRunLoopModeRef rlm, CFRunLoopActivity activity)
{ /* DOES CALLOUT */
    CHECK_FOR_FORK();

    CFIndex cnt = rlm->_observers ? CFArrayGetCount(rlm->_observers) : 0;
    if (cnt < 1)
        return;

    /* Fire the observers */
    STACK_BUFFER_DECL(CFRunLoopObserverRef, buffer, (cnt <= 1024) ? cnt : 1);
    CFRunLoopObserverRef *collectedObservers = (cnt <= 1024) ? buffer : (CFRunLoopObserverRef *)malloc(cnt * sizeof(CFRunLoopObserverRef));
    CFIndex obs_cnt = 0;
    //注释1
    for (CFIndex idx = 0; idx < cnt; idx++)
    {
        CFRunLoopObserverRef rlo = (CFRunLoopObserverRef)CFArrayGetValueAtIndex(rlm->_observers, idx);
        if (0 != (rlo->_activities & activity) && __CFIsValid(rlo) && !__CFRunLoopObserverIsFiring(rlo))
        {
            collectedObservers[obs_cnt++] = (CFRunLoopObserverRef)CFRetain(rlo);
        }
    }
    __CFRunLoopModeUnlock(rlm);
    __CFRunLoopUnlock(rl);
    //注释2
    for (CFIndex idx = 0; idx < obs_cnt; idx++)
    {
        CFRunLoopObserverRef rlo = collectedObservers[idx];
        __CFRunLoopObserverLock(rlo);
        if (__CFIsValid(rlo))
        {

            Boolean doInvalidate = !__CFRunLoopObserverRepeats(rlo);
            __CFRunLoopObserverSetFiring(rlo);
            __CFRunLoopObserverUnlock(rlo);
            //注释3
            __CFRUNLOOP_IS_CALLING_OUT_TO_AN_OBSERVER_CALLBACK_FUNCTION__(rlo->_callout, rlo, activity, rlo->_context.info);     
            //注释4       
            if (doInvalidate)
            {
                CFRunLoopObserverInvalidate(rlo);
            }
            __CFRunLoopObserverUnsetFiring(rlo);
        }
        else
        {
            __CFRunLoopObserverUnlock(rlo);
        }
        CFRelease(rlo);
    }
    __CFRunLoopLock(rl);
    __CFRunLoopModeLock(rlm);

    if (collectedObservers != buffer)
        free(collectedObservers);  
} 

```


1.  搜集所有可以被触发的observer到列表
2.  遍历别表中的observer
3.  触发observer
4.  将不能重复触发的observer设置为无效

Source
------

### 加入


```

void CFRunLoopAddSource(CFRunLoopRef rl, CFRunLoopSourceRef rls, CFStringRef modeName) {
    ...
     if (NULL != rlm && !CFSetContainsValue(rlm->_sources0, rls) && !CFSetContainsValue(rlm->_sources1, rls))
        {
                //注释1
            if (0 == rls->_context.version0.version)
            {
                CFSetAddValue(rlm->_sources0, rls);
            }
            else if (1 == rls->_context.version0.version)
            {
                    //注释2
                CFSetAddValue(rlm->_sources1, rls);

                //注释3
                __CFPort src_port = rls->_context.version1.getPort(rls->_context.version1.info);
                if (CFPORT_NULL != src_port)
                {
                    CFDictionarySetValue(rlm->_portToV1SourceMap, (const void *)(uintptr_t)src_port, rls);
                    __CFPortSetInsert(src_port, rlm->_portSet);
                }
            }
            __CFRunLoopSourceLock(rls);

            //注释4
            if (NULL == rls->_runLoops)
            {
                rls->_runLoops = CFBagCreateMutable(kCFAllocatorSystemDefault, 0, &kCFTypeBagCallBacks); // sources retain run loops!
            }
            CFBagAddValue(rls->_runLoops, rl);

            __CFRunLoopSourceUnlock(rls);  

            //注释5          
            if (0 == rls->_context.version0.version)
            {
                if (NULL != rls->_context.version0.schedule)
                {   
                        //
                    doVer0Callout = true;
                }
            }
        }
    ...
    //注释6
    if (doVer0Callout)
    {
        // although it looses some protection for the source, we have no choice but
        // to do this after unlocking the run loop and mode locks, to avoid deadlocks
        // where the source wants to take a lock which is already held in another
        // thread which is itself waiting for a run loop/mode lock
        rls->_context.version0.schedule(rls->_context.version0.info, rl, modeName); /* CALLOUT */
    }
    ...
} 

```
其他的地方跟timer和observer类似，只列出核心代码。

1.  source0的话加入到mode的\_sources0中
2.  source1加入到mode的\_sources1中
3.  source1还要更新mode的\_portSet
4.  source的\_runLoops中加入当前runloop
5.  判断时候需要加入source后回调source1
6.  如有必要回调source1

> 可以看出一个source并没有被限制只能加入到一个runloop中

### 执行


```

static Boolean __CFRunLoopDoSources0(CFRunLoopRef rl, CFRunLoopModeRef rlm, Boolean stopAfterHandle)
{ /* DOES CALLOUT */
    CHECK_FOR_FORK();
    CFTypeRef sources = NULL;
    Boolean sourceHandled = false;

    //注释1
    /* Fire the version 0 sources */
    if (NULL != rlm->_sources0 && 0 < CFSetGetCount(rlm->_sources0))
    {
        CFSetApplyFunction(rlm->_sources0, (__CFRunLoopCollectSources0), &sources);
    }

    if (NULL != sources)
    {
        __CFRunLoopModeUnlock(rlm);
        __CFRunLoopUnlock(rl);
        // sources is either a single (retained) CFRunLoopSourceRef or an array of (retained) CFRunLoopSourceRef
        if (CFGetTypeID(sources) == CFRunLoopSourceGetTypeID())
        {   
             //注释2
            CFRunLoopSourceRef rls = (CFRunLoopSourceRef)sources;
            __CFRunLoopSourceLock(rls);
            if (__CFRunLoopSourceIsSignaled(rls))
            {
                __CFRunLoopSourceUnsetSignaled(rls);
                if (__CFIsValid(rls))
                {
                    __CFRunLoopSourceUnlock(rls);
                    //注释3
                    __CFRUNLOOP_IS_CALLING_OUT_TO_A_SOURCE0_PERFORM_FUNCTION__(rls->_context.version0.perform, rls->_context.version0.info);
                    CHECK_FOR_FORK();
                    sourceHandled = true;
                }
                else
                {
                    __CFRunLoopSourceUnlock(rls);
                }
            }
            else
            {
                __CFRunLoopSourceUnlock(rls);
            }
        }
        else
        {   //注释4
            CFIndex cnt = CFArrayGetCount((CFArrayRef)sources);
            CFArraySortValues((CFMutableArrayRef)sources, CFRangeMake(0, cnt), (__CFRunLoopSourceComparator), NULL);
            for (CFIndex idx = 0; idx < cnt; idx++)
            {
                CFRunLoopSourceRef rls = (CFRunLoopSourceRef)CFArrayGetValueAtIndex((CFArrayRef)sources, idx);
                __CFRunLoopSourceLock(rls);
                if (__CFRunLoopSourceIsSignaled(rls))
                {
                    __CFRunLoopSourceUnsetSignaled(rls);
                    if (__CFIsValid(rls))
                    {
                        __CFRunLoopSourceUnlock(rls);
                        __CFRUNLOOP_IS_CALLING_OUT_TO_A_SOURCE0_PERFORM_FUNCTION__(rls->_context.version0.perform, rls->_context.version0.info);
                        CHECK_FOR_FORK();
                        sourceHandled = true;
                    }
                    else
                    {
                        __CFRunLoopSourceUnlock(rls);
                    }
                }
                else
                {
                    __CFRunLoopSourceUnlock(rls);
                }
                if (stopAfterHandle && sourceHandled)
                {
                    break;
                }
            }
        }
        CFRelease(sources);
        __CFRunLoopLock(rl);
        __CFRunLoopModeLock(rlm);
    }
    return sourceHandled;
} 

```


1.  搜集所有可以执行的source0
2.  处理单个source0
3.  调用source0回调
4.  用处理单个的方式处理多个source0


```

static Boolean __CFRunLoopDoSource1(CFRunLoopRef rl, CFRunLoopModeRef rlm, CFRunLoopSourceRef rls
#if DEPLOYMENT_TARGET_MACOSX || DEPLOYMENT_TARGET_EMBEDDED || DEPLOYMENT_TARGET_EMBEDDED_MINI
                                    ,
                                    mach_msg_header_t *msg, CFIndex size, mach_msg_header_t **reply
#endif
)
{ /* DOES CALLOUT */
    CHECK_FOR_FORK();
    Boolean sourceHandled = false;

    /* Fire a version 1 source */
    CFRetain(rls);
    __CFRunLoopModeUnlock(rlm);
    __CFRunLoopUnlock(rl);
    __CFRunLoopSourceLock(rls);
    if (__CFIsValid(rls))
    {
        __CFRunLoopSourceUnsetSignaled(rls);
        __CFRunLoopSourceUnlock(rls);
        __CFRunLoopDebugInfoForRunLoopSource(rls);
        __CFRUNLOOP_IS_CALLING_OUT_TO_A_SOURCE1_PERFORM_FUNCTION__(rls->_context.version1.perform,
#if DEPLOYMENT_TARGET_MACOSX || DEPLOYMENT_TARGET_EMBEDDED || DEPLOYMENT_TARGET_EMBEDDED_MINI
                                                                   msg, size, reply,
#endif
                                                                   rls->_context.version1.info);
        CHECK_FOR_FORK();
        sourceHandled = true;
    }
    else
    {
        if (_LogCFRunLoop)
        {
            CFLog(kCFLogLevelDebug, CFSTR("%p (%s) __CFRunLoopDoSource1 rls %p is invalid"), CFRunLoopGetCurrent(), *_CFGetProgname(), rls);
        }
        __CFRunLoopSourceUnlock(rls);
    }
    CFRelease(rls);
    __CFRunLoopLock(rl);
    __CFRunLoopModeLock(rlm);
    return sourceHandled;
} 

```


> 就是简单的调用source1的perform函数。