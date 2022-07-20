---
title: 'openwrt安装步骤'
date: Mon, 27 Jul 2015 03:58:56 +0000
draft: false
tags: ['折腾']
---

1.查询openwrt的设备支持列表，地址 http://wiki.openwrt.org/toh/start 2.找到你的设备，比如，我的是tp-link wr703n,点击名字查看详情，http://wiki.openwrt.org/toh/tp-link/tl-wr703n 3.在flashing小结里面找到 Download latest squashfs-factory.bin for the initial flash 这句话，下载 squashfs-factory.bin 链接指向的文件就是需要的openwrt文件 4.登录你的路由器，选择下载的文件对路由器升级(据说名字太长会报错，我没试过，不过最好改一下名字，短小的全英名称最好) 5.升级成功你的路由器会自动重启，但不能作为路由器使用，什么连wifi模块都没有开启。 6.将你的电脑配置成DHCP模式，用网线连接路由器，设置电脑ip为静态ip，192.168.1.\*(＊非1) 7.ping 192.168.1.1,如果ping通OK了 8.telnet 192.168.1.1,使用passwd修改密码 9.密码修改成功后ssh就启动了，使用root和刚设置的密码登陆 10.在设置路由器的过程中很容易设置错，就跟外面断掉连接了，需要重置一下，每个路由器都有reset按钮，我的是一个小孔，断电重连，长按一段时间松开，led会狂闪，就进入safe模式，这时你可以回到第六步，但telnet进去设置密码的时候会说文件是read-only的，这时需要firstboot命令恢复设置，然后reboot重启之后就可以设置密码了