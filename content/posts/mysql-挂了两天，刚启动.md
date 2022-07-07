---
title: 'MySql 挂了两天，刚启动'
date: Sun, 29 Apr 2018 07:27:53 +0000
draft: false
tags: ['折腾']
---

MySql挂了，昨天就发现了，尝试启动，一时没有成功，忙起来就去做别的事情了。 问题是之前也发现过的，但再次遇到，之前怎么解决的也不忘记了，看了以前的命令记录，也没啥特殊之处。

### 现象和尝试

今天终于启动，记录一下问题现象和解决方法： 1. service --status-all 发现mysql是没有启动的，尝试service mysql start 失败，[具体提示可以看这里](https://www.digitalocean.com/community/questions/mysql-stopped-and-it-can-t-be-restart) 2. 尝试mysqld直接启动，没有任何提示，top发现mysqld已经在运行

### 解决

pkill mysqld service mysql start

### 猜测的原因

猜测是mysql本身已经在运行，但因为内部运行出了问题，导致service命令表明他不在运行。这时候需要杀掉mysql进行重启，而非直接再次运行。