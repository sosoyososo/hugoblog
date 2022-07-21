---
title: '命令行下载Xcode'
date: Fri, 04 Aug 2017 13:28:25 +0000
draft: false
tags: ['shell']
---

为啥用命令行？有很多原因，对我，最重要有有两个：1. 可以在VPS上下载，有时候会很快，真的很快。 2. 连续性，在自己电脑上，长时间占资源不说，还老因为电脑休眠断掉。 话不多说，直接来结果：
```

curl -C - -H "Referrer Policy:no-referrer-when-downgrade" \
-H "Accept-Encoding:gzip, deflate, br" \
-H "Accept:text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" \
-H "Connection:keep-alive" \
-H "Host:download.developer.apple.com" \
-H "Referer:https://developer.apple.com/download/more/" \
-H "Upgrade-Insecure-Requests:1" \
-H "User-Agent:Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36" \
--cookie "{cookieContent}" \
-o ./{saveName} \
{xcode_download_url} 

```
替换cookieContent、saveName、xcode\_download\_url三个变量即可。cookieContent 和 xcode\_download\_url 都可以在用浏览器下载Xcode的时候看到，saveName就是保存的名字。 \_\_\_\_\_\_ Updated At 2020.11.20 新增 \`\`\` -C - \`\`\` 选项来进行断点续传，如不需要可去掉