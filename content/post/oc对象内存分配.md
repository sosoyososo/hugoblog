---
title: 'OC对象内存分配'
date: Sat, 30 May 2020 09:18:02 +0000
draft: false
tags: ['iOS', 'Objective-C']
---

oc对象在分配内存时候，在指向class的指针之外，会有多余的空间，就是实例属性所占用的空间。每个实例属性都是ivar\_t,保存了名字，空间位移和空间尺寸等信息； 在使用的时候注意，OC对象是可以继承的，父类的属性也会被继承过来，所以每个ivar\_t的大小虽然编译时决定，但位移是运行时决定的(不同平台下，数据类型尺寸不同)

```

objc_object {
    -> objc_class {
        -> objc_class
        cache_t {
            -> bucket_t {
            }
            mask_t          
            mask_t
        }
        -> class_rw_t {
            uint32_t            
            uint32_t
            ->class_ro_t {
                uint32_t flags;
                uint32_t instanceStart;
                uint32_t instanceSize;
                -> uint8_t
                -> const char
                -> method_list_t
                -> protocol_list_t
                -> ivar_list_t
                -> uint8_t
                -> property_list_t
            }           
            method_array_t
            property_array_t
            protocol_array_t
            -> objc_class
            -> objc_class       
            -> char 

        }
    }
}

struct ivar_t {
    int32_t *offset;
    const char *name;
    const char *type;
    uint32_t alignment_raw;
    uint32_t size;
}; 

```

