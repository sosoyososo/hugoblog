---
title: 'golang实现宜搜小说全本下载'
date: Fri, 14 Aug 2015 19:31:14 +0000
draft: false
tags: ['golang']
---

使用简单，只有一个参数就是任何一个宜搜小说章节内容页面的url，程序自动下载所有的章节，并保存到当前工作目录下的1.txt文件中。 工作原理是宜搜小说章节页面url中的st参数就是指定章节的方式，从1开始，按照顺序直到结束。下载的内容是网页，截取固定tag之间内容取出title和content，并去掉一些乱码和标记，作为一个章节的内容写入文件就可以得到这本小说的全文本内容。
```

/\*
./esou "http://book.easou.com/c/show.m?cu=http%3A%2F%2Fleduwo.com%2Fbook%2F15%2F15964%2F5079367.html&gid=416942&nid=12290553&or=0&st=5"
唯一的参数是任意一章的地址
\*/

package main

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"strings"
)

var (
	file    \*os.File
	fileErr error
)

func getHtmlContentWithUrl(url string) \[\]byte {
	resp, err := http.Get(url)
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err == nil {
		return body\[:\]
	} else {
		return \[\]byte{}
	}
}

func isPathExist(path string) bool {
	\_, err := os.Stat(path)
	if err == nil {
		return true
	}
	if os.IsNotExist(err) {
		return false
	}
	return false
}

func makeDir(dir string) string {
	if isPathExist(dir) == false {
		os.Mkdir(dir, 0700)
		return dir
	}
	return ""
}

func makeFileWithBytes(url string, content \[\]byte) {
	relativePath := "./pages/"
	makeDir(relativePath)
	relativePath += url
	fmt.Println(relativePath)
	file, err := os.Create(relativePath)
	if nil == err {
		defer file.Close()
		file.Write(content)
	}
}

func hasNextPage(currentPage string) bool {
	mainTagContent := ">下章</a>"
	index := strings.Index(currentPage, mainTagContent)
	if index != -1 {
		return true
	}
	return false
}

func getPageContent(content string) (string, string) {
	title := ""
	txt := ""
	titleStart := "<title\_tag>"
	titleEnd := "</title\_tag>"
	index := strings.Index(content, titleStart)
	if -1 != index {
		subcontent := content\[index+len(titleStart):\]
		index = strings.Index(subcontent, titleEnd)
		title = subcontent\[:index\]
		title = strings.Join(strings.Split(title, "<br/>"), "")
		title = strings.TrimSpace(title)
		// fmt.Println(title)
		subcontent = subcontent\[index+len(titleEnd):\]

		contentStart := "<content\_tag>"
		contentEnd := "</content\_tag>"
		index = strings.Index(subcontent, contentStart)
		subcontent = subcontent\[index+len(contentStart):\]
		index = strings.Index(subcontent, contentEnd)
		txt = subcontent\[:index\]
		txt = strings.Join(strings.Split(txt, "<br/>"), "")
		txt = strings.Join(strings.Split(txt, "&#160;"), "")
		// fmt.Println(txt)
	}
	return title, txt
}

func getPage(urlStr string, page int) bool {
	bytes := getHtmlContentWithUrl(urlStr)
	content := string(bytes)
	hasNext := hasNextPage(content)
	title, txt := getPageContent(content)
	pageContent := title + "\\n\\n" + txt
	writeToFile(pageContent)
	return hasNext
}

func writeToFile(content string) {
	file.WriteString(content)
}

func getContentWithUrl(urlValue \*url.URL) {
	values, err := url.ParseQuery(urlValue.RawQuery)
	if nil == err {
		st := 1
		for {
			values.Set("st", strconv.Itoa(st))
			query := values.Encode()
			urlValue.RawQuery = query
			url := urlValue.String()
			fmt.Println(url)
			hasNext := getPage(url, st)
			if !hasNext {
				break
			}
			st++
		}
	}
}

func main() {
	urlStr := os.Args\[1\]
	filePath := "./1.txt"
	if len(urlStr) > 0 {
		file, fileErr = os.Create(filePath)
		defer file.Close()

		urlValue, err := url.Parse(urlStr)
		if nil == err {
			getContentWithUrl(urlValue)
		}
	}
}


```
