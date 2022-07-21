---
title: 'shell获取当前页面所有符合某个前缀的url'
date: Tue, 18 Aug 2015 05:51:17 +0000
draft: false
tags: ['shell']
---

嗯，这段代码是熟悉shell练手用，性能问题比较大，所以千万不要试图去掉那行注释掉的代码，否则你会知道它有多疯狂～
```

#! /bin/bash 
# bash site.sh currentUrl baseUrl

# 参数获取
if \[ x$1 != x \]
then
    currentUrl=$1
else
	echo "必须要有页面的url"
	exit
fi

if \[ x$2 != x \]
then
    baseUrl=$2
	echo $baseUrl
else
	echo "必须要有基础url"
	exit
fi

# 获取网页并进行处理
function getLinkWithBaseUrlInCurrentPage() 
{
	for pageUrl in $(curl $currentUrl | grep -o "http://\[^\\"<\]\*")
	do
		if \[ "${pageUrl#$baseUrl}"x != "$pageUrl"x \] 
		then 
			echo "$pageUrl"
			# getLinkWithBaseUrlInCurrentPage $currentUrl $baseUrl
		fi
	done	
	return 0
}

getLinkWithBaseUrlInCurrentPage $currentUrl $baseUrl

```
