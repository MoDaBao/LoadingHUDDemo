//
//  MOLoadingHUD.m
//  LoadingHUDDemo
//
//  Created by M on 2017/7/15.
//  Copyright © 2017年 dabao. All rights reserved.
//

#import "MOLoadingHUD.h"
#import "AppDelegate.h"

#define screenWidth [UIScreen mainScreen].bounds.size.width
#define screenHeight [UIScreen mainScreen].bounds.size.height
#define bgBlue [UIColor colorWithRed:0.31 green:0.51 blue:1.00 alpha:1.00]
#define bgGreen  [UIColor colorWithRed:0.37 green:0.82 blue:0.48 alpha:1.00]
#define scale (screenWidth / 375.0)

#define radius (60 * scale)
#define roundRectWidth (300 * scale)
#define roundRectHeight (50 * scale)



@implementation MOLoadingHUD {
    UIView *_circleView;
    CGRect _originFrame;
    BOOL _animating;
}

+ (MOLoadingHUD*)sharedHUD {
    static dispatch_once_t once;
    static MOLoadingHUD *sharedHUD;
    dispatch_once(&once, ^{
        sharedHUD = [[self alloc] init];
    });
    return sharedHUD;
}

- (instancetype)init {
    if (self = [super init]) {
        
        self.frame = [UIScreen mainScreen].bounds;
        
        _circleView = [[UIView alloc] initWithFrame:CGRectMake((screenWidth - radius * 2) * .5, (screenHeight - radius * 2) * .5, radius * 2, radius * 2)];
        _circleView.clipsToBounds = YES;
        _circleView.layer.cornerRadius = radius;
        _circleView.backgroundColor = bgBlue;
        [self addSubview:_circleView];
        
        _originFrame = _circleView.frame;
    }
    return self;
}

// 圆角动画
- (void)roundAnimation {
    if (_animating) {
        return;
    }
    
    for (CALayer *subLayer in _circleView.layer.sublayers) {
        [subLayer removeFromSuperlayer];
    }
    
    _circleView.backgroundColor = bgBlue;
    
    _animating = YES;
    
    /*
     我们知道，使用 CAAnimation 如果不做额外的操作，动画会在结束之后返回到初始状态。或许你会这么设置：
      
     radiusAnimation.fillMode = kCAFillModeForwards;
     radiusAnimation.removedOnCompletion = NO;
      
     但这不是正确的方式。正确的做法可以参考 WWDC 2011 中的 session 421 - Core Animation Essentials. 为了保证教程的连贯性，我把视频放在了结尾，你可以在学完这个 demo 之后仔细看一遍。
     推荐的做法是先显式地改变  Model Layer 的对应属性，再应用动画。这样一来，我们甚至省去了 toValue.
     */
    _circleView.layer.cornerRadius = roundRectHeight * .5;
    CABasicAnimation *radiusAnimation = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
    radiusAnimation.duration = .2f;
    radiusAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    radiusAnimation.fromValue = @(_originFrame.size.height * .5);
    radiusAnimation.delegate = self;
    
    [_circleView.layer addAnimation:radiusAnimation forKey:@"cornerRadiusAnimation"];
    
    
}

