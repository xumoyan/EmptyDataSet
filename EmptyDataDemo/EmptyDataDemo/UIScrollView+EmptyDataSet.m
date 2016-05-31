//
//  UIScrollView+EmptyDataSet.m
//  源代码地址https://github.com/dzenbot/DZNEmptyDataSet
//  修改代码地址：https://github.com/xumoyan/EmptyDataSet
//  相对于源代码主要对实际运用的时候产生的一些小问题进行了一些修改
//  第一个问题：tableView滑动，数据再次为空的时候，展示View下移修改在.m文件94行，固定了View坐标
//  第二个问题：在iOS7系统当中按钮点击无响应。修改在437行，将emptyView添加到wrapperView上一层。
//  修改过之后相对来说比较完整一些，主要是一些小细节的问题。
//  如果你在使用的过程中发现了其他的问题，请联系QQ：2326470896。

#import "UIScrollView+EmptyDataSet.h"
#import <objc/runtime.h>

@interface UIView (DZNConstraintBasedLayoutExtensions)

- (NSLayoutConstraint *)equallyRelatedConstraintWithView:(UIView *)view attribute:(NSLayoutAttribute)attribute;

@end

@interface DZNWeakObjectContainer : NSObject

@property (nonatomic, readonly, weak) id weakObject;

- (instancetype)initWithWeakObject:(id)object;

@end

@interface DZNEmptyDataSetView : UIView

@property (nonatomic, readonly) UIView *contentView;
@property (nonatomic, readonly) UILabel *titleLabel;
@property (nonatomic, readonly) UILabel *detailLabel;
@property (nonatomic, readonly) UIImageView *imageView;
@property (nonatomic, readonly) UIButton *button;
@property (nonatomic, strong) UIView *customView;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;

@property (nonatomic, assign) CGFloat verticalOffset;
@property (nonatomic, assign) CGFloat verticalSpace;

@property (nonatomic, assign) BOOL fadeInOnDisplay;

- (void)setupConstraints;
- (void)prepareForReuse;

@end

#pragma mark - UIScrollView+EmptyDataSet

static char const *const kEmptyDataSetSource = "emptyDataSetSource";
static char const *const kEmptyDataSetDelegate = "emptyDataSetDelegate";
static char const *const kEmptyDataSetView = "emptyDataSetView";

#define kEmptyImageViewAnimationKey @"com.dzn.emptyDataSet.imageViewAnimation"

@interface UIScrollView () <UIGestureRecognizerDelegate>
@property (nonatomic, readonly) DZNEmptyDataSetView *emptyDataSetView;
@end

@implementation UIScrollView (DZNEmptyDataSet)
#pragma mark - Getters (Public)

- (id<EmptyDataSetSource>)emptyDataSetSource {
    DZNWeakObjectContainer *container = objc_getAssociatedObject(self, kEmptyDataSetSource);
    return container.weakObject;
}

- (id<EmptyDataSetDelegate>)emptyDataSetDelegate {
    DZNWeakObjectContainer *container = objc_getAssociatedObject(self, kEmptyDataSetDelegate);
    return container.weakObject;
}

- (BOOL)isEmptyDataSetVisible {
    UIView *view = objc_getAssociatedObject(self, kEmptyDataSetView);
    return view ? !view.hidden : NO;
}

#pragma mark - Getters (Private)

- (DZNEmptyDataSetView *)emptyDataSetView {
    DZNEmptyDataSetView *view = objc_getAssociatedObject(self, kEmptyDataSetView);

    if (!view) {
        view = [DZNEmptyDataSetView new];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        view.hidden = YES;

        view.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dzn_didTapContentView:)];
        view.tapGesture.delegate = self;
        [view addGestureRecognizer:view.tapGesture];

        [self setEmptyDataSetView:view];
    }
    view.frame = CGRectMake(0, 0, view.frame.size.width, view.frame.size.height);
    return view;
}

- (BOOL)dzn_canDisplay {
    if (self.emptyDataSetSource && [self.emptyDataSetSource conformsToProtocol:@protocol(EmptyDataSetSource)]) {
        if ([self isKindOfClass:[UITableView class]] || [self isKindOfClass:[UICollectionView class]] ||
            [self isKindOfClass:[UIScrollView class]]) {
            return YES;
        }
    }

    return NO;
}

