---
title: 'golang 有趣的点'
date: Tue, 18 Feb 2020 10:01:51 +0000
draft: false
tags: ['golang']
---

遇到个有趣的点，golang在从具体值转换到interface的值，再取指针，丢掉了类型信息。
```

package main

import (
    "fmt"

    "reflect"
)

type A struct {
    I int
}

func convertStructToInterface() interface{} {
    return A{}
}

func unwrapPtr(i reflect.Value) reflect.Value {
    tmp := i
    for {
        if tmp.Kind() == reflect.Ptr {
            tmp = reflect.Indirect(tmp)
        } else {
            break
        }
    }
    return tmp
}

func main() {
    a := convertStructToInterface()
    av := reflect.New(reflect.ValueOf(a).Type()).Interface()
    av.(\*A).I = 10
    fmt.Println(av)
    fmt.Println(unwrapPtr(reflect.ValueOf(&a)).Kind())
    fmt.Println(unwrapPtr(reflect.ValueOf(av)).Kind())
}

输出的内容：
&{10}
interface
struct


```
