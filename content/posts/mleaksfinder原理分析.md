---
title: 'MLeaksFinder原理分析'
date: Sun, 04 Feb 2018 08:22:28 +0000
draft: false
tags: ['iOS', 'Objective-C']
---

MLeakFinder可以帮我们检测一些常见的对象是否被正常释放，并在有异常的时候进行提示。我们通过UIViewController的一个场景的分析来解释一下其中的原理。

步骤
--

1.  MLeakFinder的UIViewController扩展在load方法中，viewDidDisappear:的实现配合 UINavigationController来在UIViewController被pop出去的时候调用willDealloc。
2.  willDealloc 的实现首先调用了 NSObject+MemoryLeak 扩展的 willDealloc，
3.  willDealloc 然后调用 willReleaseChildren 构建了parentPtrs用来判断父对象是否被释放，还有viewStack来展示层级结构。
4.  willDealloc的NSObject默认实现在两秒后，如果没有被释放，就调用assertNotDealloc。(父对象会比子对象的生命周期先结束)
5.  assertNotDealloc 先判断是否有父对象未释放 a. 如果没有就使用当前对象 b. 创建MLeakedObjectProxy关联到当前对象 c. 将当前对象指针加入到leakedObjectPtrs d. 当前对象被释放的时候对应的MLeakedObjectProxy会被释放 e. MLeakedObjectProxy被释放的时候，对应的对象被从leakedObjectPtrs移除

核心步骤在第四第五步，使用了对象释放的时间差来判断是否有应该被释放的对象没有被释放。父对象的willDealloc比子对象先调用，所以父对象先被保存到leakedObjectPtrs，也先被从leakedObjectPtrs移除。

构建结构
----

子对象的viewStack和parentPtrs都包含了父对象的信息
```

// UIViewController+MemoryLeak.h
- (BOOL)willDealloc {
    if (![super willDealloc]) {
        return NO;
    }

    [self willReleaseChildren:self.childViewControllers];
    [self willReleaseChild:self.presentedViewController];

    if (self.isViewLoaded) {
        [self willReleaseChild:self.view];
    }

    return YES;
}


// NSObject+MemoryLeak.h
- (void)willReleaseChildren:(NSArray *)children {
    NSArray *viewStack = [self viewStack];
    NSSet *parentPtrs = [self parentPtrs];
    for (id child in children) {
        NSString *className = NSStringFromClass([child class]);
        [child setViewStack:[viewStack arrayByAddingObject:className]];
        [child setParentPtrs:[parentPtrs setByAddingObject:@((uintptr_t)child)]];
        [child willDealloc];
    }
} 

```


检查释放的关键点
--------


```

// NSObject+MemoryLeak.h
- (BOOL)willDealloc {
    NSString *className = NSStringFromClass([self class]);
    if ([[NSObject classNamesWhitelist] containsObject:className])
        return NO;

    NSNumber *senderPtr = objc_getAssociatedObject([UIApplication sharedApplication], kLatestSenderKey);
    if ([senderPtr isEqualToNumber:@((uintptr_t)self)])
        return NO;

    __weak id weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 1.保存当前对象生命周期
        __strong id strongSelf = weakSelf; 
        // 2.延迟两秒调用assertNotDealloc
        [strongSelf assertNotDealloc]; 
    });

    return YES;
}

- (void)assertNotDealloc {
     // 3.判断当前对象有父对象没有被释放
    if ([MLeakedObjectProxy isAnyObjectLeakedAtPtrs:[self parentPtrs]]) { 
        return;
    }

    // 4.当前对象加入到leakedObjectPtrs中
    [MLeakedObjectProxy addLeakedObject:self];

    NSString *className = NSStringFromClass([self class]);
    NSLog(@"Possibly Memory Leak.\nIn case that %@ should not be dealloced, override -willDealloc in %@ by returning NO.\nView-ViewController stack: %@", className, className, [self viewStack]);
}

// MLeakedObjectProxy.h
+ (BOOL)isAnyObjectLeakedAtPtrs:(NSSet *)ptrs {
    NSAssert([NSThread isMainThread], @"Must be in main thread.");

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        leakedObjectPtrs = [[NSMutableSet alloc] init];
    });

    if (!ptrs.count) {
        return NO;
    }
    if ([leakedObjectPtrs intersectsSet:ptrs]) {
        return YES;
    } else {
        return NO;
    }
}

+ (void)addLeakedObject:(id)object {
    NSAssert([NSThread isMainThread], @"Must be in main thread.");

    MLeakedObjectProxy *proxy = [[MLeakedObjectProxy alloc] init];
    proxy.object = object;
    proxy.objectPtr = @((uintptr_t)object);
    proxy.viewStack = [object viewStack];
    static const void *const kLeakedObjectProxyKey = &kLeakedObjectProxyKey;
    objc_setAssociatedObject(object, kLeakedObjectProxyKey, proxy, OBJC_ASSOCIATION_RETAIN);    
    [leakedObjectPtrs addObject:proxy.objectPtr];    
    [MLeaksMessenger alertWithTitle:@"Memory Leak"
                            message:[NSString stringWithFormat:@"%@",proxy.viewStack]];
}

- (void)dealloc {
    NSNumber *objectPtr = _objectPtr;
    NSArray *viewStack = _viewStack;
    dispatch_async(dispatch_get_main_queue(), ^{
        [leakedObjectPtrs removeObject:objectPtr];
        [MLeaksMessenger alertWithTitle:@"Object Deallocated"
                                message:[NSString stringWithFormat:@"%@", viewStack]];
    });
} 

```


原理总结
----

对象的生命周期不会被改变，在willDealloc被调用之后两秒，判断对象应该已经被释放，如果没有被释放就提示，并且加入到leakedObjectPtrs，如果短时间内被释放，重复提示已经被释放。