- (NSInteger)dzn_itemsCount {
    NSInteger items = 0;

    // 没有对应的数据源，退出。
    if (![self respondsToSelector:@selector(dataSource)]) {
        return items;
    }

    // UITableView 支持
    if ([self isKindOfClass:[UITableView class]]) {

        UITableView *tableView = (UITableView *)self;
        id<UITableViewDataSource> dataSource = tableView.dataSource;

        NSInteger sections = 1;

        if (dataSource && [dataSource respondsToSelector:@selector(numberOfSectionsInTableView:)]) {
            sections = [dataSource numberOfSectionsInTableView:tableView];
        }

        if (dataSource && [dataSource respondsToSelector:@selector(tableView:numberOfRowsInSection:)]) {
            for (NSInteger section = 0; section < sections; section++) {
                items += [dataSource tableView:tableView numberOfRowsInSection:section];
            }
        }
    }
    // UICollectionView 支持
    else if ([self isKindOfClass:[UICollectionView class]]) {

        UICollectionView *collectionView = (UICollectionView *)self;
        id<UICollectionViewDataSource> dataSource = collectionView.dataSource;

        NSInteger sections = 1;

        if (dataSource && [dataSource respondsToSelector:@selector(numberOfSectionsInCollectionView:)]) {
            sections = [dataSource numberOfSectionsInCollectionView:collectionView];
        }

        if (dataSource && [dataSource respondsToSelector:@selector(collectionView:numberOfItemsInSection:)]) {
            for (NSInteger section = 0; section < sections; section++) {
                items += [dataSource collectionView:collectionView numberOfItemsInSection:section];
            }
        }
    }

    return items;
}

#pragma mark - Data Source Getters

- (NSAttributedString *)dzn_titleLabelString {
    if (self.emptyDataSetSource && [self.emptyDataSetSource respondsToSelector:@selector(titleForEmptyDataSet:)]) {
        NSAttributedString *string = [self.emptyDataSetSource titleForEmptyDataSet:self];
        if (string)
            NSAssert([string isKindOfClass:[NSAttributedString class]],
                     @"You must return a valid NSAttributedString object for -titleForEmptyDataSet:");
        return string;
    }
    return nil;
}

- (NSAttributedString *)dzn_detailLabelString {
    if (self.emptyDataSetSource && [self.emptyDataSetSource respondsToSelector:@selector(descriptionForEmptyDataSet:)]) {
        NSAttributedString *string = [self.emptyDataSetSource descriptionForEmptyDataSet:self];
        if (string)
            NSAssert([string isKindOfClass:[NSAttributedString class]],
                     @"You must return a valid NSAttributedString object for -descriptionForEmptyDataSet:");
        return string;
    }
    return nil;
}

- (UIImage *)dzn_image {
    if (self.emptyDataSetSource && [self.emptyDataSetSource respondsToSelector:@selector(imageForEmptyDataSet:)]) {
        UIImage *image = [self.emptyDataSetSource imageForEmptyDataSet:self];
        if (image)
            NSAssert([image isKindOfClass:[UIImage class]],
                     @"You must return a valid UIImage object for -imageForEmptyDataSet:");
        return image;
    }
    return nil;
}

- (CAAnimation *)dzn_imageAnimation {
    if (self.emptyDataSetSource && [self.emptyDataSetSource respondsToSelector:@selector(imageAnimationForEmptyDataSet:)]) {
        CAAnimation *imageAnimation = [self.emptyDataSetSource imageAnimationForEmptyDataSet:self];
        if (imageAnimation)
            NSAssert([imageAnimation isKindOfClass:[CAAnimation class]],
                     @"You must return a valid CAAnimation object for -imageAnimationForEmptyDataSet:");
        return imageAnimation;
    }
    return nil;
}

- (UIColor *)dzn_imageTintColor {
    if (self.emptyDataSetSource && [self.emptyDataSetSource respondsToSelector:@selector(imageTintColorForEmptyDataSet:)]) {
        UIColor *color = [self.emptyDataSetSource imageTintColorForEmptyDataSet:self];
        if (color)
            NSAssert([color isKindOfClass:[UIColor class]],
                     @"You must return a valid UIColor object for -imageTintColorForEmptyDataSet:");
        return color;
    }
    return nil;
}

- (NSAttributedString *)dzn_buttonTitleForState:(UIControlState)state {
    if (self.emptyDataSetSource &&
        [self.emptyDataSetSource respondsToSelector:@selector(buttonTitleForEmptyDataSet:forState:)]) {
        NSAttributedString *string = [self.emptyDataSetSource buttonTitleForEmptyDataSet:self forState:state];
        if (string)
            NSAssert([string isKindOfClass:[NSAttributedString class]],
                     @"You must return a valid NSAttributedString object for -buttonTitleForEmptyDataSet:forState:");
        return string;
    }
    return nil;
}

