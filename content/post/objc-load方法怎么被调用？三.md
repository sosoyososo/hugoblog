---
title: 'Objc load方法怎么被调用？(三)'
date: Fri, 13 Oct 2017 11:32:47 +0000
draft: false
tags: ['iOS', 'Objective-C']
---

[前一节](http://www.karsa.info/blog/?p=395)我们讲到了class的遍历是间接遍历FirstHeader链表内容而来，那么这个链表是怎么构建的？又有哪些内容呢？ 在 objc\_init 中我们看到其实注册dyld的回调还有一个，那就是 map\_2\_images ，他跟 load\_images 注册的区别就是第一个参数，看函数说明我们可以知道这是一个状态位，那么dyld\_image\_state\_bound和dyld\_image\_state\_dependents\_initialized两个状态有什么区别？我们暂时可以不太理他，只是知道这两个状态是dyld加载mach-o文件的两个不同阶段，dyld\_image\_state\_bound发生在dyld\_image\_state\_dependents\_initialized之前即可。那么也就是 map\_2\_images 应该就发生在 load\_images 之前，我们之前寻找的 FirstHeader的构建没有发生在后者的调用链中，应该就在前者的调用链中。 向下简单追查 map\_2\_images -> map\_images\_nolock :
```

const char \*
map\_images\_nolock(enum dyld\_image\_states state, uint32\_t infoCount,
                  const struct dyld\_image\_info infoList\[\])
{

...

    hCount = 0;
    i = infoCount;
    while (i--) {
        const headerType \*mhdr = (headerType \*)infoList\[i\].imageLoadAddress;

        hi = addHeader(mhdr);
        
        ...
    }
...
}



static header\_info \* addHeader(const headerType \*mhdr)
{
    header\_info \*hi;

    if (bad\_magic(mhdr)) return NULL;

#if \_\_OBJC2\_\_
    // Look for hinfo from the dyld shared cache.
    hi = preoptimizedHinfoForHeader(mhdr);
    if (hi) {
        // Found an hinfo in the dyld shared cache.

        // Weed out duplicates.
        if (hi->loaded) {
            return NULL;
        }

        // Initialize fields not set by the shared cache
        // hi->next is set by appendHeader
        hi->fname = dyld\_image\_path\_containing\_address(hi->mhdr);
        hi->loaded = true;
        hi->inSharedCache = true;

        if (PrintPreopt) {
            \_objc\_inform("PREOPTIMIZATION: honoring preoptimized header info at %p for %s", hi, hi->fname);
        }

# if DEBUG
        // Verify image\_info
        size\_t info\_size = 0;
        const objc\_image\_info \*image\_info = \_getObjcImageInfo(mhdr,&info\_size);
        assert(image\_info == hi->info);
# endif
    }
    else 
#endif
    {
        // Didn't find an hinfo in the dyld shared cache.

        // Weed out duplicates
        for (hi = FirstHeader; hi; hi = hi->next) {
            if (mhdr == hi->mhdr) return NULL;
        }

        // Locate the \_\_OBJC segment
        size\_t info\_size = 0;
        unsigned long seg\_size;
        const objc\_image\_info \*image\_info = \_getObjcImageInfo(mhdr,&info\_size);
        const uint8\_t \*objc\_segment = getsegmentdata(mhdr,SEG\_OBJC,&seg\_size);
        if (!objc\_segment  &&  !image\_info) return NULL;

        // Allocate a header\_info entry.
        hi = (header\_info \*)calloc(sizeof(header\_info), 1);

        // Set up the new header\_info entry.
        hi->mhdr = mhdr;
#if !\_\_OBJC2\_\_
        // mhdr must already be set
        hi->mod\_count = 0;
        hi->mod\_ptr = \_getObjcModules(hi, &hi->mod\_count);
#endif
        hi->info = image\_info;
        hi->fname = dyld\_image\_path\_containing\_address(hi->mhdr);
        hi->loaded = true;
        hi->inSharedCache = false;
        hi->allClassesRealized = NO;
    }

    // dylibs are not allowed to unload
    // ...except those with image\_info and nothing else (5359412)
    if (hi->mhdr->filetype == MH\_DYLIB  &&  \_hasObjcContents(hi)) {
        dlopen(hi->fname, RTLD\_NOLOAD);
    }

    appendHeader(hi);
    
    return hi;
}


void appendHeader(header\_info \*hi)
{
    // Add the header to the header list. 
    // The header is appended to the list, to preserve the bottom-up order.
    HeaderCount++;
    hi->next = NULL;
    if (!FirstHeader) {
        // list is empty
        FirstHeader = LastHeader = hi;
    } else {
        if (!LastHeader) {
            // list is not empty, but LastHeader is invalid - recompute it
            LastHeader = FirstHeader;
            while (LastHeader->next) LastHeader = LastHeader->next;
        }
        // LastHeader is now valid
        LastHeader->next = hi;
        LastHeader = hi;
    }
}


```
可以看到就是遍历 dyld\_image\_info 列表，将每个元素的imageLoadAddress属性转换为headerType，作为参数调用 addHeader 返回 header\_info ，返回值作为元素插入 FirstHeader 链表中。主要的构建发生在 addHeader 里面。而addHeader有两个分支，根据注释为了优化速度，一个获取的是共享的库，另外一个是真实构建的。而我们关心的class构建的展开如下：
```

hi = (header\_info \*)calloc(sizeof(header\_info), 1);
hi->mhdr = mhdr;
hi->mod\_count = 0;
hi->mod\_ptr = \_getObjcModules(hi, &hi->mod\_count);


#define GETSECT(name, type, sectname)                                   \\
    type \*name(const header\_info \*hi, size\_t \*outCount)  \\
    {                                                                   \\
        unsigned long byteCount = 0;                                    \\
        type \*data = (type \*)                                           \\
            getsectiondata(hi->mhdr, SEG\_OBJC, sectname, &byteCount);   \\
        \*outCount = byteCount / sizeof(type);                           \\
        return data;                                                    \\
    }
GETSECT(\_getObjcModules,      struct objc\_module, "\_\_module\_info");

```
也就是最终调用了 getsectiondata(mhdr, "\_\_OBJC", "\_\_module\_info", &(&hi->mod\_count)); 综合之前，我们能确定runtime调用了getsectiondata获得一个指针指向的内存块，指向这个内存块被转换为objc\_module，之后使用循环读取所有的 objc\_module->symtab->def指针指向的列表，每个指针指向的内容被转换为Class。 后续我们将继续追查 \_\_OBJC 段 \_\_module\_info 块的内容。