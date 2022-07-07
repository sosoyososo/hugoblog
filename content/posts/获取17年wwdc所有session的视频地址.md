---
title: '获取17年WWDC所有Session的视频地址'
date: Thu, 20 Jul 2017 06:23:48 +0000
draft: false
tags: ['shell']
---

##思路 视频列表页面没有视频的地址，只有播放页面的地址，视频下载地址放在播放页面中。视频列表页面中获取到所有的视频播放页面，去重，然后下载播放页面，解析出视频地址。

代码
--

如果想要高清视频，将 “SD Vedio” 换成 “HD Video” 就行,16年的列表，将wwdc2017换成wwdc2016即可
```

curl -L https://developer.apple.com/videos/wwdc2017/ | grep -o "/videos/play/wwdc2017/[0-9]*/" | sed 's/^/http:\/\/developer.apple.com&/g'   | sort -u |xargs curl -L | grep "SD Video"  | grep -o "\"http[^\"]*\"" 

```


查漏
--

脚本只会处理成功的，但不可避免有时候会失败，这个并没有提示，所以需要自行查找遗漏的session。 列出所有session代码:
```

curl -L https://developer.apple.com/videos/wwdc2017/ | grep -o "/videos/play/wwdc2017/[0-9]*/" | grep -o "/[0-9]*" | sort -u 

```
所有找到的session：
```

cat path/to/sessionDownloadUrlListFile |  grep -o "/[0-9]*_" | grep -o "/[0-9]*" | sort -u 

```
两厢对比一下就行了。