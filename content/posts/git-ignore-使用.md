---
title: 'git ignore 使用'
date: Fri, 19 Aug 2016 06:08:19 +0000
draft: false
tags: ['折腾']
---

> git help ignore / man gitignore 文档笔记

##设置方式

> git ignore file描述需要忽略的文件，但是不影响已经加入到git的文件。文件的每一行指定了一个pattern，git检测多个来源的文件来决定是否忽略文件，这些检测有优先级，从上到下依次是:


```

1.从命令行支持的命令读取的pattern
2.当前目录的.gitignore文件里面的pattern，子目录文件的pattern会覆盖父目录的pattern，pattern里面的路径相对当前.gitignore文件所在的路径
3.$GIT_DIR/info/exclude 文件里面的pattern
4.core.excludesFile 指定的配置文件里面的pattern 

```
##使用哪种方式设置 1.如果需要随着当前代码库，分享给其他通过git clone获取代码的开发者，需要用 .gitignore 文件来控制 2. 如果只是一个人而非团队同用，那就需要把pattern写入$GIT\_DIR/info/exclude文件 3. 如果用户想设置自己所有工程的忽略文件，那么可以设置~/.gitconfig指定的配置文件 ##PATTERN格式
```

 # 空行不匹配任何文件
# 开头的行是注释
file\                       # 当前文件夹名为file 的文件(file+空格)
!foo.html                   # !取消忽略当前文件夹名为foo.html
\!important.txt         # 当前文件夹内名为!important.txt的文件
foo.txt                     # 当前文件夹内名为foo.txt的文件
dir/                        # 当前文件夹内名为dir的文件夹
*.html                      # 当前文件夹内所有html文件
*.[oa]                      # 当前文件夹内所有.o .a文件
＊                           # 不匹配所有的路径，只匹配文件名,所以有:
Documentation/*.html    # 匹配Documentation/git.html 不匹配 Documentation/git/   git.html 不匹配 tools/perf/Documentation/perf.html
/*.c                        # 等同 *.c 

```

```

**                          # 匹配所有的路径
**/foo                      # 匹配任何地方名为foo的文件和文件名
/**                         # 当前目录下所有内容
a/**/b                      # "a/b", "a/x/b", "a/x/y/b"
                            # 其他的都是无效的 

```
