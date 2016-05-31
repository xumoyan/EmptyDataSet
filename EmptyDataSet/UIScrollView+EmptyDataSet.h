//
//  UIScrollView+EmptyDataSet.h
//  源代码地址https://github.com/dzenbot/DZNEmptyDataSet
//  修改代码地址：https://github.com/xumoyan/EmptyDataSet
//  相对于源代码主要对实际运用的时候产生的一些小问题进行了一些修改
//  第一个问题：tableView滑动，数据再次为空的时候，展示View下移修改在.m文件94行，固定了View坐标
//  第二个问题：在iOS7系统当中按钮点击无响应。修改在437行，将emptyView添加到wrapperView上一层。
//  修改过之后相对来说比较完整一些，主要是一些小细节的问题。
//  如果你在使用的过程中发现了其他的问题，请联系QQ：2326470896。

#import <UIKit/UIKit.h>

@protocol EmptyDataSetSource;
@protocol EmptyDataSetDelegate;

#define DZNEmptyDataSetDeprecated(instead) DEPRECATED_MSG_ATTRIBUTE(" Use " #instead " instead")

/**
 在UITableView/UICollectionView数据为空的时候，展示一个提示性的View。
 它会自动的根据数据是否为空来展示或者不展示这个提示性的View，前提是你遵循了EmptyDataSetSource代理。
 */
@interface UIScrollView (EmptyDataSet)
/** UITableView/UICollectionView的数据源 */
@property (nonatomic, weak) id<EmptyDataSetSource> emptyDataSetSource;
/** UITableView/UICollectionView的代理 */
@property (nonatomic, weak) id<EmptyDataSetDelegate> emptyDataSetDelegate;
/** View隐藏或者可见的判断依据 */
@property (nonatomic, readonly, getter=isEmptyDataSetVisible) BOOL emptyDataSetVisible;

/**
 重新获取UITableView/UICollectionView的数据源。使用这个方法迫使所有的数据刷新。和reloaddata相似，但是这个是对数据源的重新加载，而不是对整个表示图或者集合视图的加载。
 */
- (void)reloadEmptyDataSet;

@end

/**
 获取对象的数据源。必须遵循EmptyDataSetSource协议。数据源不进行保留。所有的代理方法都是可选的。
 */
@protocol EmptyDataSetSource <NSObject>
@optional

/**
 返回一个提示标题。
 */
- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView;

/**
 返回一个详细的提示信息。
 */
- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView;

/**
 返回一个提示图片。
 */
- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView;

/**
 返回一个图片的渲染颜色。
 */
- (UIColor *)imageTintColorForEmptyDataSet:(UIScrollView *)scrollView;

/**
 返回点击图片触发动画效果（动画添加到imageView的layer上）。
 */
- (CAAnimation *)imageAnimationForEmptyDataSet:(UIScrollView *)scrollView;

/**
 返回按钮标题的字体样式和按钮状态。
 */
- (NSAttributedString *)buttonTitleForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state;

/**
 返回按钮图片和按钮状态。
 */
- (UIImage *)buttonImageForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state;

/**
 返回按钮的背景图片和按钮的状态。
 */
- (UIImage *)buttonBackgroundImageForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state;

/**
 返回背景View的颜色（emptyDataSetView）。
 */
- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView;

/**
 返回一个自定义的视图（添加在contentView上）。
 */
- (UIView *)customViewForEmptyDataSet:(UIScrollView *)scrollView;

/**
 自定义视图的水平和垂直偏移。（默认是CGPointZero）
 */
- (CGPoint)offsetForEmptyDataSet:(UIScrollView *)scrollView DZNEmptyDataSetDeprecated(-verticalOffsetForEmptyDataSet:);
- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView;

/**
 标题和详细信息等之间垂直的间距。
 */
- (CGFloat)spaceHeightForEmptyDataSet:(UIScrollView *)scrollView;

@end

/**
 空数据对象的代理。代理不保留。所有的代理方法都是可选的。
 */
@protocol EmptyDataSetDelegate <NSObject>
@optional

/**
 空数据View展示的时候是否需要淡入的效果。默认是的。
 */
- (BOOL)emptyDataSetShouldFadeIn:(UIScrollView *)scrollView;

/**
 当数据不为空的时候，强迫显示View，而不展示数据。
 */
- (BOOL)emptyDataSetShouldBeForcedToDisplay:(UIScrollView *)scrollView;

/**
 数据为空的时候，是否应该渲染和展示。默认是的。
 */
- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView;

/**
 数据为空的时候是否接收触控手势。
 */
- (BOOL)emptyDataSetShouldAllowTouch:(UIScrollView *)scrollView;

/**
 UITableView/UICollectionView展示View的时候是否是可滚动的。
 */
- (BOOL)emptyDataSetShouldAllowScroll:(UIScrollView *)scrollView;

/**
 imageView的layer上的动画是否是可点击的。默认是的。
 */
- (BOOL)emptyDataSetShouldAnimateImageView:(UIScrollView *)scrollView;

/**
 点击手势触发的方法。
 */
- (void)emptyDataSetDidTapView:(UIScrollView *)scrollView DZNEmptyDataSetDeprecated(-emptyDataSet:didTapView:);

/**
 告诉对象点击了按钮。
 */
- (void)emptyDataSetDidTapButton:(UIScrollView *)scrollView DZNEmptyDataSetDeprecated(-emptyDataSet:didTapButton:);

/**
 点击手势触发的方法。
 */
- (void)emptyDataSet:(UIScrollView *)scrollView didTapView:(UIView *)view;

/**
 告诉对象点击按钮了。
 */
- (void)emptyDataSet:(UIScrollView *)scrollView didTapButton:(UIButton *)button;

/**
 告诉对象数据为空，View将要展现。
 */
- (void)emptyDataSetWillAppear:(UIScrollView *)scrollView;

/**
 告诉对象出现了空的数据源。
 */
- (void)emptyDataSetDidAppear:(UIScrollView *)scrollView;

/**
 告诉对象数据源现在不为空，View将要消失。
 */
- (void)emptyDataSetWillDisappear:(UIScrollView *)scrollView;

/**
 告诉对象数据源已经不为空。
 */
- (void)emptyDataSetDidDisappear:(UIScrollView *)scrollView;

@end

#undef DZNEmptyDataSetDeprecated
