---
title: 'swift feature'
date: Wed, 29 Jul 2015 16:06:28 +0000
draft: false
tags: ['swift']
---

1.分号分割同一行的两个语句 2.类型安全，任何时候都不进行隐藏的类型转换，任何编译期的类型错误都会报错 3.类型重定义typealias 4.tuples元组成声一个值组合作为一个变量值 5.optionals 是要么包含一个值要么不包含一个值的变量的类型 6.if语句解封optionals 7.强制解封使用 ! 放到optionals变量后面，如果没有值会报错 8.optionals binding ，if let a=b,c=d 9.值取出 print("sad \\(a)") string interpolation 10.隐式解封的optionals,使用的时候可以去掉解封步骤，在确定optionals负值之后不会清除的时候使用，可以跟普通的optionals一样使用 11.错误处理 12.Assertions断言 13.基本操作符号 swift允许进行float的模操作， a..b a..<b两个range operator 14.nil 聚连操作符 a ?? b  <==> a != nil ? a! : b 15.string是以值类型传递的 16.swift内部默认是Unicode编码，内部是Unicode Scalar 类型的字符，21bit 17.特别的字符\\0 \\\\ \\" \\u{24} 18.extended grapheme clusters(扩展字素串):特别的Character类型，由多个字素组成 19.String Indeices:字符串索引，不能用整形，因为上面所说每个字符的宽度不一致造成 20.字符串的索引，插入，删除 21.字符串的比较是比较每个字符的语言意义和表现，忽略背后的extended grapheme clusters表现，比如 \\u{e9} 和 \\u{65}\\u{301} 都表示拉丁语的é，所以即使内部表示不一样，他们也是相等的 22.字符串的具体Unicode表示，我们不必关心在程序中字符串的unicode表示，但写入文件的时候，不同的unicode表示方式会影响需要长度较长的字符，比如