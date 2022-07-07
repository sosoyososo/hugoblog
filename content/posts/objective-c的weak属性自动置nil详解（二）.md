---
title: 'Objective-C的weak属性自动置nil详解（二）'
date: Fri, 21 Apr 2017 07:55:00 +0000
draft: false
tags: ['Objective-C']
---

在上一部分中我们理了一下weak属性是如何被设置为nil的，但单单只看这个部分我们可能还是有很多疑惑。我们接着为大家解惑，这个部分将会理清上个部分遍历属性列表将属性设置为nil的时候，这个列表的结构是如何构建的。 为了解答这个问题，我们需要先考虑一件事情，这个被遍历的结构，是从哪里做为入口开始构建的？这个问题或许不好回答，但如果只这个列表新增内容的过程却是很简单，而且从这里也能看到这个结构的创建。从这点考虑，我们可以从为一个weak属性设置新的内容的时候开始，而对于任何一个对象属性，它的属性值真正被设置的点最终会落到runtime中的`object_setInstanceVariable` 方法，我们的冒险也从这里开始：
```

// objc-class.mm
Ivar object_setInstanceVariable(id obj, const char *name, void *value)
{
    Ivar ivar = nil;

    if (obj  &&  name  &&  !obj->isTaggedPointer()) {
        if ((ivar = class_getInstanceVariable(obj->ISA(), name))) {
            object_setIvar(obj, ivar, (id)value);
        }
    }
    return ivar;
}

void object_setIvar(id obj, Ivar ivar, id value)
{
    if (obj  &&  ivar  &&  !obj->isTaggedPointer()) {
        Class cls = _ivar_getClass(obj->ISA(), ivar);
        ptrdiff_t ivar_offset = ivar_getOffset(ivar);
        id *location = (id *)((char *)obj + ivar_offset);
        // if this ivar is a member of an ARR compiled class, then issue the correct barrier according to the layout.
        if (_class_usesAutomaticRetainRelease(cls)) {
            // for ARR, layout strings are relative to the instance start.
            uint32_t instanceStart = _class_getInstanceStart(cls);
            const uint8_t *weak_layout = class_getWeakIvarLayout(cls);
            if (weak_layout && is_scanned_offset(ivar_offset - instanceStart, weak_layout)) {
                // use the weak system to write to this variable.
                objc_storeWeak(location, value);
                return;
            }
            const uint8_t *strong_layout = class_getIvarLayout(cls);
            if (strong_layout && is_scanned_offset(ivar_offset - instanceStart, strong_layout)) {
                objc_storeStrong(location, value);
                return;
            }
        }
#if SUPPORT_GC
        if (UseGC) {
            // for GC, check for weak references.
            const uint8_t *weak_layout = class_getWeakIvarLayout(cls);
            if (weak_layout && is_scanned_offset(ivar_offset, weak_layout)) {
                objc_assign_weak(value, location);
            }
        }
        objc_assign_ivar(value, obj, ivar_offset);
#else
        *location = value;
#endif
    }
}

// NSObject.mm
id
objc_storeWeak(id *location, id newObj)
{
    return storeWeak<true/*old*/, true/*new*/, true/*crash*/>
        (location, (objc_object *)newObj);
}

template <bool HaveOld, bool HaveNew, bool CrashIfDeallocating>
static id 
storeWeak(id *location, objc_object *newObj)
{
    assert(HaveOld  ||  HaveNew);
    if (!HaveNew) assert(newObj == nil);

    Class previouslyInitializedClass = nil;
    id oldObj;
    SideTable *oldTable;
    SideTable *newTable;

    // Acquire locks for old and new values.
    // Order by lock address to prevent lock ordering problems. 
    // Retry if the old value changes underneath us.
 retry:
    if (HaveOld) {
        oldObj = *location;
        oldTable = &SideTables()[oldObj];
    } else {
        oldTable = nil;
    }
    if (HaveNew) {
        newTable = &SideTables()[newObj];
    } else {
        newTable = nil;
    }

    SideTable::lockTwo<HaveOld, HaveNew>(oldTable, newTable);

    if (HaveOld  &&  *location != oldObj) {
        SideTable::unlockTwo<HaveOld, HaveNew>(oldTable, newTable);
        goto retry;
    }

    // Prevent a deadlock between the weak reference machinery
    // and the +initialize machinery by ensuring that no 
    // weakly-referenced object has an un-+initialized isa.
    if (HaveNew  &&  newObj) {
        Class cls = newObj->getIsa();
        if (cls != previouslyInitializedClass  &&  
            !((objc_class *)cls)->isInitialized()) 
        {
            SideTable::unlockTwo<HaveOld, HaveNew>(oldTable, newTable);
            _class_initialize(_class_getNonMetaClass(cls, (id)newObj));

            // If this class is finished with +initialize then we're good.
            // If this class is still running +initialize on this thread 
            // (i.e. +initialize called storeWeak on an instance of itself)
            // then we may proceed but it will appear initializing and 
            // not yet initialized to the check above.
            // Instead set previouslyInitializedClass to recognize it on retry.
            previouslyInitializedClass = cls;

            goto retry;
        }
    }

    // Clean up old value, if any.
    if (HaveOld) {
        weak_unregister_no_lock(&oldTable->weak_table, oldObj, location);
    }

    // Assign new value, if any.
    if (HaveNew) {
        newObj = (objc_object *)weak_register_no_lock(&newTable->weak_table, 
                                                      (id)newObj, location, 
                                                      CrashIfDeallocating);
        // weak_register_no_lock returns nil if weak store should be rejected

        // Set is-weakly-referenced bit in refcount table.
        if (newObj  &&  !newObj->isTaggedPointer()) {
            newObj->setWeaklyReferenced_nolock();
        }

        // Do not set *location anywhere else. That would introduce a race.
        *location = (id)newObj;
    }
    else {
        // No new value. The storage is not changed.
    }

    SideTable::unlockTwo<HaveOld, HaveNew>(oldTable, newTable);

    return (id)newObj;
}


id 
weak_register_no_lock(weak_table_t *weak_table, id referent_id, 
                      id *referrer_id, bool crashIfDeallocating)
{
    objc_object *referent = (objc_object *)referent_id;
    objc_object **referrer = (objc_object **)referrer_id;

    if (!referent  ||  referent->isTaggedPointer()) return referent_id;

    // ensure that the referenced object is viable
    bool deallocating;
    if (!referent->ISA()->hasCustomRR()) {
        deallocating = referent->rootIsDeallocating();
    }
    else {
        BOOL (*allowsWeakReference)(objc_object *, SEL) = 
            (BOOL(*)(objc_object *, SEL))
            object_getMethodImplementation((id)referent, 
                                           SEL_allowsWeakReference);
        if ((IMP)allowsWeakReference == _objc_msgForward) {
            return nil;
        }
        deallocating =
            ! (*allowsWeakReference)(referent, SEL_allowsWeakReference);
    }

    if (deallocating) {
        if (crashIfDeallocating) {
            _objc_fatal("Cannot form weak reference to instance (%p) of "
                        "class %s. It is possible that this object was "
                        "over-released, or is in the process of deallocation.",
                        (void*)referent, object_getClassName((id)referent));
        } else {
            return nil;
        }
    }

    // now remember it and where it is being stored
    weak_entry_t *entry;
    if ((entry = weak_entry_for_referent(weak_table, referent))) {
        append_referrer(entry, referrer);
    } 
    else {
        weak_entry_t new_entry;
        new_entry.referent = referent;
        new_entry.out_of_line = 0;
        new_entry.inline_referrers[0] = referrer;
        for (size_t i = 1; i < WEAK_INLINE_COUNT; i++) {
            new_entry.inline_referrers[i] = nil;
        }

        weak_grow_maybe(weak_table);
        weak_entry_insert(weak_table, &new_entry);
    }

    // Do not set *referrer. objc_storeWeak() requires that the 
    // value not change.

    return referent_id;
} 

```
最后的方法 `weak_register_no_lock` 就实现了为一个对象注册新的弱引用对象。但要整体理解为一个弱引用属性设置新值的整体逻辑，需要重点关注的是模版函数storeWeak。 这个函数做了几件与理清逻辑相关比较关键的事情： a. 先找到当前引用对象对应的弱引用表和新引用对象的弱引用列表：
```

if (HaveOld) {
    oldObj = *location;
    oldTable = &SideTables()[oldObj];
} else {
    oldTable = nil;
}
if (HaveNew) {
    newTable = &SideTables()[newObj];
} else {
    newTable = nil;
} 

```
b. 删除旧对象弱引用表中对应的记录：
```

if (HaveOld) {
    weak_unregister_no_lock(&oldTable->weak_table, oldObj, location);
} 

```
c. 为新的对象添加对应的记录，并更新引用对象：
```

if (HaveNew) {
    newObj = (objc_object *)weak_register_no_lock(&newTable->weak_table, 
                                                  (id)newObj, location, 
                                                  CrashIfDeallocating);
    // weak_register_no_lock returns nil if weak store should be rejected

    // Set is-weakly-referenced bit in refcount table.
    if (newObj  &&  !newObj->isTaggedPointer()) {
        newObj->setWeaklyReferenced_nolock();
    }

    // Do not set *location anywhere else. That would introduce a race.
    *location = (id)newObj;
} 

```
d. 当然以上所做需要在有锁状态下进行，避免线程问题。 这个部分完成之后，可能还是有些疑问，比如这个表的整体结构是怎样的，比如里面的细节部分。关于细节部分，这里不准备列出，objc-weak.h和objc-weak.mm里面有源码。关于整体的结构，我们在第三部分讲一下。