---
title: 'iOS 单一字体参数和绘制位置说明'
date: Tue, 21 Mar 2017 11:21:30 +0000
draft: false
tags: ['iOS']
---

**测试环境** : Xcode 7.3 / iPhone Simulator 6 / swift 2.2  
**测试字体**: 系统常规字体，40字号  
**显示效果(带注释)**: [![Slice 2](http://www.karsa.info/blog/wp-content/uploads/2017/03/Slice-2-300x90.png)](http://www.karsa.info/blog/wp-content/uploads/2017/03/Slice-2.png)  **字体信息:**
```

lineH : 47.734375 
dse : -9.6484375
ase: 38.0859375 
cap : 28.18359375
xHeight : 21.0546875 

```
**测试代码:**
```

class ViewController : UIViewController, UIScrollViewDelegate {
    override func loadView() {
        super.loadView()
        view.backgroundColor = UIColor.whiteColor()

        let fontView = FontView()
        view.addSubview(fontView)
        fontView.frame = CGRectMake(0, 100, 375, 400)

        print("lineH : \(fontView.font.lineHeight) \ndse : \(fontView.font.descender)\nase: \(fontView.font.ascender) \ncap : \(fontView.font.capHeight)\nxHeight : \(fontView.font.xHeight)")
    }
}

class FontView : UIView {
    let font = UIFont.systemFontOfSize(40)
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)

        let rect = CGRectMake(5, 100, 365, 200)
        let rectpath = UIBezierPath(rect: rect)
        rectpath.lineWidth = 0.5
        UIColor.redColor().setStroke()
        rectpath.stroke()

        ("abcdfJjx啊哈哈\nabcdfJjx啊哈哈" as NSString).drawInRect(rect, withAttributes: [NSFontAttributeName:font,NSForegroundColorAttributeName:UIColor.blueColor()])

        var yPosition = [CGFloat]()
        for i in 1...2 {
            let bottom = font.lineHeight*CGFloat(i)
            yPosition.append(bottom)

            let base = bottom+font.descender
            yPosition.append(base)

            let cap = base-font.capHeight
            yPosition.append(cap)

            let xLeter = base-font.xHeight
            yPosition.append(xLeter)
        }
        let linesPath = UIBezierPath()
        for y in yPosition {
            let yPosition = y+100.0
            linesPath.moveToPoint(CGPoint(x: 5, y: yPosition))
            linesPath.addLineToPoint(CGPoint(x: 370, y: yPosition))
        }
        UIColor.greenColor().setStroke()
        linesPath.lineWidth = 0.5
        linesPath.stroke()
    }
} 

```
