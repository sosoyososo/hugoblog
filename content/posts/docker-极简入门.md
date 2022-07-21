---
title: 'Docker 极简入门'
date: Thu, 26 Oct 2017 06:12:46 +0000
draft: false
tags: ['折腾']
---

1.  基础概念 镜像：静态文件。 容器：可以运行的镜像实例，有不同状态，我们所有操作的实体。
    
2.  基本操作 // 下载ubuntu镜像 docker pull ubuntu //创建一个ubuntu的容器,进入容器，运行/bin/bash ，这时候你已经在容器里了，把它当作一个全新独立的系统。做任何当前系统允许你做的事情。 docker run -t -i ubuntu /bin/bash //退出系统 exit
    
    //再次进入  
    docker ps -a //列出所有容器 docker start CONTAINER\_ID docker attach CONTAINER\_ID
    
3.  保存 你所有的操作都只会影响当前的容器，容器没了，你所有的操作都没了。需要提交的话，docker 的 commit 创建一个新的镜像，并保存。再次运行就使用这个镜像创建新的容器。