---
title: 'swift实现(POS命令)蓝牙打印分栏信息'
date: Thu, 30 Jul 2015 08:26:38 +0000
draft: false
tags: ['swift']
---

类似这样 [![wsasa](http://www.karsa.info/blog/wp-content/uploads/2015/07/wsasa-300x168.jpg)](http://www.karsa.info/blog/wp-content/uploads/2015/07/wsasa.jpg) 直接上打印代码
```

self.setTAB(\[0x10, 0x19\])
self.printText("品类/规格", isHANZI: true)
self.printTAB()
self.printText("数量", isHANZI: true)
self.printTAB()
self.printText("价格", isHANZI: true)
self.printAndGoToNextLine()

```
下面是对上面方法的实现:
```

/\*
//设置水平定点位置，最多设置32个,每个值都比前一个大，否则就结束
//值的意思是水平方向上字符位置
\*/
func setTAB(position: \[UInt8\]) {
    if position.count > 0 {
        self.writeData(NSData(bytes: \[UInt8(0x1B), UInt8(0x44)\], length: 2))
        let count = min(position.count, 32)
        let data = Array<UInt8>(position\[0..<count\])
        self.writeData(NSData(bytes: data, length: count))
        self.writeData(NSData(bytes: \[UInt8(0x00)\], length: 1))
    }
}

/\*
//移动到下一个水平定位点，如果没有设置定位点会忽略这个命令
\*/
func printTAB() {
    self.writeData(NSData(bytes: \[UInt8(0x09)\], length: 1))
}

/\*
//打印文字：如果是中文需要先进入中文模式
\*/
func printText(text: String, isHANZI: Bool) {
    if isHANZI {
        self.enterHANZIMode()
    }
    let enc = CFStringConvertEncodingToNSStringEncoding(
        CFStringEncoding(CFStringEncodings.GB\_18030\_2000.rawValue))
    if let data = NSString(string: text).dataUsingEncoding(enc) {
        self.writeData(data)
    }
    if isHANZI {
        self.exitHANZIMode()
    }
}

func enterHANZIMode() {
    self.writeData(NSData(bytes: \[UInt8(0x1C), UInt8(0x26)\], length: 2))
}
func exitHANZIMode() {
    self.writeData(NSData(bytes: \[UInt8(0x1C), UInt8(0x2E)\], length: 2))
}

```