- (UIImage *)dzn_buttonImageForState:(UIControlState)state {
    if (self.emptyDataSetSource &&
        [self.emptyDataSetSource respondsToSelector:@selector(buttonImageForEmptyDataSet:forState:)]) {
        UIImage *image = [self.emptyDataSetSource buttonImageForEmptyDataSet:self forState:state];
        if (image)
            NSAssert([image isKindOfClass:[UIImage class]],
                     @"You must return a valid UIImage object for -buttonImageForEmptyDataSet:forState:");
        return image;
    }
    return nil;
}

- (UIImage *)dzn_buttonBackgroundImageForState:(UIControlState)state {
    if (self.emptyDataSetSource &&
        [self.emptyDataSetSource respondsToSelector:@selector(buttonBackgroundImageForEmptyDataSet:forState:)]) {
        UIImage *image = [self.emptyDataSetSource buttonBackgroundImageForEmptyDataSet:self forState:state];
        if (image)
            NSAssert([image isKindOfClass:[UIImage class]],
                     @"You must return a valid UIImage object for -buttonBackgroundImageForEmptyDataSet:forState:");
        return image;
    }
    return nil;
}

- (UIColor *)dzn_dataSetBackgroundColor {
    if (self.emptyDataSetSource && [self.emptyDataSetSource respondsToSelector:@selector(backgroundColorForEmptyDataSet:)]) {
        UIColor *color = [self.emptyDataSetSource backgroundColorForEmptyDataSet:self];
        if (color)
            NSAssert([color isKindOfClass:[UIColor class]],
                     @"You must return a valid UIColor object for -backgroundColorForEmptyDataSet:");
        return color;
    }
    return [UIColor clearColor];
}

- (UIView *)dzn_customView {
    if (self.emptyDataSetSource && [self.emptyDataSetSource respondsToSelector:@selector(customViewForEmptyDataSet:)]) {
        UIView *view = [self.emptyDataSetSource customViewForEmptyDataSet:self];
        if (view)
            NSAssert([view isKindOfClass:[UIView class]],
                     @"You must return a valid UIView object for -customViewForEmptyDataSet:");
        return view;
    }
    return nil;
}

- (CGFloat)dzn_verticalOffset {
    CGFloat offset = 0.0;

    if (self.emptyDataSetSource && [self.emptyDataSetSource respondsToSelector:@selector(verticalOffsetForEmptyDataSet:)]) {
        offset = [self.emptyDataSetSource verticalOffsetForEmptyDataSet:self];
    }
    return offset;
}

- (CGFloat)dzn_verticalSpace {
    if (self.emptyDataSetSource && [self.emptyDataSetSource respondsToSelector:@selector(spaceHeightForEmptyDataSet:)]) {
        return [self.emptyDataSetSource spaceHeightForEmptyDataSet:self];
    }
    return 0.0;
}

#pragma mark - Delegate Getters & Events (Private)

- (BOOL)dzn_shouldFadeIn {
    if (self.emptyDataSetDelegate && [self.emptyDataSetDelegate respondsToSelector:@selector(emptyDataSetShouldFadeIn:)]) {
        return [self.emptyDataSetDelegate emptyDataSetShouldFadeIn:self];
    }
    return YES;
}

- (BOOL)dzn_shouldDisplay {
    if (self.emptyDataSetDelegate && [self.emptyDataSetDelegate respondsToSelector:@selector(emptyDataSetShouldDisplay:)]) {
        return [self.emptyDataSetDelegate emptyDataSetShouldDisplay:self];
    }
    return YES;
}

- (BOOL)dzn_shouldBeForcedToDisplay {
    if (self.emptyDataSetDelegate && [self.emptyDataSetDelegate respondsToSelector:@selector(emptyDataSetShouldBeForcedToDisplay:)]) {
        return [self.emptyDataSetDelegate emptyDataSetShouldBeForcedToDisplay:self];
    }
    return NO;
}

- (BOOL)dzn_isTouchAllowed {
    if (self.emptyDataSetDelegate && [self.emptyDataSetDelegate respondsToSelector:@selector(emptyDataSetShouldAllowTouch:)]) {
        return [self.emptyDataSetDelegate emptyDataSetShouldAllowTouch:self];
    }
    return YES;
}

- (BOOL)dzn_isScrollAllowed {
    if (self.emptyDataSetDelegate && [self.emptyDataSetDelegate respondsToSelector:@selector(emptyDataSetShouldAllowScroll:)]) {
        return [self.emptyDataSetDelegate emptyDataSetShouldAllowScroll:self];
    }
    return NO;
}

- (BOOL)dzn_isImageViewAnimateAllowed {
    if (self.emptyDataSetDelegate && [self.emptyDataSetDelegate respondsToSelector:@selector(emptyDataSetShouldAnimateImageView:)]) {
        return [self.emptyDataSetDelegate emptyDataSetShouldAnimateImageView:self];
    }
    return NO;
}

