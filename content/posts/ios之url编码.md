---
title: 'iOS之URL编码'
date: Tue, 14 Jun 2016 02:34:43 +0000
draft: false
tags: ['iOS', 'swift']
---

再次碰到URL编码问题，这不是第一次踩坑了，决定找一个平台内的彻底的解决方案。google了一下，有几种处理方法:

1.使用 CFURLCreateStringByAddingPercentEscapes 方法 \`\`\` @"!\*'();:@&=+$,/?%#\[\]" \`\`\`

作为字符集，kCFStringEncodingUTF8作为编码来处理的，原理其实是把字符串先utf8编码，在对包含的字符集进行百分号转码。

2.自己手动修改的,原理跟上面一样，只是自己进行处理，对字符串先进行utf8编码，之后读取每个字符不在字符集中的进行百分号编码

在对上述进行判断之前我们先回归问题的实质，url以及url编码本身。

参照\[wiki百科\](https://zh.wikipedia.org/wiki/%E7%99%BE%E5%88%86%E5%8F%B7%E7%BC%96%E7%A0%81) 百分号编码也叫做url编码就是对不允许出现在url中的的字符串，每个byte转化成对应的十六进制表现字符串，前面加上百分号。比如数字100对应的字符是小写的d,对应的十六进制是64，所以d的百分号编码是%64。url中可以出现的字符在RFC 3986中以及上述的百科中有说明，这里不再列举。

那么我们可以很轻易的知道google到的答案其实是不完整的，那么我们可以怎么做？还好，Apple对此已有考虑，在NSCharacterSet字符集类中，我们看到有关于URL中出现的每个部分允许出现的字符的集合方法,并且还有专门的百分号编码方法。新的(Swift版本)URL编码方法如下:


```

import Foundation

extension String {

    func urlEncodedString() -> String? {

        let urlCharacterSet = NSMutableCharacterSet()

        urlCharacterSet.formUnionWithCharacterSet(NSCharacterSet.URLFragmentAllowedCharacterSet())

        urlCharacterSet.formUnionWithCharacterSet(NSCharacterSet.URLHostAllowedCharacterSet())

        urlCharacterSet.formUnionWithCharacterSet(NSCharacterSet.URLPasswordAllowedCharacterSet())

        urlCharacterSet.formUnionWithCharacterSet(NSCharacterSet.URLPathAllowedCharacterSet())

        urlCharacterSet.formUnionWithCharacterSet(NSCharacterSet.URLQueryAllowedCharacterSet())

        urlCharacterSet.formUnionWithCharacterSet(NSCharacterSet.URLUserAllowedCharacterSet())

        let retStr = self.stringByAddingPercentEncodingWithAllowedCharacters(urlCharacterSet)
        return retStr
    }
}

```
