//
//  ViewController.h
//  EmptyTableData
//
//  Created by 张冠清 on 16/5/26.
//  Copyright © 2016年 张冠清. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController<UITableViewDelegate,UITableViewDataSource>
@property (strong, nonatomic) UITableView *testTable;

@end

