---
title: "为html做了个简单的xpath选择器"
date: 2022-07-21T12:21:48+08:00
Description: ""
Tags: ['go', '工具']
---

出身开发，在处理事情的时候总避免不了从数据出发，这个网络发达的时代，很多数据都以网页的形式呈现，就经常会碰到需要对网页数据进行选择筛选。如果是写代码，那么有很多种选择，但没有找到一个合适的命令行工具做这个事情。

命令行工具的好处是可以通过shell跟其他工具配合，把其他工具功能选择项，只要解决中间最缺少的部分即可。

为了实现html的选择，基于 `https://github.com/PuerkitoBio/goquery` 做了一个极简单的选择器，作用也很简单，输入一个选择器，把选择出来的内容打印出来，尽可能的保留goquery本身的功能，功能做的尽可能的单一，就不用写文档了。

地址在 	`https://github.com/sosoyososo/htmlselector` 需要自取 。