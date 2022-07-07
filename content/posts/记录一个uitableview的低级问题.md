---
title: '记录一个UITableView的低级问题'
date: Wed, 14 Sep 2016 05:33:25 +0000
draft: false
tags: ['iOS', '瞎逼逼']
---

背景
--

为了简便写了一个UITableView的子类，自己实现自己的delegatw datasource,对外提供items作为设置数据的方法，每个数据需要实现一些protocol方法来提供cell的创建和配置，以及选择时候的操作。

错误
--

在实现的时候错误把 UITableViewDataSource 的实现: `- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;` 写成了对 UITableView的方法的覆盖: `- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;` 然后发现，每次当tableview的section>1的时候就会crash

抛出的异常
-----

`2016-09-14 13:23:26.839 TestiOS[47251:6146065] *** Assertion failure in -[UITableViewRowData rectForHeaderInSection:heightCanBeGuessed:], /BuildRoot/Library/Caches/com.apple.xbs/Sources/UIKit_Sim/UIKit-3512.60.7/UITableViewRowData.m:1746 2016-09-14 13:23:31.459 TestiOS[47251:6146065] *** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'request for rect of header in invalid section (1)' *** First throw call stack: ( 0 CoreFoundation 0x000000010dfb8d85 __exceptionPreprocess + 165 1 libobjc.A.dylib 0x000000010bf28deb objc_exception_throw + 48 2 CoreFoundation 0x000000010dfb8bea +[NSException raise:format:arguments:] + 106 3 Foundation 0x000000010bb72d5a -[NSAssertionHandler handleFailureInMethod:object:file:lineNumber:description:] + 198 4 UIKit 0x000000010c6f5921 -[UITableViewRowData rectForHeaderInSection:heightCanBeGuessed:] + 272 5 UIKit 0x000000010c4d15d1 -[UITableView rectForHeaderInSection:] + 72 6 UIKit 0x000000010c4ef24d -[UITableView _hasHeaderFooterBelowRowAtIndexPath:] + 362 7 UIKit 0x000000010c4d659c -[UITableView _shouldDrawSeparatorAtBottomOfSection:] + 115 8 UIKit 0x000000010c4eaef0 -[UITableView _setupCell:forEditing:atIndexPath:canEdit:editingStyle:shouldIndentWhileEditing:showsReorderControl:accessoryType:animated:updateSeparators:] + 1349 9 UIKit 0x000000010c4eb16c -[UITableView _setupCell:forEditing:atIndexPath:animated:updateSeparators:] + 531 10 UIKit 0x000000010c4e059e __53-[UITableView _configureCellForDisplay:forIndexPath:]_block_invoke + 4058 11 UIKit 0x000000010c43d680 +[UIView(Animation) performWithoutAnimation:] + 65 12 UIKit 0x000000010c4df5ab -[UITableView _configureCellForDisplay:forIndexPath:] + 475 13 UIKit 0x000000010c4eb51e -[UITableView _createPreparedCellForGlobalRow:withIndexPath:willDisplay:] + 808 14 UIKit 0x000000010c4eb62c -[UITableView _createPreparedCellForGlobalRow:willDisplay:] + 74 15 UIKit 0x000000010c4bfd4f -[UITableView _updateVisibleCellsNow:isRecursive:] + 2996 16 UIKit 0x000000010c4f4686 -[UITableView _performWithCachedTraitCollection:] + 92 17 UIKit 0x000000010c4db344 -[UITableView layoutSubviews] + 224 18 UIKit 0x000000010c448980 -[UIView(CALayerDelegate) layoutSublayersOfLayer:] + 703 19 QuartzCore 0x0000000112a94c00 -[CALayer layoutSublayers] + 146 20 QuartzCore 0x0000000112a8908e _ZN2CA5Layer16layout_if_neededEPNS_11TransactionE + 366 21 QuartzCore 0x0000000112a88f0c _ZN2CA5Layer28layout_and_display_if_neededEPNS_11TransactionE + 24 22 QuartzCore 0x0000000112a7d3c9 _ZN2CA7Context18commit_transactionEPNS_11TransactionE + 277 23 QuartzCore 0x0000000112aab086 _ZN2CA11Transaction6commitEv + 486 24 QuartzCore 0x0000000112aab7f8 _ZN2CA11Transaction17observer_callbackEP19__CFRunLoopObservermPv + 92 25 CoreFoundation 0x000000010deddc37 __CFRUNLOOP_IS_CALLING_OUT_TO_AN_OBSERVER_CALLBACK_FUNCTION__ + 23 26 CoreFoundation 0x000000010deddba7 __CFRunLoopDoObservers + 391 27 CoreFoundation 0x000000010ded37fb __CFRunLoopRun + 1147 28 CoreFoundation 0x000000010ded30f8 CFRunLoopRunSpecific + 488 29 GraphicsServices 0x0000000112935ad2 GSEventRunModal + 161 30 UIKit 0x000000010c38df09 UIApplicationMain + 171 31 TestiOS 0x000000010b692b62 main + 114 32 libdyld.dylib 0x000000010e74d92d start + 1 33 ??? 0x0000000000000001 0x0 + 1 ) libc++abi.dylib: terminating with uncaught exception of type NSException`

如何避免这种问题出现
----------

1.  对UITableView的各个方法不够熟悉
2.  在实现的时候没有认真对比方法名字
3.  在发现控件使用方式没有问题，就应该是控件有问题；控件方法实现没有问题，就应该是方法名字有问题了，当时的分析不够准确，没有真正冷静的看待问题，而是直接去查google，看别人是否碰到同样的问题。