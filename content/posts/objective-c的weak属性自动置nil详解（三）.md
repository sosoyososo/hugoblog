---
title: 'Objective-C的weak属性自动置nil详解（三）'
date: Fri, 21 Apr 2017 09:03:10 +0000
draft: false
tags: ['Objective-C']
---

在第二部分中，我们理了一下为一个weak属性设置新值的时候发生了什么，但我们还是不清楚在程序运行过程中，这个表的整体结构。这部分我们将就这个话题展开讨论。 从之前两部分的内容，也有部分的蛛丝马迹来猜测整体的结构，比如在模版方法`storeWeak` 获取新旧两个引用对象对应的表的时候是这样的：
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
由此我们可以向下深入：
```

// NSObject.mm
static StripedMap<SideTable>& SideTables() {
    return *reinterpret_cast<StripedMap<SideTable>*>(SideTableBuf);
}

alignas(StripedMap<SideTable>) static uint8_t 
    SideTableBuf[sizeof(StripedMap<SideTable>)];

// objc-private.h
// StripedMap<T> is a map of void* -> T, sized appropriately 
// for cache-friendly lock striping. 
// For example, this may be used as StripedMap<spinlock_t>
// or as StripedMap<SomeStruct> where SomeStruct stores a spin lock.
template<typename T>
class StripedMap {
    ...
} 

```
可以看到新旧对象的表是从一个map对象中使用(新旧两个)被引用对象的指针做为key取到的。从`weak_register_no_lock`函数的定义，我们可以看到这个表的类型是 `weak_table_t`。然后就这个函数继续向下看，真正的操作分为两部分，当前引用的属性已经引用过和没有引用过这个表所对应的对象：
```

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

```
这个属性已经引用过的时候，就在这个属性所在的记录（weak\_entry\_t)新增了这个属性的保存。而如果没有引用过，就会新建一个引用的记录，并且查看是否需要对表（weak\_table\_t）进行扩展。 下图描述了整体的结构 [![objc_weak_ref](http://www.karsa.info/blog/wp-content/uploads/2017/04/objc_weak_ref-300x222.jpg)](http://www.karsa.info/blog/wp-content/uploads/2017/04/objc_weak_ref.jpg) **_注意：_** 之前的描述**_这个属性已经引用过的时候_**并不是确切的指这个属性的已经引用过，而是说哈希有碰撞到对应的记录，而这个记录中可能保存有多个属性，并不一定包含当前操作的属性，当然也不一定不包含。这个优化体现在如果不考虑速度，其实最后一张表是不必要的，有了最后一张表，访问速度会快很多。因为对弱引用的查询不再是O(N)，最好情况下O(1)就能解决问题。