- (void)dzn_willAppear {
    if (self.emptyDataSetDelegate && [self.emptyDataSetDelegate respondsToSelector:@selector(emptyDataSetWillAppear:)]) {
        [self.emptyDataSetDelegate emptyDataSetWillAppear:self];
    }
}

- (void)dzn_didAppear {
    if (self.emptyDataSetDelegate && [self.emptyDataSetDelegate respondsToSelector:@selector(emptyDataSetDidAppear:)]) {
        [self.emptyDataSetDelegate emptyDataSetDidAppear:self];
    }
}

- (void)dzn_willDisappear {
    if (self.emptyDataSetDelegate && [self.emptyDataSetDelegate respondsToSelector:@selector(emptyDataSetWillDisappear:)]) {
        [self.emptyDataSetDelegate emptyDataSetWillDisappear:self];
    }
}

- (void)dzn_didDisappear {
    if (self.emptyDataSetDelegate && [self.emptyDataSetDelegate respondsToSelector:@selector(emptyDataSetDidDisappear:)]) {
        [self.emptyDataSetDelegate emptyDataSetDidDisappear:self];
    }
}

- (void)dzn_didTapContentView:(id)sender {
    if (self.emptyDataSetDelegate && [self.emptyDataSetDelegate respondsToSelector:@selector(emptyDataSet:didTapView:)]) {
        [self.emptyDataSetDelegate emptyDataSet:self didTapView:sender];
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    else if (self.emptyDataSetDelegate && [self.emptyDataSetDelegate respondsToSelector:@selector(emptyDataSetDidTapView:)]) {
        [self.emptyDataSetDelegate emptyDataSetDidTapView:self];
    }
#pragma clang diagnostic pop
}

- (void)dzn_didTapDataButton:(id)sender {
    if (self.emptyDataSetDelegate && [self.emptyDataSetDelegate respondsToSelector:@selector(emptyDataSet:didTapButton:)]) {
        [self.emptyDataSetDelegate emptyDataSet:self didTapButton:sender];
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    else if (self.emptyDataSetDelegate && [self.emptyDataSetDelegate respondsToSelector:@selector(emptyDataSetDidTapButton:)]) {
        [self.emptyDataSetDelegate emptyDataSetDidTapButton:self];
    }
#pragma clang diagnostic pop
}

#pragma mark - Setters (Public)

- (void)setEmptyDataSetSource:(id<EmptyDataSetSource>)datasource {
    if (!datasource || ![self dzn_canDisplay]) {
        [self dzn_invalidate];
    }
    objc_setAssociatedObject(self, kEmptyDataSetSource, [[DZNWeakObjectContainer alloc] initWithWeakObject:datasource],
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    // 添加－dzn_reloadData方法，是否实现了reloaddata方法
    [self swizzleIfPossible:@selector(reloadData)];

    // 针对于TableView我们添加了－dzn_reloadData方法和－endUpdates方法
    if ([self isKindOfClass:[UITableView class]]) {
        [self swizzleIfPossible:@selector(endUpdates)];
    }
}

- (void)setEmptyDataSetDelegate:(id<EmptyDataSetDelegate>)delegate {
    if (!delegate) {
        [self dzn_invalidate];
    }

    objc_setAssociatedObject(self, kEmptyDataSetDelegate, [[DZNWeakObjectContainer alloc] initWithWeakObject:delegate],
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Setters (Private)

- (void)setEmptyDataSetView:(DZNEmptyDataSetView *)view {
    objc_setAssociatedObject(self, kEmptyDataSetView, view, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Reload APIs (Public)

- (void)reloadEmptyDataSet {
    [self dzn_reloadEmptyDataSet];
}

#pragma mark - Reload APIs (Private)

- (void)dzn_reloadEmptyDataSet {
    if (![self dzn_canDisplay]) {
        return;
    }

    if (([self dzn_shouldDisplay] && [self dzn_itemsCount] == 0) || [self dzn_shouldBeForcedToDisplay]) {
        // 通知空的数据源将要出现
        [self dzn_willAppear];

        DZNEmptyDataSetView *view = self.emptyDataSetView;

        if (!view.superview) {
            // 本身应该把这个view放在最下边，为了考虑header、footer和sectionHeaders
            //但是在iOS7上会出现问题，现在添加到wrapperView上边
            // 和contentView
            if (([self isKindOfClass:[UITableView class]] || [self isKindOfClass:[UICollectionView class]]) && self.subviews.count > 1) {
                [self insertSubview:view atIndex:1];
            } else {
                [self addSubview:view];
            }
        }

        // 删除视图重置视图及其约束，这是非常重要的（保持一个干净的状态）。
        [view prepareForReuse];

        UIView *customView = [self dzn_customView];

        // 如果customView不为空，使用customView作为View
        if (customView) {
            view.customView = customView;
        } else {
            // 从数据源获取数据
            NSAttributedString *titleLabelString = [self dzn_titleLabelString];
            NSAttributedString *detailLabelString = [self dzn_detailLabelString];

            UIImage *buttonImage = [self dzn_buttonImageForState:UIControlStateNormal];
            NSAttributedString *buttonTitle = [self dzn_buttonTitleForState:UIControlStateNormal];

            UIImage *image = [self dzn_image];
            UIColor *imageTintColor = [self dzn_imageTintColor];
            UIImageRenderingMode renderingMode = imageTintColor ? UIImageRenderingModeAlwaysTemplate : UIImageRenderingModeAlwaysOriginal;

            view.verticalSpace = [self dzn_verticalSpace];

            // 配置图片
            if (image) {
                if ([image respondsToSelector:@selector(imageWithRenderingMode:)]) {
                    view.imageView.image = [image imageWithRenderingMode:renderingMode];
                    view.imageView.tintColor = imageTintColor;
                } else {
                    // 早iOS6之前，插入代码转变成图片，如果需要的话。
                    view.imageView.image = image;
                }
            }

            // 配置标题
            if (titleLabelString) {
                view.titleLabel.attributedText = titleLabelString;
            }

            // 配置详细信息
            if (detailLabelString) {
                view.detailLabel.attributedText = detailLabelString;
            }

            // 配置按钮
            if (buttonImage) {
                [view.button setImage:buttonImage forState:UIControlStateNormal];
                [view.button setImage:[self dzn_buttonImageForState:UIControlStateHighlighted]
                             forState:UIControlStateHighlighted];
            } else if (buttonTitle) {
                [view.button setAttributedTitle:buttonTitle forState:UIControlStateNormal];
                [view.button setAttributedTitle:[self dzn_buttonTitleForState:UIControlStateHighlighted]
                                       forState:UIControlStateHighlighted];
                [view.button setBackgroundImage:[self dzn_buttonBackgroundImageForState:UIControlStateNormal]
                                       forState:UIControlStateNormal];
                [view.button setBackgroundImage:[self dzn_buttonBackgroundImageForState:UIControlStateHighlighted]
                                       forState:UIControlStateHighlighted];
            }
        }

        // 配置偏移量
        view.verticalOffset = [self dzn_verticalOffset];

        // 配置数据为空时候的view
        view.backgroundColor = [self dzn_dataSetBackgroundColor];
        view.hidden = NO;
        view.clipsToBounds = NO;

        // 配置数据为空的时候，是否响应事件。
        view.userInteractionEnabled = [self dzn_isTouchAllowed];

        // 配置显示空View的时候的淡入。
        view.fadeInOnDisplay = [self dzn_shouldFadeIn];

        [view setupConstraints];

        [UIView performWithoutAnimation:^{
            [view layoutIfNeeded];
        }];

        // 配置滚动
        self.scrollEnabled = [self dzn_isScrollAllowed];

        // 配置图片动画
        if ([self dzn_isImageViewAnimateAllowed]) {
            CAAnimation *animation = [self dzn_imageAnimation];

            if (animation) {
                [self.emptyDataSetView.imageView.layer addAnimation:animation forKey:kEmptyImageViewAnimationKey];
            }
        } else if ([self.emptyDataSetView.imageView.layer animationForKey:kEmptyImageViewAnimationKey]) {
            [self.emptyDataSetView.imageView.layer removeAnimationForKey:kEmptyImageViewAnimationKey];
        }

        // 配置数据为空的View将要出现
        [self dzn_didAppear];
    } else if (self.isEmptyDataSetVisible) {
        [self dzn_invalidate];
    }
}

- (void)dzn_invalidate {
    // 通知数据为空的View将要消失
    [self dzn_willDisappear];

    if (self.emptyDataSetView) {
        [self.emptyDataSetView prepareForReuse];
        [self.emptyDataSetView removeFromSuperview];

        [self setEmptyDataSetView:nil];
    }

    self.scrollEnabled = YES;

    // 通知数据为空的View已经消失
    [self dzn_didDisappear];
}

#pragma mark - Method Swizzling

static NSMutableDictionary *_impLookupTable;
static NSString *const DZNSwizzleInfoPointerKey = @"pointer";
static NSString *const DZNSwizzleInfoOwnerKey = @"owner";
static NSString *const DZNSwizzleInfoSelectorKey = @"selector";

void dzn_original_implementation(id self, SEL _cmd) {
    // 从查找表中取出原始的数据
    Class baseClass = dzn_baseClassToSwizzleForTarget(self);
    NSString *key = dzn_implementationKey(baseClass, _cmd);

    NSDictionary *swizzleInfo = [_impLookupTable objectForKey:key];
    NSValue *impValue = [swizzleInfo valueForKey:DZNSwizzleInfoPointerKey];

    IMP impPointer = [impValue pointerValue];

    // 数据为空的时候实现额外的方法reloadding
    // 在调用原始数据实现之前，更新isEmptyDataSetVisible的值
    [self dzn_reloadEmptyDataSet];

    // 如果找到，实现。
    if (impPointer) {
        ((void (*)(id, SEL))impPointer)(self, _cmd);
    }
}

NSString *dzn_implementationKey(Class class, SEL selector) {
    if (!class || !selector) {
        return nil;
    }

    NSString *className = NSStringFromClass([class class]);

    NSString *selectorName = NSStringFromSelector(selector);
    return [NSString stringWithFormat:@"%@_%@", className, selectorName];
}

Class dzn_baseClassToSwizzleForTarget(id target) {
    if ([target isKindOfClass:[UITableView class]]) {
        return [UITableView class];
    } else if ([target isKindOfClass:[UICollectionView class]]) {
        return [UICollectionView class];
    } else if ([target isKindOfClass:[UIScrollView class]]) {
        return [UIScrollView class];
    }

    return nil;
}

- (void)swizzleIfPossible:(SEL)selector {
    // 检查selector方法是否相应
    if (![self respondsToSelector:selector]) {
        return;
    }

    // 创建一个查找表
    if (!_impLookupTable) {
        _impLookupTable = [[NSMutableDictionary alloc] initWithCapacity:3]; // 3 represent the supported base classes
    }

    // 确保对象是UITableView或者CollectionView
    for (NSDictionary *info in [_impLookupTable allValues]) {
        Class class = [info objectForKey:DZNSwizzleInfoOwnerKey];
        NSString *selectorName = [info objectForKey:DZNSwizzleInfoSelectorKey];
        if ([selectorName isEqualToString:NSStringFromSelector(selector)]) {
            if ([self isKindOfClass:class]) {
                return;
            }
        }
    }

    Class baseClass = dzn_baseClassToSwizzleForTarget(self);
    NSString *key = dzn_implementationKey(baseClass, selector);
    NSValue *impValue = [[_impLookupTable objectForKey:key] valueForKey:DZNSwizzleInfoPointerKey];

    // 如果这个类已经存在，跳过。
    if (impValue || !key || !baseClass) {
        return;
    }

    // 额外的实现
    Method method = class_getInstanceMethod(baseClass, selector);
    IMP dzn_newImplementation = method_setImplementation(method, (IMP)dzn_original_implementation);

    // 存储一个新的查找表
    NSDictionary *swizzledInfo = @{
        DZNSwizzleInfoOwnerKey: baseClass,
        DZNSwizzleInfoSelectorKey: NSStringFromSelector(selector),
        DZNSwizzleInfoPointerKey: [NSValue valueWithPointer:dzn_newImplementation]
    };

    [_impLookupTable setObject:swizzledInfo forKey:key];
}

#pragma mark - UIGestureRecognizerDelegate Methods

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer.view isEqual:self.emptyDataSetView]) {
        return [self dzn_isTouchAllowed];
    }

    return [super gestureRecognizerShouldBegin:gestureRecognizer];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    UIGestureRecognizer *tapGesture = self.emptyDataSetView.tapGesture;

    if ([gestureRecognizer isEqual:tapGesture] || [otherGestureRecognizer isEqual:tapGesture]) {
        return YES;
    }

    // 有没有实现emptyDataSetDelegate下的代理方法
    if ((self.emptyDataSetDelegate != (id)self) &&
        [self.emptyDataSetDelegate
        respondsToSelector:@selector(gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:)]) {
        return [(id)self.emptyDataSetDelegate gestureRecognizer:gestureRecognizer
             shouldRecognizeSimultaneouslyWithGestureRecognizer:otherGestureRecognizer];
    }

    return NO;
}

@end

#pragma mark - DZNEmptyDataSetView

@interface DZNEmptyDataSetView ()
@end

@implementation DZNEmptyDataSetView
@synthesize contentView = _contentView;
@synthesize titleLabel = _titleLabel, detailLabel = _detailLabel, imageView = _imageView, button = _button;

#pragma mark - Initialization Methods

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubview:self.contentView];
    }
    return self;
}

- (void)didMoveToSuperview {
    self.frame = self.superview.bounds;

    void (^fadeInBlock)(void) = ^{
        _contentView.alpha = 1.0;
    };

    if (self.fadeInOnDisplay) {
        [UIView animateWithDuration:0.25 animations:fadeInBlock completion:NULL];
    } else {
        fadeInBlock();
    }
}

#pragma mark - Getters

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [UIView new];
        _contentView.translatesAutoresizingMaskIntoConstraints = NO;
        _contentView.backgroundColor = [UIColor clearColor];
        _contentView.userInteractionEnabled = YES;
        _contentView.alpha = 0;
    }
    return _contentView;
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [UIImageView new];
        _imageView.translatesAutoresizingMaskIntoConstraints = NO;
        _imageView.backgroundColor = [UIColor clearColor];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        _imageView.userInteractionEnabled = NO;
        _imageView.accessibilityIdentifier = @"empty set background image";

        [_contentView addSubview:_imageView];
    }
    return _imageView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.backgroundColor = [UIColor clearColor];

        _titleLabel.font = [UIFont systemFontOfSize:27.0];
        _titleLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _titleLabel.numberOfLines = 0;
        _titleLabel.accessibilityIdentifier = @"empty set title";

        [_contentView addSubview:_titleLabel];
    }
    return _titleLabel;
}

