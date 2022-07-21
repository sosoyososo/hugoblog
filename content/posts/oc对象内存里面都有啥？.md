---
title: 'OC对象内存里面都有啥？'
date: Thu, 25 May 2017 15:05:58 +0000
draft: false
tags: ['Objective-C']
---

今天被问道OC对象在内存中都保存啥东西的问题，瞬间傻逼了，之前确实没看过，只好按照自己知道的东西先说了一遍，但没底是肯定的。刚才大致翻了一下源码，大致记录一下 OC对象会被编译器最终生成的一个objc\_object，知道runtime的应该都知道。那么接下来直接先上源码：
```

struct objc_object {
private:
    isa_t isa;
public:

    // ISA() assumes this is NOT a tagged pointer object
    Class ISA();

    // getIsa() allows this to be a tagged pointer object
    Class getIsa();
/*
剩下的还有其他一些方法就不完全贴出来了
*/
} 

```
我们可以看到，objc\_object对象只有一个isa\_t类型的值，然后剩下的全都是方法，让我们继续:
```

union isa_t 
{
    isa_t() { }
    isa_t(uintptr_t value) : bits(value) { }

    Class cls;
    uintptr_t bits;
...
} 

```
这里比校有用的是 Class ，这点从 objc\_object 的方法实现可以看出来。
```

typedef struct objc_class *Class;

struct objc_class : objc_object {
    Class superclass;
    const char *name;
    uint32_t version;
    uint32_t info;
    uint32_t instance_size;
    struct old_ivar_list *ivars;
    struct old_method_list **methodLists;
    Cache cache;
    struct old_protocol_list *protocols;
    // CLS_EXT only
    const uint8_t *ivar_layout;
    struct old_class_ext *ext;

/*
这里也有一些方法列表没有列出来
*/
} 

```
看到这里应该对OC对象的内存分布有所了解了。 objc\_object -> \[isa\_t\] isa\_t -> objc\_class objc\_class -> \[objc\_object　 //存储本身的类型 superclass //父类 name //名字 version //版本 info //状态信息 instance\_size //实例需要分配的内存大小 ivars //变量列表 methodLists //方法列表 cache //缓存 protocols //遵守的协议列表 ivar\_layout //变量的排列 ext\] //额外内容 所以可以看到大部分的东西都是在objc\_class中存储，而objc\_class本身又是objc\_object　类型