---
title: 'git fatal: Will not add file alias'
date: Tue, 24 Nov 2015 07:51:09 +0000
draft: false
tags: ['tools']
---

最近在使用git的时候发生一件比较神异的事情，我在使用git status命令后出现下面这样的情景 [![屏幕快照 2015-11-24 3.32 + Rectangle 4](http://www.karsa.info/blog/wp-content/uploads/2015/11/屏幕快照-2015-11-24-3.32-Rectangle-4-300x91.png)](http://www.karsa.info/blog/wp-content/uploads/2015/11/屏幕快照-2015-11-24-3.32-Rectangle-4.png) 在此之前只有一个文件出现这个问题的时候我企图用git add .来蒙混过关，结果当然也很不幸 [![屏幕快照 2015-11-24 3.33 + Rectangle 1 + Rectangle 2](http://www.karsa.info/blog/wp-content/uploads/2015/11/屏幕快照-2015-11-24-3.33-Rectangle-1-Rectangle-2-300x8.png)](http://www.karsa.info/blog/wp-content/uploads/2015/11/屏幕快照-2015-11-24-3.33-Rectangle-1-Rectangle-2.png) 谷大神想了许久说，一般都是在windows上文件大小写不同的时候会有这种问题，你这样的，还是在mac上，我确实也没见过啊。 最后我在xcode里修改了文件名，然后发现文件果然区分开了，一份原来的名字，一份新名字。为保险起见我直接git add . / git commit ,之后又删除新文件再次执行add／commit终于搞定。 可能是文件系统产生问题，导致的吧。因为如果是git的问题，我修改文件名不会导致出来两份文件的啊 。不过纯属YY啦，继续干活～