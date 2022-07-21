---
title: 'SnapKit 3 updateConstraints crash  with EXC_BAD_ACCESS(code=EXC_i386_GPFLT)'
date: Mon, 24 Apr 2017 08:33:20 +0000
draft: false
tags: ['iOS']
---

测试环境： Xcode 8.2.1 iOS 10.2 SnapKit 3.2.0 现象: 在使用 updateConstraints 来更新view的位置的时候crash。原因应该是调用removeFromSuperview的时候没有同步移除约束，造成野指针访问已经释放的内存。 测试代码:
```

class ViewController: UIViewController {

    var testView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()

        let button = UIButton()
        button.backgroundColor = UIColor.gray
        view.addSubview(button)
        button.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 100, height: 100))
            make.bottom.equalTo(-20)
        }
        button.addTarget(self, action: #selector(ViewController.update), for: UIControlEvents.touchUpInside)
    }

    func update() {
        if testView.superview == nil {
            let container = UIView()
            container.backgroundColor = UIColor.init(white: 0, alpha: 0.45)
            view.addSubview(container)
            container.snp.makeConstraints({ (make) in
                make.edges.equalTo(UIEdgeInsetsMake(0, 0, 200, 0))
            })
            testView.backgroundColor = UIColor.red
            container.addSubview(testView)
            testView.snp.makeConstraints { (make) in
                make.left.right.equalTo(0)
                make.height.equalTo(100)
                make.top.equalTo(-100)
            }
            self.view.layoutIfNeeded()

            testView.snp.updateConstraints { (make) in
                make.top.equalTo(0)
            }
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
        } else {
            testView.snp.updateConstraints { (make) in
                make.top.equalTo(-100)
            }
            UIView.animate(withDuration: 0.25, animations: {
                self.view.layoutIfNeeded()
            }, completion: { (_) in
                self.testView.superview?.removeFromSuperview()
                self.testView.removeFromSuperview()
            })
        }
    }
} 

```
在 `testView.snp.updateConstraints` 的时候crash，但使用这个调用有两个地方，并不一定在哪个调用点挂。调用堆堆栈如下:
```

1. ConstraintViewDSL -> updateConstraints 
2. ConstraintMaker -> updateConstraints 
    ...
    for constraint in constraints {
        constraint.activateIfNeeded(updatingExisting: true)
    }
    ...
3. Constraint ->  activateIfNeeded
    ...
    for layoutConstraint in layoutConstraints {
        let existingLayoutConstraint = existingLayoutConstraints.first { $0 == layoutConstraint } // Call == func on step 5
        guard let updateLayoutConstraint = existingLayoutConstraint else {
            fatalError("Updated constraint could not find existing matching constraint to update: \(layoutConstraint)")
        }

        let updateLayoutAttribute = (updateLayoutConstraint.secondAttribute == .notAnAttribute) ? updateLayoutConstraint.firstAttribute : updateLayoutConstraint.secondAttribute
        updateLayoutConstraint.constant = self.constant.constraintConstantTargetValueFor(layoutAttribute: updateLayoutAttribute)
    }
    ...
4. LayoutConstraint.swift 
    internal func ==(lhs: LayoutConstraint, rhs: LayoutConstraint) -> Bool {
        guard lhs.firstItem === rhs.firstItem && // Crashed Here with EXC_BAD_ACCESS(code=EXC_i386_GPFLT)
            lhs.secondItem === rhs.secondItem &&
            lhs.firstAttribute == rhs.firstAttribute &&
            lhs.secondAttribute == rhs.secondAttribute &&
            lhs.relation == rhs.relation &&
            lhs.priority == rhs.priority &&
            lhs.multiplier == rhs.multiplier else {
            return false
        }
        return true
    } 

```
当前可以把 `testView.snp.makeConstraints` 改成 `testView.snp.makeConstraints` 来规避这个问题。 已经在github上snapkit的issue中向作者给出这个内容了，希望能早日修复。