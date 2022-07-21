---
title: '微信小程序使用babel避免 Cannot read property of undefined'
date: Mon, 29 Jun 2020 12:00:23 +0000
draft: false
tags: ['前端']
---

1.  全局安装 @babel/cli +onchange
2.  项目安装 @babel/core + @babel/plugin-proposal-optional-chaining
3.  创建.babelrc,设置plugin为@babel/plugin-proposal-optional-chaining （后续示例）
4.  全局运行一次 npx babel . --out-dir ../proj-copy-name --copy-files
5.  监控js文件 onchange '\*\*/\*.js' -- npx babel '{{changed}}' --out-file ../proj-copy-name/'{{changed}}'
6.  监控其他文件 onchange '**/\*.wxml' '**/\*.wxss' '\*\*/\*.json' -- cp '{{changed}}' ../inhoo-bidding-dist/'{{changed}}'
7.  使用小程序开发工具打开目录 proj-copy-name 进行预览，用其他编辑器进行开发
8.  在package.json中添加npm脚本方便运行和记忆

> .babelrc 文件内容


```

{
  "plugins": ["@babel/plugin-proposal-optional-chaining"]
} 

```


> package.json脚本内容


```

{
"scripts": {
    "watchjs":"onchange '**/*.js' -- npx babel '{{changed}}' --out-file ../proj-copy-name/'{{changed}}'",
    "watchres":" onchange '**/*.wxml' '**/*.wxss' '**/*.json'   -- cp '{{changed}}' ../proj-copy-name/'{{changed}}'",
    "init":"babel . --out-dir ../proj-copy-name --copy-files"
  },
} 

```
PS. babel是个好东西，而到这里，其实babel的其余特性你也可以用了。 Happy coding , 原力与你同在，卢克。