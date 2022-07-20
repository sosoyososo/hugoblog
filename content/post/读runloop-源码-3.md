---
title: '读Runloop 源码'
date: Sun, 14 Jan 2018 13:06:55 +0000
draft: false
tags: ['iOS', 'Objective-C']
---

源码中CFRunLoopRun 和 CFRunLoopRunInMode 都是运行了CFRunLoopRunSpecific，只是 CFRunLoopRun 只是在一个while循环里循环运行，而 CFRunLoopRunInMode 只是运行了 CFRunLoopRunSpecific 一次。CFRunLoopRunSpecific是找到对应的mode，然后使用这个mode作为参数运行了 \_\_CFRunLoopRun。

单次运行
====

> 为了稍微简短一些，这里删除了很多windows相关的代码


```

static int32_t __CFRunLoopRun(CFRunLoopRef rl, CFRunLoopModeRef rlm, CFTimeInterval seconds, Boolean stopAfterHandle, CFRunLoopModeRef previousMode)
{
    //注释1
    mach_port_name_t dispatchPort = MACH_PORT_NULL;
    Boolean libdispatchQSafe = pthread_main_np() && ((HANDLE_DISPATCH_ON_BASE_INVOCATION_ONLY && NULL == previousMode) || (!HANDLE_DISPATCH_ON_BASE_INVOCATION_ONLY && 0 == _CFGetTSD(__CFTSDKeyIsInGCDMainQ)));
    if (libdispatchQSafe && (CFRunLoopGetMain() == rl) && CFSetContainsValue(rl->_commonModes, rlm->_name))
        dispatchPort = _dispatch_get_main_queue_port_4CF();


#if USE_DISPATCH_SOURCE_FOR_TIMERS
    mach_port_name_t modeQueuePort = MACH_PORT_NULL;
    if (rlm->_queue)
    {       
          //注释2
        modeQueuePort = _dispatch_runloop_root_queue_get_port_4CF(rlm->_queue);
        if (!modeQueuePort)
        {
            CRASH("Unable to get port for run loop mode queue (%d)", -1);
        }
    }
#endif

     //注释3
    dispatch_source_t timeout_timer = NULL;
    struct __timeout_context *timeout_context = (struct __timeout_context *)malloc(sizeof(*timeout_context));
    if (seconds <= 0.0)
    { // instant timeout
        seconds = 0.0;
        timeout_context->termTSR = 0ULL;
    }
    else if (seconds <= TIMER_INTERVAL_LIMIT)
    {
        dispatch_queue_t queue = pthread_main_np() ? __CFDispatchQueueGetGenericMatchingMain() : __CFDispatchQueueGetGenericBackground();
        timeout_timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        dispatch_retain(timeout_timer);
        timeout_context->ds = timeout_timer;
        timeout_context->rl = (CFRunLoopRef)CFRetain(rl);
        timeout_context->termTSR = startTSR + __CFTimeIntervalToTSR(seconds);
        dispatch_set_context(timeout_timer, timeout_context); // source gets ownership of context
        dispatch_source_set_event_handler_f(timeout_timer, __CFRunLoopTimeout);
        dispatch_source_set_cancel_handler_f(timeout_timer, __CFRunLoopTimeoutCancel);
        uint64_t ns_at = (uint64_t)((__CFTSRToTimeInterval(startTSR) + seconds) * 1000000000ULL);
        dispatch_source_set_timer(timeout_timer, dispatch_time(1, ns_at), DISPATCH_TIME_FOREVER, 1000ULL);
        dispatch_resume(timeout_timer);
    }
    else
    { // infinite timeout
        seconds = 9999999999.0;
        timeout_context->termTSR = UINT64_MAX;
    }

    //注释4
    Boolean didDispatchPortLastTime = true;
    int32_t retVal = 0;
    do
    {
#if DEPLOYMENT_TARGET_MACOSX || DEPLOYMENT_TARGET_EMBEDDED || DEPLOYMENT_TARGET_EMBEDDED_MINI
        voucher_mach_msg_state_t voucherState = VOUCHER_MACH_MSG_STATE_UNCHANGED;
        voucher_t voucherCopy = NULL;
#endif
        uint8_t msg_buffer[3 * 1024];
        mach_msg_header_t *msg = NULL;
        mach_port_t livePort = MACH_PORT_NULL;
        __CFPortSet waitSet = rlm->_portSet;

        __CFRunLoopUnsetIgnoreWakeUps(rl);

          //注释5
        if (rlm->_observerMask & kCFRunLoopBeforeTimers)
            __CFRunLoopDoObservers(rl, rlm, kCFRunLoopBeforeTimers);
        if (rlm->_observerMask & kCFRunLoopBeforeSources)
            __CFRunLoopDoObservers(rl, rlm, kCFRunLoopBeforeSources);

         //注释6
        __CFRunLoopDoBlocks(rl, rlm);

         //注释7
        Boolean sourceHandledThisLoop = __CFRunLoopDoSources0(rl, rlm, stopAfterHandle);
        if (sourceHandledThisLoop)
        {
            __CFRunLoopDoBlocks(rl, rlm);
        }

        Boolean poll = sourceHandledThisLoop || (0ULL == timeout_context->termTSR);

          //注释8
        if (MACH_PORT_NULL != dispatchPort && !didDispatchPortLastTime)
        {
            msg = (mach_msg_header_t *)msg_buffer;
            if (__CFRunLoopServiceMachPort(dispatchPort, &msg, sizeof(msg_buffer), &livePort, 0, &voucherState, NULL))
            {
                goto handle_msg;
            }
        }

        didDispatchPortLastTime = false;

          //注释9
        if (!poll && (rlm->_observerMask & kCFRunLoopBeforeWaiting))
            __CFRunLoopDoObservers(rl, rlm, kCFRunLoopBeforeWaiting);

        //注释10
        __CFRunLoopSetSleeping(rl);
        // do not do any user callouts after this point (after notifying of sleeping)

        // Must push the local-to-this-activation ports in on every loop
        // iteration, as this mode could be run re-entrantly and we don't
        // want these ports to get serviced.

         //注释11
        __CFPortSetInsert(dispatchPort, waitSet);

        __CFRunLoopModeUnlock(rlm);
        __CFRunLoopUnlock(rl);

        CFAbsoluteTime sleepStart = poll ? 0.0 : CFAbsoluteTimeGetCurrent();

#if USE_DISPATCH_SOURCE_FOR_TIMERS
        do
        {
            if (kCFUseCollectableAllocator)
            {
                // objc_clear_stack(0);
                // <rdar://problem/16393959>
                memset(msg_buffer, 0, sizeof(msg_buffer));
            }
            msg = (mach_msg_header_t *)msg_buffer;

              //注释12            
            __CFRunLoopServiceMachPort(waitSet, &msg, sizeof(msg_buffer), &livePort, poll ? 0 : TIMEOUT_INFINITY, &voucherState, &voucherCopy);

            if (modeQueuePort != MACH_PORT_NULL && livePort == modeQueuePort)
            {
                // Drain the internal queue. If one of the callout blocks sets the timerFired flag, break out and service the timer.
                while (_dispatch_runloop_root_queue_perform_4CF(rlm->_queue))
                    ;
                if (rlm->_timerFired)
                {
                    // Leave livePort as the queue port, and service timers below
                    rlm->_timerFired = false;
                    break;
                }
                else
                {
                    if (msg && msg != (mach_msg_header_t *)msg_buffer)
                        free(msg);
                }
            }
            else
            {
                // Go ahead and leave the inner loop.
                break;
            }
        } while (1);
#else
        if (kCFUseCollectableAllocator)
        {
            // objc_clear_stack(0);
            // <rdar://problem/16393959>
            memset(msg_buffer, 0, sizeof(msg_buffer));
        }
        msg = (mach_msg_header_t *)msg_buffer;
        __CFRunLoopServiceMachPort(waitSet, &msg, sizeof(msg_buffer), &livePort, poll ? 0 : TIMEOUT_INFINITY, &voucherState, &voucherCopy);
#endif

        __CFRunLoopLock(rl);
        __CFRunLoopModeLock(rlm);

          //注释13
        rl->_sleepTime += (poll ? 0.0 : (CFAbsoluteTimeGetCurrent() - sleepStart));

        // Must remove the local-to-this-activation ports in on every loop
        // iteration, as this mode could be run re-entrantly and we don't
        // want these ports to get serviced. Also, we don't want them left
        // in there if this function returns.

         //注释14
        __CFPortSetRemove(dispatchPort, waitSet);

        __CFRunLoopSetIgnoreWakeUps(rl);

        // user callouts now OK again
        __CFRunLoopUnsetSleeping(rl);
        //注释15
        if (!poll && (rlm->_observerMask & kCFRunLoopAfterWaiting))
            __CFRunLoopDoObservers(rl, rlm, kCFRunLoopAfterWaiting);

    handle_msg:;
        __CFRunLoopSetIgnoreWakeUps(rl);

         //注释16-1
        if (MACH_PORT_NULL == livePort)
        {
            CFRUNLOOP_WAKEUP_FOR_NOTHING();
            // handle nothing
        }
        //注释16-2
        else if (livePort == rl->_wakeUpPort)          
        {
            CFRUNLOOP_WAKEUP_FOR_WAKEUP();
            // do nothing on Mac OS
        }
#if USE_DISPATCH_SOURCE_FOR_TIMERS
        //注释16-3
        else if (modeQueuePort != MACH_PORT_NULL && livePort == modeQueuePort)
        {
            CFRUNLOOP_WAKEUP_FOR_TIMER();
            if (!__CFRunLoopDoTimers(rl, rlm, mach_absolute_time()))
            {
                // Re-arm the next timer, because we apparently fired early
                __CFArmNextTimerInMode(rlm, rl);
            }
        }
#endif
#if USE_MK_TIMER_TOO
        //注释16-4
        else if (rlm->_timerPort != MACH_PORT_NULL && livePort == rlm->_timerPort)
        {
            CFRUNLOOP_WAKEUP_FOR_TIMER();
            // On Windows, we have observed an issue where the timer port is set before the time which we requested it to be set. For example, we set the fire time to be TSR 167646765860, but it is actually observed firing at TSR 167646764145, which is 1715 ticks early. The result is that, when __CFRunLoopDoTimers checks to see if any of the run loop timers should be firing, it appears to be 'too early' for the next timer, and no timers are handled.
            // In this case, the timer port has been automatically reset (since it was returned from MsgWaitForMultipleObjectsEx), and if we do not re-arm it, then no timers will ever be serviced again unless something adjusts the timer list (e.g. adding or removing timers). The fix for the issue is to reset the timer here if CFRunLoopDoTimers did not handle a timer itself. 9308754
            if (!__CFRunLoopDoTimers(rl, rlm, mach_absolute_time()))
            {
                // Re-arm the next timer
                __CFArmNextTimerInMode(rlm, rl);
            }
        }
#endif
         //注释16-5
        else if (livePort == dispatchPort)
        {
            CFRUNLOOP_WAKEUP_FOR_DISPATCH();
            __CFRunLoopModeUnlock(rlm);
            __CFRunLoopUnlock(rl);
            _CFSetTSD(__CFTSDKeyIsInGCDMainQ, (void *)6, NULL);
            __CFRUNLOOP_IS_SERVICING_THE_MAIN_DISPATCH_QUEUE__(msg);
            _CFSetTSD(__CFTSDKeyIsInGCDMainQ, (void *)0, NULL);
            __CFRunLoopLock(rl);
            __CFRunLoopModeLock(rlm);
            sourceHandledThisLoop = true;
            didDispatchPortLastTime = true;
        }
        //注释16-6
        else
        {
            CFRUNLOOP_WAKEUP_FOR_SOURCE();

            // If we received a voucher from this mach_msg, then put a copy of the new voucher into TSD. CFMachPortBoost will look in the TSD for the voucher. By using the value in the TSD we tie the CFMachPortBoost to this received mach_msg explicitly without a chance for anything in between the two pieces of code to set the voucher again.
            voucher_t previousVoucher = _CFSetTSD(__CFTSDKeyMachMessageHasVoucher, (void *)voucherCopy, os_release);

            // Despite the name, this works for windows handles as well
            CFRunLoopSourceRef rls = __CFRunLoopModeFindSourceForMachPort(rl, rlm, livePort);
            if (rls)
            {
                mach_msg_header_t *reply = NULL;
                sourceHandledThisLoop = __CFRunLoopDoSource1(rl, rlm, rls, msg, msg->msgh_size, &reply) || sourceHandledThisLoop;
                if (NULL != reply)
                {
                    (void)mach_msg(reply, MACH_SEND_MSG, reply->msgh_size, 0, MACH_PORT_NULL, 0, MACH_PORT_NULL);
                    CFAllocatorDeallocate(kCFAllocatorSystemDefault, reply);
                }
            }

            // Restore the previous voucher
            _CFSetTSD(__CFTSDKeyMachMessageHasVoucher, previousVoucher, os_release);
        }

        if (msg && msg != (mach_msg_header_t *)msg_buffer)
            free(msg);

        __CFRunLoopDoBlocks(rl, rlm);

         //注释17
        if (sourceHandledThisLoop && stopAfterHandle)
        {
            retVal = kCFRunLoopRunHandledSource;
        }
        else if (timeout_context->termTSR < mach_absolute_time())
        {
            retVal = kCFRunLoopRunTimedOut;
        }
        else if (__CFRunLoopIsStopped(rl))
        {
            __CFRunLoopUnsetStopped(rl);
            retVal = kCFRunLoopRunStopped;
        }
        else if (rlm->_stopped)
        {
            rlm->_stopped = false;
            retVal = kCFRunLoopRunStopped;
        }
        else if (__CFRunLoopModeIsEmpty(rl, rlm, previousMode))
        {
            retVal = kCFRunLoopRunFinished;
        }

        voucher_mach_msg_revert(voucherState);
        os_release(voucherCopy);
    } while (0 == retVal);

    if (timeout_timer)
    {
        dispatch_source_cancel(timeout_timer);
        dispatch_release(timeout_timer);
    }
    else
    {
        free(timeout_context);
    }

    return retVal;
} 

```


1.  dispatchPort 用于唤醒runloop，处理CF相关的一些mach msg
2.  modeQueuePort 是用来获取计时器mach msg的port
3.  创建并设置timeout\_timer，超时回调计时器
4.  循环处理mode
5.  两个observer回调
6.  处理当前mode所有的block
7.  处理source0之后，再次处理当前mode所有的block(source0回调处理过程中添加的block处理)
8.  如果dispatchPort中有消息，直接跳转到最后处理消息阶段
9.  跳过8之后，发出准备休眠消息
10.  设置runloop为休眠状态
11.  将dispatchPort插入到waitSet中
12.  等待从waitSet所有的port中收消息，带超时的阻塞等待(runloop的睡眠实现)。
13.  醒来之后计算睡眠时间
14.  将 dispatchPort 从 waitSet 中移除，后续不再会等待这个port
15.  通知醒来
16.  各种醒来的处理
17.  处理结果(关系到是不是要退出4开始的循环)