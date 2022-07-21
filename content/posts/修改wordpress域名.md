---
title: '修改wordpress域名'
date: Thu, 13 Aug 2015 09:02:07 +0000
draft: false
tags: ['折腾']
---

正常情况下修改wordpress的域名很简单，如图所示wordpress后台设置里面就有。 [![屏幕快照 2015-08-13 4.36.15 PM](http://www.karsa.info/blog/wp-content/uploads/2015/08/屏幕快照-2015-08-13-4.36.15-PM-300x47.png)](http://www.karsa.info/blog/wp-content/uploads/2015/08/屏幕快照-2015-08-13-4.36.15-PM.png) 一旦你设置wordpress的域名为一个错误域名，你将不能进入wordpress的后台，这时候应该怎么恢复域名呢？ wordpress的后台数据是在mysql里面保存的，你只需要登录你的mysql修改相关内容即可。 察看你的wordpress里面的mysql配置(WordPressPath一般默认是在/var/www/html/目录下):
```

cat WordPressPath/wp-config.php | grep DB\_

```
返回内容需要下面三行:
```

define('DB\_NAME', 'db\_name');
define('DB\_USER', 'user\_name');
define('DB\_PASSWORD', 'user\_pswd');

```
登录mysql所在机器，输入命令察看mysql是否启动:
```

lsof -i -P

```
返回内容列表如果有这一行:
```

COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME
mysqld 972 mysql 10u IPv4 9485 0t0 TCP localhost:3306 (LISTEN)

```
说明mysql已经启动(3306是mysql的默认端口，如果你使用了其它端口，需要寻找对应端口)，如果没有启动那你需要启动你的mysql。 输入命令并按照提示输入密码user\_pswd，进入mysql:
```

mysql -u user\_name -p

```
连接数据库:
```

connect db\_name;

```
察看现在的wordpress的URL配置:
```

select \* from wp\_options where option\_name = "siteurl" or option\_name = "home";


```
更新配置:
```

update wp\_options set option\_value = "home\_url" where option\_name = "siteurl" or option\_name = "home";


```
刷新页面就可以重新连上你的wordpress，并且正常操作了。