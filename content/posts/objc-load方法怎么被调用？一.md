---
title: 'Objc load方法怎么被调用？(一)'
date: Fri, 29 Sep 2017 07:41:10 +0000
draft: false
tags: ['Objective-C', 'Program Language', '瞎逼逼']
---

首先Objc runtime启动的时候(\_objc\_init是runtime的启动函数)向dyld注册了image状态监听，这是所有load方法被调用的入口:
```

#if !\_\_OBJC2\_\_
static \_\_attribute\_\_((constructor))
#endif
void \_objc\_init(void)
{
    static bool initialized = false;
    if (initialized) return;
    initialized = true;
    
    // fixme defer initialization until an objc-using image is found?
    environ\_init();
    tls\_init();
    static\_init();
    lock\_init();
    exception\_init();
        
    // Register for unmap first, in case some +load unmaps something
    \_dyld\_register\_func\_for\_remove\_image(&unmap\_image);
    dyld\_register\_image\_state\_change\_handler(dyld\_image\_state\_bound,
                                             1/\*batch\*/, &map\_2\_images);
    dyld\_register\_image\_state\_change\_handler(dyld\_image\_state\_dependents\_initialized, 0/\*not batch\*/, &load\_images);
}

```
每次有新的image被加载到内存中，就会先调用map\_2\_images，再调用load\_images 方法, 加递归锁后，load\_images\_nolock 函数遍历image信息，将class和load函数绑定，放到loadable\_classes列表中(category 放入 loadable\_categories 中)，做同样处理的还有涉及到的类的父类和category，所有需要加载的类带着load方法的实现，都放入了loadable\_classes中。call\_load\_methods方法遍历上面两个列表，执行load方法:
```

const char \*
load\_images(enum dyld\_image\_states state, uint32\_t infoCount,
           const struct dyld\_image\_info infoList\[\])
{
    bool found;

    recursive\_mutex\_locker\_t lock(loadMethodLock);

    // Discover +load methods
    found = load\_images\_nolock(state, infoCount, infoList);

    // Call +load methods (without classLock - re-entrant)
    if (found) {
        call\_load\_methods();
    }

    return nil;
}

```
需要注意的是,在load\_images\_nolock过程中可以看到，load方法是遍历直接从image信息中读取的方列表，比较方法名得来,这个跟obc其他方法调用的方式是不同的，并不会遍历类继承结构:
```

static IMP \_class\_getLoadMethod\_nocheck(Class cls)
{
    old\_method\_list \*mlist;
    mlist = get\_base\_method\_list(cls->ISA());
    if (mlist) {
        return lookupNamedMethodInMethodList (mlist, "load");
    }
    return nil;
}



IMP lookupNamedMethodInMethodList(old\_method\_list \*mlist, const char \*meth\_name)
{
    old\_method \*m;
    m = meth\_name ? \_findNamedMethodInList(mlist, meth\_name) : nil;
    return (m ? m->method\_imp : nil);
}

static inline old\_method \*\_findNamedMethodInList(old\_method\_list \* mlist, const char \*meth\_name) {
    int i;
    if (!mlist) return nil;
    if (ignoreSelectorNamed(meth\_name)) return nil;
    for (i = 0; i < mlist->method\_count; i++) {
        old\_method \*m = &mlist->method\_list\[i\];
        if (0 == strcmp((const char \*)(m->method\_name), meth\_name)) {
            return m;
        }
    }
    return nil;
}

```
但是这个方法列表从哪里来的？查get\_base\_method\_list代码发现，在调用这个方法的时候就已经构建好了，我们需要向上查，但这个流程一直到load\_images，都没有相关的操作。但我们发现最终的方便遍历实际上是遍历 struct objc\_class 的 methodLists :
```

static old\_method\_list \*get\_base\_method\_list(Class cls) 
{
    old\_method\_list \*\*ptr;

    if (!cls->methodLists) return nil;
    if (cls->info & CLS\_NO\_METHOD\_ARRAY) return (old\_method\_list \*)cls->methodLists;
    ptr = cls->methodLists;
    if (!\*ptr  ||  \*ptr == END\_OF\_METHODS\_LIST) return nil;
    while ( \*ptr != 0 && \*ptr != END\_OF\_METHODS\_LIST ) { ptr++; }
    --ptr;
    return \*ptr;
}

```
从最初，load\_images 的调用，到后面遍历的结构变成了 objc\_class 的 methodLists ，这中间又发生了怎样的转变？我们这个系列的第二篇看一下这个东西。