//
//  ViewController.m
//  EmptyTableData
//
//  Created by 张冠清 on 16/5/26.
//  Copyright © 2016年 张冠清. All rights reserved.
//

#import "UIColor+Hexadecimal.h"
#import "UIScrollView+EmptyDataSet.h"
#import "ViewController.h"
@interface ViewController () <EmptyDataSetSource, EmptyDataSetDelegate> {
    BOOL bol;
}
@property (nonatomic, getter=isLoading) BOOL loading;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"TableView Test";
    self.testTable = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    self.testTable.delegate = self;
    self.testTable.dataSource = self;
    self.testTable.emptyDataSetDelegate = self;
    self.testTable.emptyDataSetSource = self;
    self.testTable.separatorStyle = UITableViewCellStyleDefault;
    [self.view addSubview:self.testTable];

    UIBarButtonItem *rightItem =
    [[UIBarButtonItem alloc] initWithTitle:@"变更数据" style:(UIBarButtonItemStyleDone) target:self action:@selector(test)];
    self.navigationItem.rightBarButtonItem = rightItem;
}
#pragma mark - button click method
- (void)test {
    if (bol == NO) {
        bol = YES;
        [self.testTable reloadData];
    } else {
        bol = NO;
        [self.testTable reloadData];
    }
}
- (void)setLoading:(BOOL)loading {
    if (self.isLoading == loading) {
        return;
    }
    _loading = loading;
    [self.testTable reloadEmptyDataSet];
}
#pragma mark - UITableViewDataSource Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (bol == YES) {
        return 40;
    } else
        return 0;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    cell.textLabel.text = @"测试数据";
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}
#pragma mark - EmptyDataSetSource Methods
- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *text = @"No Messages";
    UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light" size:22.0];
    UIColor *textColor = [UIColor colorWithHex:@"c9c9c9"];
    NSMutableDictionary *attributes = [NSMutableDictionary new];
    [attributes setObject:font forKey:NSFontAttributeName];
    [attributes setObject:textColor forKey:NSForegroundColorAttributeName];
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}
- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *text = @"When you have messages, you’ll see them here.";
    UIFont *font = [UIFont systemFontOfSize:13.0];
    UIColor *textColor = [UIColor colorWithHex:@"cfcfcf"];
    NSMutableDictionary *attributes = [NSMutableDictionary new];
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;
    paragraph.lineSpacing = 4.0;
    [attributes setObject:textColor forKey:NSForegroundColorAttributeName];
    [attributes setObject:font forKey:NSFontAttributeName];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text attributes:attributes];
    return attributedString;
}
- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    if (self.isLoading) {
        return [UIImage imageNamed:@"loading_imgBlue_78x78"];
    } else {
        NSString *imageName = [NSString stringWithFormat:@"placeholder_airbnb"];
        return [UIImage imageNamed:imageName];
    }
}
- (CAAnimation *)imageAnimationForEmptyDataSet:(UIScrollView *)scrollView {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
    animation.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
    animation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(M_PI_2, 0.0, 0.0, 1.0)];
    animation.duration = 0.25;
    animation.cumulative = YES;
    animation.repeatCount = MAXFLOAT;

    return animation;
}
- (NSAttributedString *)buttonTitleForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state {
    NSString *text = @"Continue";
    UIFont *font = [UIFont boldSystemFontOfSize:17.0];
    UIColor *textColor = [UIColor colorWithHex:(state == UIControlStateNormal) ? @"007ee5" : @"48a1ea"];
    NSMutableDictionary *attributes = [NSMutableDictionary new];
    [attributes setObject:font forKey:NSFontAttributeName];
    [attributes setObject:textColor forKey:NSForegroundColorAttributeName];
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView {
    return 0.0;
}
- (CGFloat)spaceHeightForEmptyDataSet:(UIScrollView *)scrollView {
    return 24.0f;
}
#pragma mark - EmptyDataSetDelegate Methods

- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView {
    return YES;
}

- (BOOL)emptyDataSetShouldAllowTouch:(UIScrollView *)scrollView {
    return YES;
}

- (BOOL)emptyDataSetShouldAllowScroll:(UIScrollView *)scrollView {
    return YES;
}

- (BOOL)emptyDataSetShouldAnimateImageView:(UIScrollView *)scrollView {
    return self.isLoading;
}

- (void)emptyDataSet:(UIScrollView *)scrollView didTapView:(UIView *)view {
    self.loading = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.loading = NO;
        if (bol == NO) {
            bol = YES;
            [self.testTable reloadData];
        } else {
            bol = NO;
            [self.testTable reloadData];
        }
    });
}

- (void)emptyDataSet:(UIScrollView *)scrollView didTapButton:(UIButton *)button {
    self.loading = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.loading = NO;
        if (bol == NO) {
            bol = YES;
            [self.testTable reloadData];
        } else {
            bol = NO;
            [self.testTable reloadData];
        }
    });
}

#pragma mark - View Auto-Rotation

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate {
    return NO;
}

#pragma mark - View Auto-Rotation

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
}

@end
