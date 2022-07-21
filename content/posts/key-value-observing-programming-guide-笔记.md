---
title: 'Key-Value Observing Programming Guide 笔记'
date: Tue, 21 Apr 2015 08:11:07 +0000
draft: false
tags: ['Read Note', 'Read Note']
---

KVC(Key-Value Coding)通过定义NSKeyValueCoding protocol来规定了一系列的规范，提供了一套通过key而不是通过调用方法来访问对象属性的方法。KVC时Cocoa中很多其他技术(KVC/Cocoa bindings/Core Data/AppleScript support等)的底层支持。 KVO(Key-Value Observing)的实现使用了KVC特性提供了一个机制，允许一个key指定的对象的property的内容改变时通知一个指定对象。

**KVO的使用过程:**

1.找到你要监听的对象属性 2.调用addObserver:forKeyPath:options:context: 方法添加监听 3.在observer参数指定的对象中实现observeValueForKeyPath:ofObject:change:context:方法。当keyPath指定的参数有相应修改的时候这个方法被自动调用，并传递对应参数。 4.在observeValueForKeyPath:ofObject:change:context:实现中根据keyPath和object参数指定的property进行不同的实现。 _**注意**_:在observer指定的对象内存释放之前必须使用removeObserver:来取消监听。observer必须实现observeValueForKeyPath:ofObject:change:context:方法。

**KVO的说明:**

不同于notifications使用NSNotificationCenter作为发送通知的中心，被KVO监听的对象属性发生变化时，通知直接被发送到observer对象，NSObject提供这个KVO的底层实现。 在使用KVO之前你需要确认监听对象是否支持使用KVO。

**KVO支持:**

1.自动支持:NSObject默认对所有的property提供KVC支持，如果监听NSObject子类的property不需要额外的代码来对KVO进行支持。 2.手动支持:实现类方法automaticallyNotifiesObserversForKey:来控制自动通知。

**KVO可用性判断:**

1.class的对应property必须是被KVC实现的 2.class实现有在property改变的时候发出通知 3.对应的keypath被正确注册

**监听类型:**

1.To-one:(firstName和scondName组成fullName，前两者的变化引起后者变化) a.使用keyPathsForValuesAffectingValueForKey:方法返回影响某个property的所有key组成的NSSet对象来实现在多个property中任何一个更新的时候通知监控某个key变动的observer。 b.使用keyPathsForValuesAffecting<Key>(key是对应property的key，首字母大写)， 注意:a方法因为有默认实现，所以不能在category里面进行实现，这时候可以使用b方案，进行实现。 2.To-many:(一个机构发的所有工资包含机构里面所有雇员工资总和) a.使用KVO监控所有员工对象的工资属性，使用机构作为observer b.using core data

**KVO实现细节:**

KVO使用isa-swizzling技术实现，isa默认指向对象的类，当对象的某个属性被注册监听的时候，isa指向了一个中间类而不是原来的类。 所以永远不能使用isa来判断对象的类型而是应该使用class方法。