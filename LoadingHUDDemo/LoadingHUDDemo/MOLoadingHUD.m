//
//  MOLoadingHUD.m
//  LoadingHUDDemo
//
//  Created by M on 2017/7/15.
//  Copyright © 2017年 dabao. All rights reserved.
//

#import "MOLoadingHUD.h"
#import "AppDelegate.h"

#define radius 60
#define roundRectWidth 300
#define roundRectHeight 40

#define screenWidth [UIScreen mainScreen].bounds.size.width
#define screenHeight [UIScreen mainScreen].bounds.size.height
#define bgBlue [UIColor colorWithRed:0.31 green:0.51 blue:1.00 alpha:1.00]
#define bgGreen  [UIColor colorWithRed:0.37 green:0.82 blue:0.48 alpha:1.00]

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

- (void)animate {
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

- (void)progressBarAnimation {
    CAShapeLayer *progressLayer = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(roundRectHeight * .5, _circleView.frame.size.height * .5)];
    [path addLineToPoint:CGPointMake(_circleView.frame.size.width - roundRectHeight * .5, _circleView.frame.size.height * .5)];
    
    progressLayer.path = path.CGPath;
    progressLayer.strokeColor = [UIColor whiteColor].CGColor;
    progressLayer.lineWidth = roundRectHeight - 6;
    progressLayer.lineCap = kCALineCapRound;
    progressLayer.backgroundColor = [UIColor blueColor].CGColor;
    [_circleView.layer addSublayer:progressLayer];
    
    CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    pathAnimation.duration = 2.0f;
    pathAnimation.fromValue = @(0.0f);
    pathAnimation.toValue = @(1.0f);
    pathAnimation.delegate = self;
    
    [pathAnimation setValue:@"progressBarAnimation" forKey:@"animationName"];// 用KVO判断不同 anim
    [progressLayer addAnimation:pathAnimation forKey:nil];
}

+ (void)showHUD {
    MOLoadingHUD *hud = [MOLoadingHUD sharedHUD];
    AppDelegate *appdelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    UIViewController *rootVC = appdelegate.window.rootViewController;
    
    UIViewController *currentVC = [hud getCurrentVCFrom:rootVC];
    [currentVC.view addSubview:hud];
    [hud animate];
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


- (void)animationDidStart:(CAAnimation *)anim {
    if ([anim isEqual:[_circleView.layer animationForKey:@"cornerRadiusAnimation"]]) {
        [UIView animateWithDuration:.6f delay:.0 usingSpringWithDamping:.6 initialSpringVelocity:.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            _circleView.frame = CGRectMake((screenWidth - roundRectWidth) * .5, (screenHeight - roundRectHeight) * .5, roundRectWidth, roundRectHeight);
        } completion:^(BOOL finished) {
            [_circleView.layer removeAllAnimations];
            [self progressBarAnimation];
        }];
    } else if ([[anim valueForKey:@"animationName"]isEqualToString:@"progressBarAnimation"]) {
        
    } else if ([anim isEqual:[_circleView.layer animationForKey:@"CornerRadiusExpandAnim"]]) {
        [UIView animateWithDuration:.6f delay:.0 usingSpringWithDamping:.6 initialSpringVelocity:.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            _circleView.frame = CGRectMake((screenWidth - radius * 2) * .5, (screenHeight - radius * 2) * .5, radius * 2, radius * 2);
            _circleView.backgroundColor = bgGreen;
        } completion:^(BOOL finished) {
            [_circleView.layer removeAllAnimations];
            
            _animating = NO;
        }];
    }
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if ([[anim valueForKey:@"animationName"]isEqualToString:@"progressBarAnimation"] ) {
        [UIView animateWithDuration:.3f animations:^{
            for (CALayer *sublayer in _circleView.layer.sublayers) {
                sublayer.opacity = 0.0f;
            }
        } completion:^(BOOL finished) {
            for (CALayer *sublayer in _circleView.layer.sublayers) {
                [sublayer removeFromSuperlayer];
            }
            _circleView.layer.cornerRadius = radius;
            CABasicAnimation *radiusAnimation = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
            radiusAnimation.duration = .2f;
            radiusAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            radiusAnimation.fromValue = @(roundRectHeight * .5);
            radiusAnimation.delegate = self;
            
            [_circleView.layer addAnimation:radiusAnimation forKey:@"CornerRadiusExpandAnim"];
        }];
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
