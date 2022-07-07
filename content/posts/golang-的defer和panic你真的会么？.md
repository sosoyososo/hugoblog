---
title: 'Golang 的defer和panic,你真的会么？'
date: Mon, 01 Jun 2020 02:38:20 +0000
draft: false
tags: ['Uncategorized']
---

看很多面试题中有提到defer和panic的配合，大概是说出下面代码的输出顺序：
```

func testDeferAndPanic() {
    defer fmt.Println("打印前")
    defer fmt.Println("打印前")
    defer fmt.Println("打印前")
    panic("崩溃") 
} 

```
一般我们知道defer先进后出以及panic最后执行的都不会感觉难，但止步于此，也就那样了。 要真正理解defer和panic还是要带入具体的实践中。真正的情况应该是下面几种情况的组合：

1.  defer
2.  panic
3.  panic in defer
4.  recover panic
5.  panic in recover
6.  recover panic in defer
7.  recover panic in defer and then panic
8.  recover panic in defer and then panic and then recover
9.  defer panic recover mix in call stack

这里列出几种简单组合酸爽一下，看看你是否真的会：
```

package main

import "fmt"

func testDeferAndPanic1() {
    defer fmt.Println("打印前")
    defer fmt.Println("打印中")
    defer fmt.Println("打印后")
    fmt.Println("运行中")
    panic("崩溃")
}

func testDeferAndPanic2() {
    defer func() {
        if ok := recover(); ok != nil {
            fmt.Println(ok)
        }
    }()
    defer fmt.Println("打印前")
    defer fmt.Println("打印中")
    defer fmt.Println("打印后")
    fmt.Println("运行中")
    panic("崩溃")
}

func testDeferAndPanic3() {
    defer fmt.Println("打印前")
    defer fmt.Println("打印中")
    defer fmt.Println("打印后")
    defer func() {
        if ok := recover(); ok != nil {
            fmt.Println(ok)
        }
    }()
    fmt.Println("运行中")
    panic("崩溃")
}

func testDeferAndPanic4() {
    defer fmt.Println("打印前")
    defer func() {
        if ok := recover(); ok != nil {
            fmt.Println(ok)
            panic("panic again")
        }
    }()
    fmt.Println("运行中")
    panic("崩溃")
}

func testDeferAndPanic5() {
    defer fmt.Println("打印前")
    defer func() {
        defer func() {
            if ok := recover(); ok != nil {
                fmt.Println(ok)
            }
        }()
        if ok := recover(); ok != nil {
            fmt.Println(ok)
            panic("panic again")
        }
    }()
    fmt.Println("运行中")
    panic("崩溃")
}

func testDeferAndPanic6() {
    defer fmt.Println("打印前")
    defer panic("panic defer")
    panic("panic")
}

func testDeferAndPanic7() {
    defer fmt.Println("打印前")
    defer panic("panic defer")
    defer func() {
        if ok := recover(); ok != nil {
            fmt.Println(ok)
        }
    }()
}

func testDeferAndPanic8() {
    defer fmt.Println("打印前")
    defer func() {
        if ok := recover(); ok != nil {
            fmt.Println(ok)
        }
    }()
    defer panic("panic defer")
} 

```
