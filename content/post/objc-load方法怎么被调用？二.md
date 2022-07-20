---
title: 'Objc load方法怎么被调用？(二)'
date: Fri, 13 Oct 2017 08:49:49 +0000
draft: false
tags: ['iOS', 'Objective-C']
---

[之前一节](http://www.karsa.info/blog/?p=374)我们讲到获取load方法其实是直接从objc\_class 的 methodLists 里面直接读取到的，那么这一节来看一下class的method是如何建立起来的。 上一节的内容中，我们会发现在函数的调用起点load\_images到\_class\_getLoadMethod\_nocheck的过程中发生了某种转化，传入的参数也从 dyld\_image\_info 变成了 Class，load\_images 有两个分支，load\_images\_nolock 和 call\_load\_methods ，后者间接调用了call\_class\_loads,这个过城中一直都没有参数的传递。并且是通过遍历 loadable\_classes 这个全局列表变量中的类列表，获取到类的load方法。那么loadable\_classes是在哪里构建的？ 全局搜索 loadable\_classes ，我们不难发现 add\_class\_to\_loadable\_list 这个函数构建了 loadable\_classes，并且能看到同时在这里获取到了类的load方法。结合 load\_images 的路径，我们能会发现 dyld\_image\_info 到 Class 在这个路径下的转变:
```

void prepare\_load\_methods(const headerType \*mhdr)
{
    Module mods;
    unsigned int midx;

    header\_info \*hi;
    for (hi = FirstHeader; hi; hi = hi->next) {
        if (mhdr == hi->mhdr) break;
    }
    if (!hi) return;

    if (\_objcHeaderIsReplacement(hi)) {
        // Ignore any classes in this image
        return;
    }

    // Major loop - process all modules in the image
    mods = hi->mod\_ptr;
    for (midx = 0; midx < hi->mod\_count; midx += 1)
    {
        unsigned int index;

        // Skip module containing no classes
        if (mods\[midx\].symtab == nil)
            continue;

        // Minor loop - process all the classes in given module
        for (index = 0; index < mods\[midx\].symtab->cls\_def\_cnt; index += 1)
        {
            // Locate the class description pointer
            Class cls = (Class)mods\[midx\].symtab->defs\[index\];
            if (cls->info & CLS\_CONNECTED) {
                schedule\_class\_load(cls);
            }
        }
    }
...
}


```
在这里，我们发现，这个转变却是一个双层循环里面的强制转换，具体过程是： 1. 通过遍历FirstHeader链表，获取跟当前header一样的header\_info 类型的节点 N 2. 遍历 Ｎ　节点中　mod\_ptr　指针指向的　objc\_module　数据结构 M， 获取 Symtab 类型的 symtab 属性 S 3. 遍历 S 中 def 指向的 void\* 类型的指针 P 转换程 Class 。 后续我们追踪 FirstHeader 指引的链表的构建。