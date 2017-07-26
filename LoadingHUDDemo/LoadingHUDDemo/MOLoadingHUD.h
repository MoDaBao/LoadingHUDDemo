//
//  MOLoadingHUD.h
//  LoadingHUDDemo
//
//  Created by M on 2017/7/15.
//  Copyright © 2017年 dabao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MOLoadingHUD : UIView<CAAnimationDelegate>

+ (void)showHUD;
+ (void)dismissHUD;
+ (void)reductionHUD;
@end
