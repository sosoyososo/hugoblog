---
title: '珍惜生命，远离JAVA'
date: Wed, 14 Nov 2018 08:13:38 +0000
draft: false
tags: ['瞎逼逼']
---

JAVA对于我的印象，是老旧，沉重，完美但复杂。最近出于一些原因，看了一下JAVA相关的东西，没有多深入，只是想了解一下，对于一个不算很资深的人来说，快速上手JAVA Web开发需要看多少内容。嗯，当前的技术栈是Groovy+Grails。 首先我需要知道，程序是怎么跑起来的。于是我看了Tomcat，于是知道了Server，Service，Host，Context，Connector，Container东西，之后Container还有Engine，Host，Context，Wrapper，再之后Wrapper才封装了一直闻名遐迩的Servlet，而Servlet只是Tomcat跟我们写的java代码之间沟通的协议。写Java Web代码还需要知道Spring，SpringMVC，到此为止可以写出Hello World了。嗯完整的Java web，你最好还要知道MyBatis，Hibernate。对于Grails+Groovy，除了这些之外，你还需要Groovy语言和Grails框架。 但是，上面的只是名词，就罗列了一排。其中只一点，Spring注解就能让人望而却步，在多数情况下，你使用的时候，到底影响了什么，你根本不可能知道的很清楚，因为他只是一个配置。我所看到的名词多数都是通过配置组合起来的，而Java中到处充满这种你知道做了什么，不知道怎么做的东西。这是一个用完美运行的复杂机器只完成了很小的一件事情的机制。对于初学者，这是个黑箱子，学习曲线非常陡峭，而且学习通常对于你的提升只在于你了解了这个架构，去体会它各种美好复杂的结构，但也仅此而已，他不会让你对于网络，对于系统，对于业务有更多的了解。 仅仅针对Web开发，我理解一个好的架构体系，应该有几个特点： 1. 对于懂得HTTP原理的人，查询HTTP相关问题不会很费劲； 2. 对于没有开发过MVC的人，了解一下MVC，选择一个差不多的MVC框架，能快速开展工作； 3. 对于一个熟悉整个开发流程的人，他的主要工作应该是在对业务的理解，架构的优化，效率的提升上，而非与艰深复杂的脚手架斗争； 4. 对于一个精通整个流程的人，他唯一可以炫耀的应该是对于数据有多少提升，而这些提升的原因，应该是对于web框架的优化，使用了更快的业务模块，数据库的优化等等，而绝非是因为熟悉而调优了脚手架； 简单，直观，快速，核心集中在业务、优化，而非脚手架。所以，仅仅针对于Web开发，完全反对java web的整个逻辑。你很美，但你太难上。so fuck off。