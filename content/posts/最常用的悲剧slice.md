---
title: '最常用的悲剧slice'
date: Wed, 08 Apr 2020 16:51:41 +0000
draft: false
tags: ['golang']
---

Go中我们一直强调slice只是array的引用，修改slice会修改array，复制slice给一个变量，只是拷贝了引用。 若是不理解这个逻辑，这段异常代码可能会刷新三观。 代码对两种4个字符串的所指引的数字列表进行排列组合，4的4次方，一共是256个结果。 核心点在于对slice的广泛应用所导致异常问题，在 `indexes = append(indexes, index)`这段代码前后，在某种特定条件下，与之无关的tmpRet内容被修改；最终导致生成内容并非实际需要，存在大量不正常的重复。
```

func test() {
    wordsIndexesMap := map\[string\]\[\]int{"ab": \[\]int{0, 3, 5, 8}, "ba": \[\]int{1, 4, 7, 9}}
    words := \[\]string{"ab", "ba", "ab", "ba"}

    indexesRet := \[\]\[\]int{}
    for \_, word := range words {
        indexList := wordsIndexesMap\[word\]

        tmpRet := \[\]\[\]int{}
        for \_, index := range indexList {
            if len(indexesRet) > 0 {
                for \_, indexes := range indexesRet {
                    indexes = append(indexes, index)
                    if len(indexes) == 4 {
                        fmt.Println(indexes)
                    }
                    tmpRet = append(tmpRet, indexes)
                }
            } else {
                tmpRet = append(tmpRet, \[\]int{index})
            }
        }
        indexesRet = tmpRet
    }
    fmt.Println(indexesRet)
}

```
为什么和如何破? 破解很简单，go有一个内置的方法，copy可以复制slice内容。 `indexes = append(indexes, index)` 这段，对indexes 进行内容复制，后面的操作都在拷贝上进行即可破解。但这是为啥？ 我理解跟两个方面相关，一个是slice的引用，一个是append时候是新分配新空间操作还是原有空间操作。可以确定的是，indexes 间接引用并错误的修改了 tmpRet 内容，比如新增元素的时候，新增的空间和原有的空间指向了同一个位置。新增成功，但新的内容和原有内容就重复覆盖了。具体发生的时机也很清楚，但细节还不清晰。 还有另外两点值得注意，一个是二维slice的操作和for range 遍历slice时候的操作。