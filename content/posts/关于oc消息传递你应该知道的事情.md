---
title: '关于OC消息传递你应该知道的事情'
date: Tue, 30 Dec 2014 08:08:06 +0000
draft: false
tags: ['Read Note']
---

这是我对OC语言本身回顾的第四弹，熟悉的人直接跳过。 相关的类NSObject／NSInvocation／NSMethodSignature NSInvocation代表了一个message的静态存储，存储一个方法调用所需的所有信息。 NSMethodSignature代表了方法的参数，返回值信息 默认情况下，所有的NSObject基类调用方法的原则是在自己的方法列表中寻找对应的方法，如果没有找到，就在父类中寻找，一直到NSObject。如果途中找到，就终止寻找，调用相应实现(默认不会调用父类实现，如果有需要，需要明确调用父类的同名方法)，如果一直到NSObject都没有实现这个方法，会调用forwardInvocation:方法来进行消息转发，如果消息没有被转发，需要做出响应的处理。而NSObject的默认处理是简单的调用了doesNotRecognizeSelector:，而NSObject的doesNotRecognizeSelector:方法简单的throw了一个NSException，这就是我们调用一个不存在的方法会导致crash的原因。 如果你要实现forwardInvocation:，那么你也要实现methodSignatureForSelector:方法，因为前者的调用需要后者提供的实现来返回调用的参数。这两个方法同时构成了一个消息链路修改逻辑。 使用上述完整的转发机制，使得你有机会对转发的消息做一些修改，但是如果你不需要，你还可以使用更简单的方式。简单的使用forwardingTargetForSelector:方法，返回一个对应某个消息的对象，会导致在无法寻到方法的时候，简单的将消息的target修改为返回的对象。 我们还可以使用resolveClassMethod:方法和resolveInstanceMethod:来动态的为一个类提供某个方法实现，因为这两个方法在OC进入消息转发链之前起作用，所以不会影响到正常方法调用的机制。 \[self class\]; \[super class\]; 所以上面两个方法返回一样的内容就不足为奇了，因为他们最终调用的都是NSObject的实现,如果想知道父类的type，需要调用\[self superclass\];