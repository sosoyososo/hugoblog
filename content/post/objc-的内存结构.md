---
title: 'Objc 的内存结构'
date: Thu, 18 Jan 2018 11:19:51 +0000
draft: false
tags: ['Objective-C']
---

Objc中我们使用最多的就是对象，那么首先从对象的分配开始看：
```

typedef struct objc_object *id;

struct objc_object {
private:
    isa_t isa;  
...  
}

union isa_t 
{
    isa_t() { }
    isa_t(uintptr_t value) : bits(value) { }

    Class cls;
    uintptr_t bits;
#   define ISA_MASK        0x00007ffffffffff8ULL
#   define ISA_MAGIC_MASK  0x001f800000000001ULL
#   define ISA_MAGIC_VALUE 0x001d800000000001ULL
    struct {
        uintptr_t nonpointer        : 1;
        uintptr_t has_assoc         : 1;
        uintptr_t has_cxx_dtor      : 1;
        uintptr_t shiftcls          : 44; // MACH_VM_MAX_ADDRESS 0x7fffffe00000
        uintptr_t magic             : 6;
        uintptr_t weakly_referenced : 1;
        uintptr_t deallocating      : 1;
        uintptr_t has_sidetable_rc  : 1;
        uintptr_t extra_rc          : 8;
#       define RC_ONE   (1ULL<<56)
#       define RC_HALF  (1ULL<<7)
    };

}; 

```
所以Objc的对象，在内存中就是一个只包含 isa\_t 的结构体，而 isa\_t 则是一个 union ，主要的信息包含了一个 Class 来存储类信息，存储了对象(类)的变量，属性，方法，协议等等一系列信息，我们继续看Class的结构。
```

typedef struct objc_class *Class;

struct objc_class : objc_object {
    // Class ISA;
    Class superclass;
    cache_t cache;             // formerly cache pointer and vtable
    class_data_bits_t bits;    // class_rw_t * plus custom rr/alloc flags

    class_rw_t *data() { 
        return bits.data();
    }
    ...
}


struct class_data_bits_t {

    // Values are the FAST_ flags above.
    uintptr_t bits;

    ...
}

struct class_rw_t {
    // Be warned that Symbolication knows the layout of this structure.
    uint32_t flags;
    uint32_t version;

    const class_ro_t *ro;

    method_array_t methods;
    property_array_t properties;
    protocol_array_t protocols;

    Class firstSubclass;
    Class nextSiblingClass;

    char *demangledName;

    ...
}

struct class_ro_t {
    uint32_t flags;
    uint32_t instanceStart;
    uint32_t instanceSize;
#ifdef __LP64__
    uint32_t reserved;
#endif

    const uint8_t * ivarLayout;

    const char * name;
    method_list_t * baseMethodList;
    protocol_list_t * baseProtocols;
    const ivar_list_t * ivars;

    const uint8_t * weakIvarLayout;
    property_list_t *baseProperties;

    method_list_t *baseMethods() const {
        return baseMethodList;
    }
}; 

```
Class的superclass和ISA主要维护了类的继承结构，和MetaClass，cache则是对运行速度的优化，主要信息的存储是class\_data\_bits\_t，其中只包含了一个指针，在用的时候被转化成class\_rw\_t。 class\_rw\_t 存储的结构化的 Class 信息，methods 存储方法列表，properties存储属性列表，protocols存储协议列表，demangledName则是内存中的名字。 另外还有一个class\_ro\_t来存储不太会改变的信息(其中的ro我理解成read only ^\_^，但其中的信息并不真的是一成不变的，他的不变相对于在构建过程中可能改变的东西，比如是否在初始化，是否已经加载等等)。 load 方法就存储在 class\_ro\_t 的 baseMethodList 中， ivars 和 weakIvarLayout 保存所有变量的名字类型位置等信息，ivarLayout 存储所有变量的值， 其他的就是协议列表，方法列表，属性列表。 class\_rw\_t 和 class\_ro\_t 中都有协议列表，方法列表，属性列表，他们有什么区别？class\_ro\_t 中的列表，是在类初始化的时候从加载类的image中获取到的，而class\_rw\_t的列表则是后续加载其他image和程序运行过程中加入的。