---
title: 'shadow代码走读'
date: Thu, 30 Jul 2015 10:16:02 +0000
draft: false
tags: ['golang']
---

GoAgnent倒了之后就一直在用shadow，对它一直都很好奇，一直没去看过他的原理，本着好读书不求甚解的精神(实际是比较懒，只想满足好奇心而已)，大致看了一下代码结构。主要的内容是loca.go、server.go 以及shadowsocks下的go文件。 [![屏幕快照 2015-07-30 5.41.24 PM](http://www.karsa.info/blog/wp-content/uploads/2015/07/屏幕快照-2015-07-30-5.41.24-PM-105x300.png)](http://www.karsa.info/blog/wp-content/uploads/2015/07/屏幕快照-2015-07-30-5.41.24-PM.png)  shadow的wiki上说，shadowsocks是一个socks5协议的代理，可定制工业级别的加密算法。这些怎么体现呢？ local.go里面主要是shadow客户端代理本地请求到服务端，返回请求数据给本地请求的过程,server.go实现了接收客户端请求并进行真正请求并返回给客户端的过程。 local中，main函数进行参数解析生成配置之后就进入了run函数； run函数则是读取了配置并根据配置内容在本地监听本地端口，接到请求后直接交给handleConnection函数进行处理； handleConnection函数则先判断本地请求是否是socks5请求，然后获取请求接口，创建一个到服务器的连接，然后将链接加入一个队列了事； 从这里已经看到了socks5转发的特性，那么加密特性呢，这在哪里进行体现？ 前面我们说了，创建到服务端的连接然后加入了队列，不用说加入队列之后就是处理请求了。创建到server的连接的时候我们定位到connectToServer函数中的connectToServer这个调用，这是在conn.go中实现的，主要就是处理请求创建，数据读取，写入的。写入数据的实现Write中，我们发现了真正卸乳钱的initEncrypt 和 encrypt 的加密相关操作。加密信息，在调用DialWithRawAddr函数的时候就作为参数cipher传入并作为与服务端connect的属性在加解密的时候使用。这个信息最初是在解析服务端配置的函数parseServerConfig中，作为配置设置到服务器配置里，在创建到服务端连接时候通过se := servers.srvCipher\[serverId\]读取，然后传给DialWithRawAddr函数作为后面的使用。 encrypt.go封装了加密解密相关的操作。 config.go封装了配置相关的操作。 其他的都算事辅助型的存在，为了这个项目能运行的架构，交互，以及一些脚本。