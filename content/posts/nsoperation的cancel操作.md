---
title: 'NSOPeration的cancel操作'
date: Wed, 27 Jun 2018 07:35:05 +0000
draft: false
tags: ['iOS', 'Objective-C']
---

跟某人的一次聊天让我怀疑了人生，于是再次跑回来看看GCD和NSOperation关于任务cancel的处理。 NSOPeration的cancel给人的第一印象是终止任务执行，但它实际上做的事只是取消执行。取消和终止有啥区别？拿约见一个人来说，取消是未来不见，但如果已经见了，那么自己约的，跪着也要约完。终止是未来不见，如果已经见了，那么马上离开。NSOPeration的cancel就属于前者，如果加入队列的任务还未执行，那么通过将它从队列取出或者标记状态的方式保证未来也不会执行。如果已经开始执行，就只能任由执行结束。 跟GCD有啥差别？GCD加入队列的任务，没有取消一说。但GCD可以做到NSOperation相似的取消操作不？当然可以，但你要自己写好多任务管理代码，NSOperation做的就是这件事，你为啥不用它？这就是NSOperation相对于GCD存在的意义。 看下面代码： `[op cancel];`完全无用。
```


#import "TestGCDAndQueue.h"

@interface TestOperation : NSOperation
@property void(^callBack)(int);
@end
@implementation TestOperation
- (void)main {
    for (int i = 0; i < 1000; i ++) {
        NSLog(@"%d", i);
        dispatch\_async(dispatch\_get\_global\_queue(DISPATCH\_QUEUE\_PRIORITY\_DEFAULT, 0), ^{
            self.callBack(i);
        });
    }
}
@end


static NSOperationQueue \*\_s\_queue;
@implementation TestGCDAndQueue
+ (void)testCancel {
    static dispatch\_once\_t onceToken;
    dispatch\_once(&onceToken, ^{
        \_s\_queue = \[\[NSOperationQueue alloc\] init\];
    });
    
    TestOperation \*op = \[\[TestOperation alloc\] init\];
    op.callBack = ^(int i) {
        NSLog(@"c %d", i);
        if (i > 100) {
            static dispatch\_once\_t onceToken;
            dispatch\_once(&onceToken, ^{
                NSArray \*ops = \_s\_queue.operations;
                for (NSOperation \*op in ops) {
                    \[op cancel\];
                    NSLog(@"cancel op");
                }
            });
        }
    };
    \[\_s\_queue addOperation:op\];
}

@end


```
