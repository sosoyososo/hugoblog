---
title: 'Objective-C的weak属性自动置nil详解（一）'
date: Fri, 21 Apr 2017 06:59:30 +0000
draft: false
tags: ['Objective-C']
---

[《招聘一个靠谱的iOS》面试题参考答案（上）第8题](https://github.com/ChenYilong/iOSInterviewQuestions/blob/master/01%E3%80%8A%E6%8B%9B%E8%81%98%E4%B8%80%E4%B8%AA%E9%9D%A0%E8%B0%B1%E7%9A%84iOS%E3%80%8B%E9%9D%A2%E8%AF%95%E9%A2%98%E5%8F%82%E8%80%83%E7%AD%94%E6%A1%88/%E3%80%8A%E6%8B%9B%E8%81%98%E4%B8%80%E4%B8%AA%E9%9D%A0%E8%B0%B1%E7%9A%84iOS%E3%80%8B%E9%9D%A2%E8%AF%95%E9%A2%98%E5%8F%82%E8%80%83%E7%AD%94%E6%A1%88%EF%BC%88%E4%B8%8A%EF%BC%89.md#8-runtime-%E5%A6%82%E4%BD%95%E5%AE%9E%E7%8E%B0-weak-%E5%B1%9E%E6%80%A7)**runtime 如何实现 weak 属性** 里面说到：

> runtime 对注册的类， 会进行布局，对于 weak 对象会放入一个 hash 表中。 用 weak 指向的对象内存地址作为 key，当此对象的引用计数为0的时候会 dealloc，假如 weak 指向的对象内存地址是a，那么就会以a为键， 在这个 weak 表中搜索，找到所有以a为键的 weak 对象，从而设置为 nil。

然后还引用了表示 weak 对象的结构体，以及存储weak对象引用列表的 weak\_table\_t，然后设计了伪代码，进行说明。 但是作为智商有严重缺陷的人，我死活还是不懂啊，本来有的一些想法倒是给说的更迷糊了。不过没关系，runtime部分的代码本来就是开源的，我就按照使用过程引用并简单解释一下相关的实现（这里只会列出整个过程的关键点，细节部分代码太多，可以自己去看源码)。如果你跟我一样笨，那就继续向下看。 本篇是第一部分，作为引入点，我们从weak属性如何自动被设置成nil开始，要实现这一点，很容易想到可以在被使用weak引用的对象的dealloc中实现，我们从这个点来拉出到最终清除weak属性到nil的过程：
```

// NSObject.mm 
- (void)dealloc {
    _objc_rootDealloc(self);
}

void
_objc_rootDealloc(id obj)
{
    assert(obj);

    obj->rootDealloc();
}

// objc-object.h
inline void
objc_object::rootDealloc()
{
    if (isTaggedPointer()) return;
    object_dispose((id)this);
}


// objc-class-old.mm //其实还有一个新版的实现，有兴趣的可以去看看
id object_dispose(id obj) 
{
    if (UseGC) return _object_dispose(obj);
    else return (*_dealloc)(obj); 
}

static id 
_object_dispose(id anObject) 
{
    if (anObject==nil) return nil;

    objc_destructInstance(anObject);

#if SUPPORT_GC
    if (UseGC) {
        auto_zone_retain(gc_zone, anObject); // gc free expects rc==1
    } else 
#endif
    {
        // only clobber isa for non-gc
        anObject->initIsa(_objc_getFreedObjectClass ()); 
    }
    free(anObject);
    return nil;
}

void *objc_destructInstance(id obj) 
{
    if (obj) {
        Class isa = obj->getIsa();

        if (isa->hasCxxDtor()) {
            object_cxxDestruct(obj);
        }

        if (isa->instancesHaveAssociatedObjects()) {
            _object_remove_assocations(obj);
        }

        if (!UseGC) objc_clear_deallocating(obj);
    }

    return obj;
}

// NSObject.mm 
void 
objc_clear_deallocating(id obj) 
{
    assert(obj);
    assert(!UseGC);

    if (obj->isTaggedPointer()) return;
    obj->clearDeallocating();
}

// objc-object.h
inline void 
objc_object::clearDeallocating()
{
    sidetable_clearDeallocating();
}


// NSObject.mm 
void 
objc_object::sidetable_clearDeallocating()
{
    SideTable& table = SideTables()[this];

    // clear any weak table items
    // clear extra retain count and deallocating bit
    // (fixme warn or abort if extra retain count == 0 ?)
    table.lock();
    RefcountMap::iterator it = table.refcnts.find(this);
    if (it != table.refcnts.end()) {
        if (it->second & SIDE_TABLE_WEAKLY_REFERENCED) {
            weak_clear_no_lock(&table.weak_table, (id)this);
        }
        table.refcnts.erase(it);
    }
    table.unlock();
}

// objc-weak.mm
void 
weak_clear_no_lock(weak_table_t *weak_table, id referent_id) 
{
    objc_object *referent = (objc_object *)referent_id;

    weak_entry_t *entry = weak_entry_for_referent(weak_table, referent);
    if (entry == nil) {
        /// XXX shouldn't happen, but does with mismatched CF/objc
        //printf("XXX no entry for clear deallocating %p\n", referent);
        return;
    }

    // zero out references
    weak_referrer_t *referrers;
    size_t count;

    if (entry->out_of_line) {
        referrers = entry->referrers;
        count = TABLE_SIZE(entry);
    } 
    else {
        referrers = entry->inline_referrers;
        count = WEAK_INLINE_COUNT;
    }

    for (size_t i = 0; i < count; ++i) {
        objc_object **referrer = referrers[i];
        if (referrer) {
            if (*referrer == referent) {
                *referrer = nil;
            }
            else if (*referrer) {
                _objc_inform("__weak variable at %p holds %p instead of %p. "
                             "This is probably incorrect use of "
                             "objc_storeWeak() and objc_loadWeak(). "
                             "Break on objc_weak_error to debug.\n", 
                             referrer, (void*)*referrer, (void*)referent);
                objc_weak_error();
            }
        }
    }

    weak_entry_remove(weak_table, entry);
} 

```
最后一段代码就是循环遍历引用这个对象的所有weak指针，把这些指针指向的内容设置为nil。 在这个部分中我们理了一下weak属性是如何被设置为nil的，但单单只看这个部分我们可能还是有很多疑惑。对于我最大的就是这个for循环到底做了啥？遍历的这个结构是如何建立的？下个部分我们将就这个话题继续理出实现逻辑。