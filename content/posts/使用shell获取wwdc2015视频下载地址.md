---
title: '使用shell获取wwdc2015视频下载地址'
date: Sun, 16 Aug 2015 00:04:08 +0000
draft: false
tags: ['shell']
---

WWDC在[这里](https://developer.apple.com/videos/wwdc/2015/)有个视频列表的页面，这个页面列面是有大部分2015年wwdc视频的连接的。苹果以前在一个页面里面就会放出所有视频的url，但这里需要你进入视频播放页面才会有高清和标清视频，所以以前直接拿页面进行正则匹配的方式不行了。这里放出一个脚本自动取出2015年wwdc视频地址列表的shell脚本。直接bash运行即可在当前运行目录下创建一个urlList.txt文件来保存地址列表。 [![屏幕快照 2015-08-16 8.02.08 AM](http://www.karsa.info/blog/wp-content/uploads/2015/08/屏幕快照-2015-08-16-8.02.08-AM-300x83.png)](http://www.karsa.info/blog/wp-content/uploads/2015/08/屏幕快照-2015-08-16-8.02.08-AM.png)  
```

#! /bin/bash 

for idStr in $(curl "https://developer.apple.com/videos/wwdc/2015/" | grep -o "?id=\[^\\"\]\*")
do
 for url in $(curl "https://developer.apple.com/videos/wwdc/2015/$idStr" | grep -o "\\"http://devstreaming.apple.com/videos/wwdc/2015/\[^\\"\]\*hd\[^\\"\]\*\\"")
 do 
 echo $url >> ./urlList.txt
 done
done


```
