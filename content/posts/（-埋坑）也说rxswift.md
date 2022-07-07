---
title: '（# 填坑）也说RxSwift － 一个简单案例的运行原理'
date: Fri, 04 Nov 2016 10:36:04 +0000
draft: false
tags: ['iOS', 'swift']
---

我们从RxSwift中一个常见的案例Delegate深入下去，给我们带来的好处以及坏处,我们使用一个简单的场景，监控 UISearchBar 内容的变化，这是典型的 Delegate 使用。

### 怎么使用

原来的使用方式:
```

UISearchBar *searchBar = /* initSearch */;
searchBar.delegate = /* get ObjectA object */; 
/* add searchBar to UI */

//ObjectA impletement start
...
func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
    /* handler text change  */
}
...
//ObjectA impletement end 

```
现在的使用方式:
```

UISearchBar *searchBar = /* initSearch */;
/* add searchBar to UI */

_=searchBar.rx_text.subscribeNext({ (text) in
    /* handler text change  */
}) 

```


### 怎么运行

> 不管现在的使用方式是什么，我们确信的是，不能缺少对delegate的绑定，不能缺少回调的动作和对回调的实现。

1.  对 UISearchBar 进行扩展，提供了rx\_text ， rx\_delegate
2.  rx\_delegate 是创建了一个 RxSearchBarDelegateProxy 对象，这个对象被设置成 UISearchBar 的 delegate(在DelegateProxyType的proxyForObject方法中) ，也就是说它需要实现相关的回调方法，但并没有发现对应的代码，我们继续向下看。
3.  observe方法中我们看到创建了与传入selector对应的PublishSubject，并保存起来，然后就结束了。奇怪的是还是没有找到回调实现的地方。
4.  但在RxSearchBarDelegateProxy最顶层父类\_RXDelegateProxy中我们看到了跟转移方法调用相关的一系列方法(canRespondToSelector:,respondsToSelector:,forwardInvocation:),这里看到方法的调用被转向 interceptedSelector:withArguments: 和 self.\_forwardToDelegate 这两个地方，而后一个方向是之前设置的delegate，所以这里保证了之前监听的回调还是有效。
5.  第一个转向的实现，在 DelegateProxy 的实现中，我们看到他的默认实现就是subjectsForSelector\[selector\]?.on(.Next(arguments))。也就是发送了一个Next事件，以arguments作为参数(这个保证了作为 subscribeNext 参数的闭包能够处理这个参数，具体的后面再说)。于是整个流程终于完整。

### 整理结构

1.  rx\_delegate 创建 RxSearchBarDelegateProxy
2.  observe 创建 \[Selector: PublishSubject\]，设置 RxSearchBarDelegateProxy 的实例对象作为 UISearchBar 的 Delegate
3.  RxSearchBarDelegateProxy 没有实现回调，利用 \_RXDelegateProxy 的消息转发机制，在 interceptedSelector:withArguments: 中，以回调方法参数构建一个 Next事件，调用 PublishSubject 的 on 方法，发送这个事件。