// 进度条动画
- (void)progressBarAnimation {
    CAShapeLayer *progressLayer = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPath];
    /*
     如何设置直线的起始点才能让白色进度条距离四周的间距相等呢？结论是 x = _progressBarHeight/2. 证明如下：
     因为我们设置了 progressLayer.lineCap = kCALineCapRound; lineCap 指的是线段的线帽，也就是决定一条线段两段的封口样式，有三种样式可以选择：
     kCALineCapButt: 默认格式，不附加任何形状;
     kCALineCapRound: 在线段头尾添加半径为线段 lineWidth 一半的半圆；
     kCALineCapSquare: 在线段头尾添加半径为线段 lineWidth 一半的矩形
      
     由于我们之前设置了 kCALineCapRound, 而半圆的半径就是 lineWidth/2, 所以起始点的 x 坐标应该满足公式 x = space + lineWidth/2, 又 ∵ lineWidth ＝ _progressBarHeight - space*2  ∴ x = _progressBarHeight/2, 也就是说起始点的 x 坐标与 lineWidth 的值并没有关系
     所以，只要保证了 path 的起点 x 坐标等于外围进度条（demo 中的蓝色进度条）高度的 1/2 ，那么无论设置 path 的 lineWidth 为多少都可以让白色进度条距离四周的间距相等。
     */
    [path moveToPoint:CGPointMake(roundRectHeight * .5, _circleView.frame.size.height * .5)];
    [path addLineToPoint:CGPointMake(_circleView.frame.size.width - roundRectHeight * .5, _circleView.frame.size.height * .5)];
    
    progressLayer.path = path.CGPath;
    progressLayer.strokeColor = [UIColor whiteColor].CGColor;
    progressLayer.lineWidth = roundRectHeight - 6;
    progressLayer.lineCap = kCALineCapRound;
    progressLayer.backgroundColor = [UIColor blueColor].CGColor;
    [_circleView.layer addSublayer:progressLayer];
    
    /*
     关于 @property CGFloat strokeStart; 和  @property CGFloat strokeEnd;  这两个属性，正如它的名字一样，定义了线段的开始和结束，并且取值都在 [0,1] 之间。默认 strokeStart 为 0，strokeEnd 为 1。通过设置不同的值，可以控制线条的展示状态。
     */
    CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    pathAnimation.duration = 2.0f;
    pathAnimation.fromValue = @(0.0f);
    pathAnimation.toValue = @(1.0f);
    pathAnimation.delegate = self;
    
    /*
     在同一个协议方法：animationDidStart 和 animationDidStop 中，如何区分不同的 anim ?
     有两种方法：
     1、如果 anim 加在一个全局变量上，比如例子里的self.AnimateView ，这就是一个全局变量。那么我们在这里可以通过 [self.AnimateView.layer animationForKey:] 方法根据动画不同的key来进行区分；
      
     2、如果对于一个非全局的变量，比如接下去我会在 demo 中用到的 progressLayer，则可以用KVO:[pathAnimation setValue:@"strokeEndAnimation" forKey:@"animationName"]; 注意这个animationName是我们自定义的。
     */
    [pathAnimation setValue:@"progressBarAnimation" forKey:@"animationName"];// 用KVO判断不同的anim
    [progressLayer addAnimation:pathAnimation forKey:nil];
}

// 打勾动画
- (void)checkAnimation {
    CAShapeLayer *checkLayer = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPath];
    //首先创建一个圆的内接矩形，方便后面画勾的时候可以以这个矩形作为参考
    CGFloat rectWidth = sqrt((radius * 2) * (radius * 2) * .5);
    CGRect rectInCircle = CGRectInset(_circleView.frame,  radius - rectWidth * .5, radius - rectWidth * .5);
    
    [path moveToPoint:CGPointMake(rectInCircle.size.width * 3 / 10, rectInCircle.size.height * 7 / 10)];
    [path addLineToPoint:CGPointMake(rectInCircle.size.width * 6 / 10, rectInCircle.size.height * 10 / 10)];
    [path addLineToPoint:CGPointMake(rectInCircle.size.width * 11 / 10, rectInCircle.size.height * 4 / 10)];
    
    checkLayer.path = path.CGPath;
    checkLayer.fillColor = [UIColor clearColor].CGColor;
    checkLayer.strokeColor = [UIColor whiteColor].CGColor;
    checkLayer.lineWidth = 10.0f;
    checkLayer.lineCap = kCALineCapRound;
    checkLayer.lineJoin = kCALineJoinRound;
    [_circleView.layer addSublayer:checkLayer];
    
    
    CABasicAnimation *checkAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    checkAnimation.duration = .3f;
    checkAnimation.fromValue = @(0.0f);
    checkAnimation.toValue = @(1.0f);
    checkAnimation.delegate = self;
    [checkAnimation setValue:@"checkAnimation" forKey:@"animationName"];
    [checkLayer addAnimation:checkAnimation forKey:nil];
}

+ (void)showHUD {
    MOLoadingHUD *hud = [MOLoadingHUD sharedHUD];
    AppDelegate *appdelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    UIViewController *rootVC = appdelegate.window.rootViewController;
    
    UIViewController *currentVC = [hud getCurrentVCFrom:rootVC];
    [currentVC.view addSubview:hud];
    [hud roundAnimation];
}

+ (void)dismissHUD {
    MOLoadingHUD *hud = [MOLoadingHUD sharedHUD];
    [hud removeFromSuperview];
}

+ (void)reductionHUD {
    MOLoadingHUD *hud = [MOLoadingHUD sharedHUD];
    [hud reduction];
}

