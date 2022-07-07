---
title: 'Objc load方法怎么被调用？(四)'
date: Fri, 13 Oct 2017 18:12:59 +0000
draft: false
tags: ['iOS', 'Objective-C']
---

[前一节](http://www.karsa.info/blog/?p=399)讲到我们class的内容是从使用 \_\_OBJC 作为段名 \_\_module\_info 作为块名来调用 getsectiondata 函数获取到的数据块中获取到的。但当我们真正使用 otool 来验证的时候，会发现根本找不到相关的segment(段)和section(块)，这又是为啥？ 再回到我们追查runtime代码的过城中，查看每个函数不难发现其实我们追查的一些关键代码是属于旧时代的文件，文件名中就包含有 old 字样，现在我们使用新的代码再追查一下objc2时代新代码下的实现吧：
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

/\*\*\*\*\*\*\*\*\*\*\*\* map\_2\_images \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*/

const char \*
map\_2\_images(enum dyld\_image\_states state, uint32\_t infoCount,
             const struct dyld\_image\_info infoList\[\])
{
    rwlock\_writer\_t lock(runtimeLock);
    return map\_images\_nolock(state, infoCount, infoList);
}


const char \*
map\_images\_nolock(enum dyld\_image\_states state, uint32\_t infoCount,
                  const struct dyld\_image\_info infoList\[\])
{
...
\_read\_images(hList, hCount);
...
}

void \_read\_images(header\_info \*\*hList, uint32\_t hCount) {
...
realizeAllClasses();
...
}

static void realizeAllClasses(void)
{
    runtimeLock.assertWriting();

    header\_info \*hi;
    for (hi = FirstHeader; hi; hi = hi->next) {
        realizeAllClassesInImage(hi);
    }
}

static void realizeAllClassesInImage(header\_info \*hi)
{
    runtimeLock.assertWriting();

    size\_t count, i;
    classref\_t \*classlist;

    if (hi->allClassesRealized) return;

    classlist = \_getObjc2ClassList(hi, &count);

    for (i = 0; i < count; i++) {
        realizeClass(remapClass(classlist\[i\]));
    }

    hi->allClassesRealized = YES;
}

/\*\*\*\*\*\*\*\*\*\*\*\* load\_images \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*/
const char \*
load\_images(enum dyld\_image\_states state, uint32\_t infoCount,
            const struct dyld\_image\_info infoList\[\])
{
    bool found;

    // Return without taking locks if there are no +load methods here.
    found = false;
    for (uint32\_t i = 0; i < infoCount; i++) {
        if (hasLoadMethods((const headerType \*)infoList\[i\].imageLoadAddress)) {
            found = true;
            break;
        }
    }
    if (!found) return nil;

    recursive\_mutex\_locker\_t lock(loadMethodLock);

    // Discover load methods
    {
        rwlock\_writer\_t lock2(runtimeLock);
        found = load\_images\_nolock(state, infoCount, infoList);
    }

    // Call +load methods (without runtimeLock - re-entrant)
    if (found) {
        call\_load\_methods();
    }

    return nil;
}

bool 
load\_images\_nolock(enum dyld\_image\_states state,uint32\_t infoCount,
                   const struct dyld\_image\_info infoList\[\])
{
    bool found = NO;
    uint32\_t i;

    i = infoCount;
    while (i--) {
        const headerType \*mhdr = (headerType\*)infoList\[i\].imageLoadAddress;
        if (!hasLoadMethods(mhdr)) continue;

        prepare\_load\_methods(mhdr);
        found = YES;
    }

    return found;
}

void prepare\_load\_methods(const headerType \*mhdr)
{
    size\_t count, i;

    runtimeLock.assertWriting();

    classref\_t \*classlist = 
        \_getObjc2NonlazyClassList(mhdr, &count);
    for (i = 0; i < count; i++) {
        schedule\_class\_load(remapClass(classlist\[i\]));
    }

    category\_t \*\*categorylist = \_getObjc2NonlazyCategoryList(mhdr, &count);
    for (i = 0; i < count; i++) {
        category\_t \*cat = categorylist\[i\];
        Class cls = remapClass(cat->cls);
        if (!cls) continue;  // category for ignored weak-linked class
        realizeClass(cls);
        assert(cls->ISA()->isRealized());
        add\_category\_to\_loadable\_list(cat);
    }
}

```
对比之前，分别使用了 \_getObjc2NonlazyCategoryList 和 \_getObjc2ClassList 获取到两个classref\_t指针列表，也就只类列表，然后跟之前一样的方式将类和获取到的load方法加入到列表中，后续去调用。这两个函数定义如下:
```

GETSECT(\_getObjc2ClassList,           classref\_t,      "\_\_objc\_classlist");
GETSECT(\_getObjc2NonlazyClassList,    classref\_t,      "\_\_objc\_nlclslist");


#define GETSECT(name, type, sectname)                                   \\
    type \*name(const headerType \*mhdr, size\_t \*outCount) {              \\
        return getDataSection<type>(mhdr, sectname, nil, outCount);     \\
    }                                                                   \\
    type \*name(const header\_info \*hi, size\_t \*outCount) {               \\
        return getDataSection<type>(hi->mhdr, sectname, nil, outCount); \\
    }


template <typename T>
T\* getDataSection(const headerType \*mhdr, const char \*sectname, 
                  size\_t \*outBytes, size\_t \*outCount)
{
    unsigned long byteCount = 0;
    T\* data = (T\*)getsectiondata(mhdr, "\_\_DATA", sectname, &byteCount);
    if (!data) {
        data = (T\*)getsectiondata(mhdr, "\_\_DATA\_CONST", sectname, &byteCount);
    }
    if (!data) {
        data = (T\*)getsectiondata(mhdr, "\_\_DATA\_DIRTY", sectname, &byteCount);
    }
    if (outBytes) \*outBytes = byteCount;
    if (outCount) \*outCount = byteCount / sizeof(T);
    return data;
}

```
也就是分别使用了 \_\_objc\_classlist 和 \_\_objc\_nlclslist 作为section参数调用了getsectiondata函数。然后转换成类列表数据。这个逻辑跟之前的讲述是一致的，只是数据格式发生了变化。 需要额外注意的是，这里获取到的class直接被转换成了Class之后，又使用 remapClass 函数做了一层转换，这个后续讲述内容对比的时候再说。 下节我们继续追查 \_\_objc\_classlist 和 \_\_objc\_nlclslist 块的内容。