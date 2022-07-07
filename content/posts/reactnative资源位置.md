---
title: 'ReactNative资源位置'
date: Sun, 29 Apr 2018 07:17:21 +0000
draft: false
tags: ['React Native']
---

### 资源加载顺序:

1.  jsLocation(从UserDefaults读取一个字符串作为host)
2.  ip.txt(从ip.txt读取ip作为hose)
3.  localhost(直接使用localhost)
4.  main.jsbundle(从main.jsbundle文件直接读取js)

### 使用说明

1.  fallback: 每一步都是前一步的fallback，就是说前一步有用的话用前一步，不可用才会看后一步
2.  server running: 前三步的到的本质上都是一个ip地址，需要连接server，在第三步之后，需要判断获取到的host上，是否有server在运行，如果有，就使用前三步返回的host，没有就使用main.jsbundle