- (void)reduction {
    _animating = NO;
    
    _circleView.frame = CGRectMake((screenWidth - radius * 2) * .5, (screenHeight - radius * 2) * .5, radius * 2, radius * 2);
    _circleView.layer.cornerRadius = radius;
    _circleView.backgroundColor = bgBlue;
    for (CALayer *subLayer in _circleView.layer.sublayers) {
        [subLayer removeFromSuperlayer];
    }
}

- (void)removeFromSuperview {
    [super removeFromSuperview];
    [self reduction];
}


#pragma mark- 动画代理

- (void)animationDidStart:(CAAnimation *)anim {
    if ([anim isEqual:[_circleView.layer animationForKey:@"cornerRadiusAnimation"]]) {
        /*
          圆角动画开始的同时，我们开始一个 bounds 的动画。让圆变化到一根长长的进度条。因为使用了弹性效果，而 CAAnimation 直到 iOS9 之后才引入了CASpringAnimation, 所以我们只能用 UIView 的 UIViewAnimationWithBlocks Category 来实现弹性动画了。
         */
        [UIView animateWithDuration:.6f delay:.0 usingSpringWithDamping:.6 initialSpringVelocity:.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            _circleView.frame = CGRectMake((screenWidth - roundRectWidth) * .5, (screenHeight - roundRectHeight) * .5, roundRectWidth, roundRectHeight);
        } completion:^(BOOL finished) {
            [_circleView.layer removeAllAnimations];
            [self progressBarAnimation];
        }];
    } else if ([anim isEqual:[_circleView.layer animationForKey:@"CornerRadiusExpandAnim"]]) {
        
        // cornerRadius 动画开始时  同时进行一个 bounds 动画，让进度条恢复到圆形状态。
        [UIView animateWithDuration:.6f delay:.0 usingSpringWithDamping:.6 initialSpringVelocity:.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            _circleView.frame = CGRectMake((screenWidth - radius * 2) * .5, (screenHeight - radius * 2) * .5, radius * 2, radius * 2);
            _circleView.backgroundColor = bgGreen;
        } completion:^(BOOL finished) {
            [_circleView.layer removeAllAnimations];
            [self checkAnimation];// 做打勾动画
        }];
    } else if ([[anim valueForKey:@"animationName"]isEqualToString:@"checkAnimation"]) {
        
    }
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if ([[anim valueForKey:@"animationName"]isEqualToString:@"progressBarAnimation"] ) {
        [UIView animateWithDuration:.3f animations:^{
            // 当进度条动画走完后，我们先让进度条做一个透明度到 0 的动画
            for (CALayer *sublayer in _circleView.layer.sublayers) {
                sublayer.opacity = 0.0f;
            }
        } completion:^(BOOL finished) {
            for (CALayer *sublayer in _circleView.layer.sublayers) {
                [sublayer removeFromSuperlayer];
            }
            // 之后立马同时开始一个 cornerRadius 动画
            _circleView.layer.cornerRadius = radius;
            CABasicAnimation *radiusAnimation = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
            radiusAnimation.duration = .2f;
            radiusAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            radiusAnimation.fromValue = @(roundRectHeight * .5);
            radiusAnimation.delegate = self;
            
            [_circleView.layer addAnimation:radiusAnimation forKey:@"CornerRadiusExpandAnim"];
        }];
    }  else if ([[anim valueForKey:@"animationName"]isEqualToString:@"checkAnimation"]) {
        _animating = NO;
    }
}


// 获取当前显示的视图控制器
- (UIViewController *)getCurrentVCFrom:(UIViewController *)rootVC {
    UIViewController *currentVC;
    
    if ([rootVC presentedViewController]) {
        // 视图是被presented出来的
        
        rootVC = [rootVC presentedViewController];
    }
    
    if ([rootVC isKindOfClass:[UITabBarController class]]) {
        // 根视图为UITabBarController
        
        currentVC = [self getCurrentVCFrom:[(UITabBarController *)rootVC selectedViewController]];
        
    } else if ([rootVC isKindOfClass:[UINavigationController class]]){
        // 根视图为UINavigationController
        
        currentVC = [self getCurrentVCFrom:[(UINavigationController *)rootVC visibleViewController]];
        
    } else {
        // 根视图为非导航类
        
        currentVC = rootVC;
    }
    
    return currentVC;
}


@end
