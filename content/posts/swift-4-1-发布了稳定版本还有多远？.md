---
title: 'swift 4.1 发布了,稳定版本还有多远？'
date: Mon, 16 Apr 2018 07:55:46 +0000
draft: false
tags: ['swift']
---

3.29号4.1发布了，相对之前算是比较小的改动了，为数不多的几个改动都是关于语法和API的，一切都向着好的方向在发展。

1.  Conditional conformances: 有条件的遵守，就是只在某些条件下遵守协议。
2.  Support recursive constraints on associated types: associated types 是在protocol中用来占位，这个改进支持对递归associated types进行限制。
3.  Synthesizing Equatable and Hashable conformance: 复杂结构所有成员都是Equatable的时候，复杂协议自动Equatable，Hashable也是。
4.  Introduce Sequence.compactMap(\_:):添加新方法
5.  Make Standard Library Index Types Hashable : Index 遵循 Hashable(应该是为了尽可能满足3)
6.  Eliminate IndexDistance from Collection: 删除了IndexDistance这种反人类操作，使用Int。

4.1 版本发之前一个月，公布了4.2的一些消息，可以看到4.2应该会是一个很大的改动，但大部分是在底层，并且还承诺版本5会是一个ABI稳定版本。总算是有个盼头了。 附上[ABI稳定的进度](https://swift.org/abi-stability/#data-layout)，看看就有点小激动呢～