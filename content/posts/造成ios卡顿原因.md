---
title: '造成iOS卡顿原因'
date: Thu, 01 Mar 2018 06:36:32 +0000
draft: false
tags: ['iOS', 'Objective-C']
---

iOS内容绘制是CPU和GPU协作的结果，卡顿原因也分为两种，CPU造成的卡顿，GPU造成的卡顿。

### CPU造成的卡顿

CPU造成卡顿本质是因为主线繁忙无法处理屏幕绘制信号导致，造成[主线程卡顿的原因有几种](https://blog.ibireme.com/2015/11/12/smooth_user_interfaces_for_ios/):

1.  对象创建(创建，内存分配以及后续的属性调整，以及文件读取)
    1.  轻量对象代替重对象(CALayer代替只用来绘制的UIView)
    2.  后台创建不涉及UI操作的对象(包含CALayer的控件都只能在主线程创建和操作)
    3.  Storyboard创建的视图对象比代码创建消耗多得多的资源
    4.  尽量推迟对象创建时间，尽量把对象创建分配到多个任务中(性价比不高)
    5.  尽量复用对象
2.  对象调整(常见消耗资源的地方)
    1.  CALayer的属性变化是对内部的一个Dictionary的操作，会通知delegate，创建动画，比较消耗资源
    2.  UIView显示相关的属性是从CALayer的属性映射过来的，属性的变化比CALayer更消耗资源，所以应该避免调整视图层次，添加和移除视图
3.  对象销毁
    1.  尽量把对象销毁放到后台程线程
4.  布局计算(最常见消耗CPU的地方)
    1.  后台线程提前计算布局
    2.  缓存视图布局
    3.  一次计算好，需要的时候一次调整好，不要分多次
5.  Autolayout复杂的时候会有严重的CPU性能问题
    1.  使用ComponentKit、AsyncDisplayKit替换Autolayout
6.  文本的宽高计算
    1.  使用系统方法在后台进行计算
    2.  CoreText 绘制文本，那就可以先生成 CoreText 排版对象，然后自己计算
    3.  保留CoreText 对象以供稍后绘制使用
7.  文本渲染(iOS文本显示是通过CoreText 排版、绘制为 Bitmap 显示的)
    1.  iOS文本控件排版和绘制都是在主线程进行，大量文本会比较消耗主线程，解决方案只有一个，那就是自定义文本控件，用 TextKit 或最底层的 CoreText 对文本异步绘制。
8.  图片的解码
    
    > 当你用 UIImage 或 CGImageSource 的那几个方法创建图片时，图片数据并不会立刻解码。图片设置到 UIImageView 或者 CALayer.contents 中去，并且 CALayer 被提交到 GPU 前，CGImage 中的数据才会得到解码。这一步是发生在主线程的，并且不可避免。
    
    1.  见的做法是在后台线程先把图片绘制到 CGBitmapContext 中，然后从 Bitmap 直接创建图片
9.  图形图像的绘制
    1.  CoreGraphic 方法通常都是线程安全的，所以图像的绘制可以很容易的放到后台线程进行。

### GPU造成的卡顿

GPU工作简单，接收提交的纹理，顶点描述，应用变换，混合，渲染，然后输出到屏幕上。造成GPU卡顿的主要有:

1.  快速提交纹理(图片) -> 尽量合并图片
2.  提交超大纹理，造成CPU预处理 -> 分割大图
3.  视图层次太多造成混合量大 -> 减少视图数量和层次，适当设置opaque尽量避免Alpha通道合成 -> 提前在CPU混合
4.  CALayer的透明阴影圆角属性导致的离屏渲染 -> 设置CALayer的shouldRasterize属性，将渲染转到CPU

#### [GPU离屏渲染为什么慢](http://foggry.com/blog/2015/05/06/chi-ping-xuan-ran-xue-xi-bi-ji/?utm_source=tuicool)

相比于当前屏幕渲染，离屏渲染的代价是很高的，主要体现在两个方面：

1.  创建新缓冲区
    
    > 要想进行离屏渲染，首先要创建一个新的缓冲区。
    
2.  上下文切换
    
    > 离屏渲染的整个过程，需要多次切换上下文环境：先是从当前屏幕（On-Screen）切换到离屏（Off-Screen）；等到离屏渲染结束以后，将离屏缓冲区的渲染结果显示到屏幕上有需要将上下文环境从离屏切换到当前屏幕。而上下文环境的切换是要付出很大代价的。