- (UILabel *)detailLabel {
    if (!_detailLabel) {
        _detailLabel = [UILabel new];
        _detailLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _detailLabel.backgroundColor = [UIColor clearColor];

        _detailLabel.font = [UIFont systemFontOfSize:17.0];
        _detailLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
        _detailLabel.textAlignment = NSTextAlignmentCenter;
        _detailLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _detailLabel.numberOfLines = 0;
        _detailLabel.accessibilityIdentifier = @"empty set detail label";

        [_contentView addSubview:_detailLabel];
    }
    return _detailLabel;
}

- (UIButton *)button {
    if (!_button) {
        _button = [UIButton buttonWithType:UIButtonTypeCustom];
        _button.translatesAutoresizingMaskIntoConstraints = NO;
        _button.backgroundColor = [UIColor clearColor];
        _button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        _button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        _button.accessibilityIdentifier = @"empty set button";

        [_button addTarget:self action:@selector(didTapButton:) forControlEvents:UIControlEventTouchUpInside];

        [_contentView addSubview:_button];
    }
    return _button;
}

- (BOOL)canShowImage {
    return (_imageView.image && _imageView.superview);
}

- (BOOL)canShowTitle {
    return (_titleLabel.attributedText.string.length > 0 && _titleLabel.superview);
}

