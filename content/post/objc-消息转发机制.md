---
title: 'objc 消息转发机制'
date: Mon, 29 Aug 2016 02:13:39 +0000
draft: false
tags: ['iOS', 'Objective-C', 'Program Language']
---

之前有聊到objc方法调用的核心在找出objc方法的实现，这部分的逻辑主要在 NSObject 的 methodForSelector: 和 instanceMethodForSelector: 里面。看rumtime可以看到这两个方法的实现最终都落到 class\_getMethodImplementation ，所以我们只看这个方法的实现即可理解objc的消息实现机制。 核心代码如下，返回的\_objc\_msgSend\_uncached\_impcache被转成\_objc\_msgForward:
```

IMP lookUpImpOrForward(Class cls, SEL sel, id inst, 
                       bool initialize, bool cache, bool resolver)
{
    Class curClass;
    IMP imp = nil;
    Method meth;
    bool triedResolver = NO;

    runtimeLock.assertUnlocked();

    // Optimistic cache lookup
    if (cache) {
        imp = cache_getImp(cls, sel);
        if (imp) return imp;
    }

    if (!cls->isRealized()) {
        rwlock_writer_t lock(runtimeLock);
        realizeClass(cls);
    }

    if (initialize  &&  !cls->isInitialized()) {
        _class_initialize (_class_getNonMetaClass(cls, inst));
        // If sel == initialize, _class_initialize will send +initialize and 
        // then the messenger will send +initialize again after this 
        // procedure finishes. Of course, if this is not being called 
        // from the messenger then it won't happen. 2778172
    }

    // The lock is held to make method-lookup + cache-fill atomic 
    // with respect to method addition. Otherwise, a category could 
    // be added but ignored indefinitely because the cache was re-filled 
    // with the old value after the cache flush on behalf of the category.
 retry:
    runtimeLock.read();

    // Ignore GC selectors
    if (ignoreSelector(sel)) {
        imp = _objc_ignored_method;
        cache_fill(cls, sel, imp, inst);
        goto done;
    }

    // Try this class's cache.
    imp = cache_getImp(cls, sel);
    if (imp) goto done;

    // Try this class's method lists.
    meth = getMethodNoSuper_nolock(cls, sel); //内部核心实现是 _findMethodInClass
    if (meth) {
        log_and_fill_cache(cls, meth->imp, sel, inst, cls);
        imp = meth->imp;
        goto done;
    }

    // Try superclass caches and method lists.
    curClass = cls;
    while ((curClass = curClass->superclass)) {
        // Superclass cache.
        imp = cache_getImp(curClass, sel);
        if (imp) {
            if (imp != (IMP)_objc_msgForward_impcache) {
                // Found the method in a superclass. Cache it in this class.
                log_and_fill_cache(cls, imp, sel, inst, curClass);
                goto done;
            }
            else {
                // Found a forward:: entry in a superclass.
                // Stop searching, but don't cache yet; call method 
                // resolver for this class first.
                break;
            }
        }

        // Superclass method list.
        meth = getMethodNoSuper_nolock(curClass, sel);
        if (meth) {
            log_and_fill_cache(cls, meth->imp, sel, inst, curClass);
            imp = meth->imp;
            goto done;
        }
    }

    // No implementation found. Try method resolver once.

    if (resolver  &&  !triedResolver) {
        runtimeLock.unlockRead();
        _class_resolveMethod(cls, sel, inst);
        // Don't cache the result; we don't hold the lock so it may have 
        // changed already. Re-do the search from scratch instead.
        triedResolver = YES;
        goto retry;
    }

    // No implementation found, and method resolver didn't help. 
    // Use forwarding.

    imp = (IMP)_objc_msgForward_impcache;
    cache_fill(cls, sel, imp, inst);

 done:
    runtimeLock.unlockRead();

    // paranoia: look for ignored selectors with non-ignored implementations
    assert(!(ignoreSelector(sel)  &&  imp != (IMP)&_objc_ignored_method));

    // paranoia: never let uncached leak out
    assert(imp != _objc_msgSend_uncached_impcache);

    return imp;
} 

```


1.  搜索缓存
2.  如果class没有初始化，进行初始化
3.  如果是GC method，\_objc\_ignhored\_method 作为IMP返回，并且放入缓存
4.  再次搜索缓存
5.  搜索类方法实现，并且设置缓存
6.  循环搜索所有继承层次上的方法缓存，并且搜索每个类方法更新缓存
7.  重新解析一次类的方法，并且跳转到第3步，开始新一次的解析
8.  返回 \_objc\_msgForward\_impcache ，并且更新缓存