---
title: 'React Native 布局原理概述'
date: Wed, 30 May 2018 09:33:21 +0000
draft: false
tags: ['iOS', 'React Native']
---

用了RN有一段时间了，稍微做一些总结，整体的东西尚不明确，就从一些细节的点开始介绍，并做略微的深入，以明确原理为目的，不求甚解。

React Native 做了什么？
------------------

简单来说，React Native(后面使用RN来简化称呼)给了移动开发者机会使用React来开发移动端App。React是一个最近流行的JS视觉库，特点是使用了JSX这种混合了JS、CSS和Html的开发方式。

React Native 怎么做到的？
-------------------

RN的基本运行原理是构建本地的组件和JS组件之间的映射，组件方法的映射以及一些常量的映射，以及JS和本地的互相调用。 在iOS中，JS的执行是通过iOS的JSContext来执行的。 CSS解释执行后，通过设置facebook的yoga库来在本地实现布局计算，yoga的的基本元素是node，对应了一个本地的RCTShadowView，间接对应了实际用来显示内容的UIView，yoga的node，RCTShadowView和iOS的View组件是一对一对一的关系。 RN提供了一套宏定义来构建本地组件，将组件，组件的方法暴露给JS，RN也提供了一些调用JS方法的方法，让用户可以很方便的创建用户自定义组件。 在运行的时候，RN将JS打包压缩后变成一整个JS文件，在主工程里面引用，并在打包的时候打包到APP里面。运行的时候，通过这个文件路径创建一个Bridge，用来加载这个JS文件。然后使用Bridge创建一个RCTRootView，用来显示JS创建的内容。

创建View
------

RCTUIManager 暴露了一系列创建View和在ParentView中加入删去ChildView的方法。在createView中创建了RCTShadowView和对应的View，ShadowView初始化的时候创建了对应的yoga node：
```

 RCTShadowView *shadowView = [componentData createShadowViewWithTag:reactTag];

  UIView *view = [componentData createViewWithTag:reactTag]; 

```
RCTShadowView重新定义了UI布局的一些基本元素，在更新的时候会发现更新的是yogaNode的内容，最终体现到对应的View上。

创建和更新布局
-------

布局相关的操作有创建和更新，分别在 createView 和 updateView 中，都是通过 setProps:forShadowView:来实现。这个方法便利props的每个元素，获取到对应的block，传入shadowView和json作为参数。获取block是通过createPropBlock:isShadowView: 来创建的，可以看到是通过拼接字符串来获取到对应的方法进行调用，对shadowView布局的更新返回的是调用类似setRight:方法的block。