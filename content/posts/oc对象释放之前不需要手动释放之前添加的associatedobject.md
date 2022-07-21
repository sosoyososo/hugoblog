---
title: 'OC对象释放之前不需要手动释放之前添加的AssociatedObject'
date: Tue, 08 Jan 2019 07:12:23 +0000
draft: false
tags: ['iOS', 'Objective-C']
---

> 对象通过dealloc释放自己的时候，间接调用了objc\_destructInstance函数，这里会做相应的检查和释放动作：


```

void *objc_destructInstance(id obj)
{
if (obj) {
// Read all of the flags at once for performance.
bool cxx = obj->hasCxxDtor();
bool assoc = obj->hasAssociatedObjects();

// This order is important.
if (cxx) object_cxxDestruct(obj);
if (assoc) _object_remove_assocations(obj);
obj->clearDeallocating();
}

return obj;
} 

```
