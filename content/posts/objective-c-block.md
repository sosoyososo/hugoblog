---
title: 'Objective-C Block'
date: Thu, 24 Mar 2016 08:50:13 +0000
draft: false
tags: ['iOS', 'Objective-C']
---

概述
==

> apple从OS X v10.6 iOS 4.0 之后引入了block，它是如此方便，以至于一旦习惯你就再也离不开，直到你意识到你已经把它在你的工程里滥用了。apple的介绍中只是说引入block的sdk版本，是c层面的语法，可以在c/c++/objective-c(++)中使用，但这货到底是什么原理是啥也没说。甚至你在xcode里面进行调试的时候，在很多时候，打印出来的东西也只有名字，无法提供给你任何内部实现相关的内容。我试图在这篇短文里简单解释一下apple文档中简略带过的内容的含义。  

LLVM简介
------

嗯，首先需要致敬所有apple开发者心中的神Chris Lattner，llvm就是他的博士论文作品，上帝啊，这货是78年的啊，已经有了llvm和swift这样的封神之作。 回到针对本文的主题，llvm帮助我们将block转换成能直接在设备运行的机器码，并且提供中间过程的交互操作。但仅仅知道这个对我们理解Block没有什么帮助，所以我们要以一个更细的维度来看llvm。 在[LLVM](http://www.aosabook.org/en/llvm.html)一文中,CL有讲LLVM的核心就是LLVM IR，llvm的代码表达树。LLVM是典型的三段式结构的编译器，前端将语言代码翻译成llvm-ir,优化器针对ir进行代码优化，后端针对不同平台，将ir转换成平台相关的机器码。所以对所有的语言，llvm都要先把代码转换成IR，至此我们对LLVM的了解又进了一步。 所以要了解block的详情，我们还是要看针对Objective-C语言的前端，也就是Clang。

Clang
-----

正如用名字所说，Clang是llvm的C语言家族的编译器前端。在[Clang - Features and Goals](http://clang.llvm.org/features.html#unifiedparser)有说道，C/C++/ObjC的parser是统一实现的，所以我们的目标进一步缩小为这个C家族的clang实现。为了这个统一，在Clang的特性里面有提到，Clang对各种语言的各个版本提供可支持，也包含语言的各个变种。 在[Language Compatibility](http://clang.llvm.org/compatibility.html#blocks-in-protected-scope)我们可以看到，block相关的兼容是从C开始的，因为ObjC是C的超集，所以连带的ObjC也支持了block。这也是**为什么apple说block是C层面的语法**。 在[Clang Language Extensions](http://clang.llvm.org/docs/LanguageExtensions.html)也可以找到Block相关的内容，于是我们知道Block是Clang对C语言的扩展支持，而非标准C的支持。甚至在gcc里面我们也找不到相关的内容。

Objective-C
-----------

说到ObjC我们就不得不提它的runtime，为了在ObjC中无缝使用block，Clang中ObjC的runtim同样需要支持block。实际上在ObjC中，所有的block都被封装成ObjC的对象，ObjC对block的这种扩展使得block可以被当作id使用，详细的内容可以在[Objective-C Extensions](http://clang.llvm.org/docs/BlockLanguageSpec.html#id6)看到。

C层面内部实现
-------

在[Block Implementation Specification](http://clang.llvm.org/docs/Block-ABI-Apple.html)则是Clang实现Block的描述详情，block最终是以struct来实现的。针对不同情况，这个struct结构时不同的，但基本实现部分的结构不会变化。由此可以看到，block和ObjC在本质上有所区别，它不能在运行时被改变，而是在编译的时候就已经确定了的。

支持范围
----

至此我们可以看到block是clang为C语言提供的扩展支持，ObjC的runtime为它提供了ObjC面向对象的支持。所以基础的支持需要Clang对代码进行编译，ObjC如果要正常使用就需要支持Block的ObjC runtime了。

相关文档
----

[Blocks Programming Topics](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/Blocks/Articles/00_Introduction.html#//apple_ref/doc/uid/TP40007502-CH1-SW1) [Programming with Objective-C & Working with Blocks](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/WorkingwithBlocks/WorkingwithBlocks.html) [Language Compatibility](http://clang.llvm.org/compatibility.html#blocks-in-protected-scope) [谈Objective-C block的实现 by 唐巧](http://blog.devtang.com/2013/07/28/a-look-inside-blocks/) [Clang Block Implemention Specification](http://clang.llvm.org/docs/Block-ABI-Apple.html#imported-const-copy-variables) [Block runtime source code](https://llvm.org/svn/llvm-project/compiler-rt/trunk/lib/BlocksRuntime/) [Clang - Features and Goals](http://clang.llvm.org/features.html#unifiedparser) [LLVM architecture](http://www.aosabook.org/en/llvm.html)