- (BOOL)canShowDetail {
    return (_detailLabel.attributedText.string.length > 0 && _detailLabel.superview);
}

- (BOOL)canShowButton {
    if ([_button attributedTitleForState:UIControlStateNormal].string.length > 0 || [_button imageForState:UIControlStateNormal]) {
        return (_button.superview != nil);
    }
    return NO;
}

#pragma mark - Setters

- (void)setCustomView:(UIView *)view {
    if (!view) {
        return;
    }

    if (_customView) {
        [_customView removeFromSuperview];
        _customView = nil;
    }

    _customView = view;
    _customView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_customView];
}

#pragma mark - Action Methods

- (void)didTapButton:(id)sender {
    SEL selector = NSSelectorFromString(@"dzn_didTapDataButton:");

    if ([self.superview respondsToSelector:selector]) {
        [self.superview performSelector:selector withObject:sender afterDelay:0.0f];
    }
}

- (void)removeAllConstraints {
    [self removeConstraints:self.constraints];
    [_contentView removeConstraints:_contentView.constraints];
}

- (void)prepareForReuse {
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    _titleLabel = nil;
    _detailLabel = nil;
    _imageView = nil;
    _button = nil;
    _customView = nil;

    [self removeAllConstraints];
}

#pragma mark - Auto-Layout Configuration

