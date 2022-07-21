---
title: 'iOS8 bug for UITableView'
date: Fri, 14 Jul 2017 03:14:20 +0000
draft: false
tags: ['iOS']
---

Env Config
----------

> Xcode8.3.2 iOS8.1 Swift3.1

App初始化结构: App->Window->UINavigationController->(UITableViewController \* TableViewController)

Problem
-------

点击cell进入下个页面后，点击nav back返回，会发现Cell的高度，从第二行开始会有错误，第二行显示第一行的高度，第三行显示第二行的，后面以此类推。

### Reason

TableView 在重新显示的时候，会计算高度、contentSize，然后重新layout，这时候需要对cell高度进行调用，这里的调用错位(从第二个cell开始的row都错误的减1)。在第一次显示的时候也有这个问题，但后续的reloadData调用路径上并没有这个bug。

### 修复

可以在didMoveToWindow后，额外调用一次reloadData方法修复这个问题。可以用使用UITableView的子类，也可以直接使用Method Swizzle 解决这个问题。

Sample Code
-----------


```

//
//  TableViewController.swift
//  Xcode8TestSwift_iOS
//
//  Created by karsa on 2017/7/13.
//  Copyright © 2017年 karsa. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {

    var cellHeights : [Float] = [120,40,100,23,40]

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")
        navigationController?.navigationBar.barTintColor = .white
        navigationController?.navigationBar.isTranslucent = false
    }

    func showPicker() {
        let picker = UIPickerView()
        picker.backgroundColor = UIColor.red
        view.addSubview(picker)
        picker.frame = CGRect(x: 0, y: 10, width: 200, height: 200)

        let tmpView = UIView()
        tmpView.backgroundColor = .green
        view.addSubview(tmpView)
        tmpView.frame = CGRect(x: 210, y: 10, width: 100, height: 200)
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellHeights.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier")
        return cell!
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let height = CGFloat(cellHeights[indexPath.row])
        print("\(indexPath) : \(height)")
        return height
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.navigationController?.pushViewController(ViewController(), animated: true)
        showPicker()
    }

} 

```
