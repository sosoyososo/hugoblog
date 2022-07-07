---
title: 'shell管道和参数管道'
date: Sun, 16 Aug 2015 01:24:06 +0000
draft: false
tags: ['shell']
---

shell管道和参数管道 管道 | : 使用格式: cammand1 | cammand2 | cammand3 管道是将前一个命令的stdout作为后一个命令的stdin使用，所以后一个命令必须是可以从stdin接收数据的命令，这样的命令成为管道命令。 比如

```

curl "www.baidu.com" | grep -o "\\"\[^\\"\]\*\\""

```

会获取网页"www.baidu.com"，然后输出所有双引号之间的内容 参数管道 |xargs: 使用格式:cammand1 | xargs cammand2 | xargs cammand3 当一个非管道命令需要作为后一个命令参与命令连接的时候，使用参数管道。这时候前者的stadin会作为后一个命令的参数存在，以空格作为分割。比如：

```

find ./ -iname "\*.jpg" | ls -l

```

因为ls是非管道命令，不能从stdin读内容，所以输出的内容是 ls -l的返回结果: [![屏幕快照 2015-08-16 9.07.20 AM](http://www.karsa.info/blog/wp-content/uploads/2015/08/屏幕快照-2015-08-16-9.07.20-AM-300x157.png)](http://www.karsa.info/blog/wp-content/uploads/2015/08/屏幕快照-2015-08-16-9.07.20-AM.png)

```

find ./ -iname "\*.jpg" |xargs ls -l

```

这个命令使用 `find ./ -iname "\*.jpg"` 的返回结果作为ls -l的参数，所以返回了所有找到文件的信息![屏幕快照 2015-08-16 9.06.17 AM](http://www.karsa.info/blog/wp-content/uploads/2015/08/屏幕快照-2015-08-16-9.06.17-AM-300x168.png)