- (void)setupConstraints {
    // 第一步配置content的约束
    // content View必须居中在superView中
    NSLayoutConstraint *centerXConstraint =
    [self equallyRelatedConstraintWithView:self.contentView attribute:NSLayoutAttributeCenterX];
    NSLayoutConstraint *centerYConstraint =
    [self equallyRelatedConstraintWithView:self.contentView attribute:NSLayoutAttributeCenterY];

    [self addConstraint:centerXConstraint];
    [self addConstraint:centerYConstraint];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[contentView]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:@{
                                                                       @"contentView": self.contentView
                                                                   }]];

    // 如果定制了一个便宜量，我们实现这个偏移
    if (self.verticalOffset != 0 && self.constraints.count > 0) {
        centerYConstraint.constant = self.verticalOffset;
    }

    // 如果customView存在，设置customView的约束。
    if (_customView) {
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[contentView]|"
                                                                     options:0
                                                                     metrics:nil
                                                                       views:@{
                                                                           @"contentView": _contentView
                                                                       }]];

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[customView]|"
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:@{
                                                                                       @"customView": _customView
                                                                                   }]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[customView]|"
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:@{
                                                                                       @"customView": _customView
                                                                                   }]];
    } else {
        CGFloat width = CGRectGetWidth(self.frame) ?: CGRectGetWidth([UIScreen mainScreen].bounds);
        CGFloat padding = roundf(width / 16.0);
        CGFloat verticalSpace = self.verticalSpace ?: 11.0; // 默认 11 pts

        NSMutableArray *subviewStrings = [NSMutableArray array];
        NSMutableDictionary *views = [NSMutableDictionary dictionary];
        NSDictionary *metrics = @{ @"padding": @(padding) };

        // 指定ImageView的约束
        if (_imageView.superview) {

            [subviewStrings addObject:@"imageView"];
            views[[subviewStrings lastObject]] = _imageView;

            [self.contentView
            addConstraint:[self.contentView equallyRelatedConstraintWithView:_imageView attribute:NSLayoutAttributeCenterX]];
        }

        // 指定标题的约束
        if ([self canShowTitle]) {

            [subviewStrings addObject:@"titleLabel"];
            views[[subviewStrings lastObject]] = _titleLabel;

            [self.contentView addConstraints:[NSLayoutConstraint
                                             constraintsWithVisualFormat:@"H:|-(padding@750)-[titleLabel(>=0)]-(padding@750)-|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
        }
        // 或者从父视图移除
        else {
            [_titleLabel removeFromSuperview];
            _titleLabel = nil;
        }

        // 指定详细信息的约束
        if ([self canShowDetail]) {

            [subviewStrings addObject:@"detailLabel"];
            views[[subviewStrings lastObject]] = _detailLabel;

            [self.contentView addConstraints:[NSLayoutConstraint
                                             constraintsWithVisualFormat:@"H:|-(padding@750)-[detailLabel(>=0)]-(padding@750)-|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
        }
        // 或者从父视图移除
        else {
            [_detailLabel removeFromSuperview];
            _detailLabel = nil;
        }

        // 指定按钮的约束
        if ([self canShowButton]) {

            [subviewStrings addObject:@"button"];
            views[[subviewStrings lastObject]] = _button;

            [self.contentView
            addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(padding@750)-[button(>=0)]-(padding@750)-|"
                                                                   options:0
                                                                   metrics:metrics
                                                                     views:views]];
        }
        // 或者从父视图移除
        else {
            [_button removeFromSuperview];
            _button = nil;
        }

        NSMutableString *verticalFormat = [NSMutableString new];

        // 这几个控件之间建立一个垂直的约束，默认是11pts
        for (int i = 0; i < subviewStrings.count; i++) {

            NSString *string = subviewStrings[i];
            [verticalFormat appendFormat:@"[%@]", string];

            if (i < subviewStrings.count - 1) {
                [verticalFormat appendFormat:@"-(%.f@750)-", verticalSpace];
            }
        }

        // 指定contentView的约束
        if (verticalFormat.length > 0) {
            [self.contentView
            addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|%@|", verticalFormat]
                                                                   options:0
                                                                   metrics:metrics
                                                                     views:views]];
        }
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];

    // 返回按钮的UIControl实例
    if ([hitView isKindOfClass:[UIControl class]]) {
        return hitView;
    }

    // 返回contentView或者customView
    if ([hitView isEqual:_contentView] || [hitView isEqual:_customView]) {
        return hitView;
    }

    return nil;
}

@end

#pragma mark - UIView+DZNConstraintBasedLayoutExtensions

@implementation UIView (DZNConstraintBasedLayoutExtensions)

- (NSLayoutConstraint *)equallyRelatedConstraintWithView:(UIView *)view attribute:(NSLayoutAttribute)attribute {
    return [NSLayoutConstraint constraintWithItem:view
                                        attribute:attribute
                                        relatedBy:NSLayoutRelationEqual
                                           toItem:self
                                        attribute:attribute
                                       multiplier:1.0
                                         constant:0.0];
}

@end

#pragma mark - DZNWeakObjectContainer

@implementation DZNWeakObjectContainer

- (instancetype)initWithWeakObject:(id)object {
    self = [super init];
    if (self) {
        _weakObject = object;
    }
    return self;
}

@end
