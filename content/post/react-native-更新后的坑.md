---
title: 'React Native 更新后的坑'
date: Tue, 29 May 2018 13:43:23 +0000
draft: false
tags: ['React Native']
---

最近折腾的时候把RN代码改的有点乱，就索性删掉重新更新了一下，记录一下更新遇到的问题。

1.  更新后无法编译React，提示没有glog/logging.h等glog相关头文件。 暂时目测原因是rn本身的脚本问题导致的， https://github.com/facebook/react-native/issues/14382 高票答案回答了问题所在，我在后面解释了原因(id是sosoyososo)。
    
2.  Xcode编译通过，但自动化脚本编译失败，提示脚本执行错误(返回 error code 65)。 可能是RN这边打包的时候如果RN的服务已经在运行，新的脚本会执行失败导致，关掉RN的服务即可。