---
title: 'Swift的Array与ArraySlice'
date: Wed, 17 May 2017 03:53:05 +0000
draft: false
tags: ['swift']
---

在Swift中我们对数组的使用主要涉及到两个结构体，Array和ArraySlice，一般对Array做剪切操作的结果会是ArraySlice，剪切操作类似与取出前三个，中间10个，后两个等。Apple在文档中提到，加入ArraySlice是为剪切操作结果可以共用原始Array的存储，而不必重新分配内存空间，以此来提升程序的运行效率。 在实测过程中，创建Array，截取得到ArraySlice，然后打印了元素指针，我发现数据并没有重用。去掉打印元素指针的操作后，通过Xcode的工具去查看，发现确实又共用了内存。看来对内存操作在编译器看来也符合了Swift copy-on-write 的原则。 下面的测试代码，注释打开会发现内存中只有一份数组，而关闭后会发现变成了两份：
```

import Foundation



var array = Array<Int>.init(repeating: 1, count: 100000)
var slice = array[0...1000]
/*
for i in 0..<10 {
    _=withUnsafePointer(to: &array[i]) { (p) -> String in
        print(p.debugDescription)
        return p.debugDescription
    }
}

print("======")

for i in 0..<10 {
    _=withUnsafePointer(to: &slice[i]) { (p) -> String in
        print(p.debugDescription)
        return p.debugDescription
    }
}*/

print("======") 

```
打开注释的内存： ![](http://www.karsa.info/blog/wp-content/uploads/2017/05/屏幕快照-2017-05-17-上午11.46.48-300x222.png) 关闭注释的内存： ![](http://www.karsa.info/blog/wp-content/uploads/2017/05/屏幕快照-2017-05-17-上午11.46.14-300x240.png)