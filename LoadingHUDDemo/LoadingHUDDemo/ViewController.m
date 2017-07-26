//
//  ViewController.m
//  LoadingHUDDemo
//
//  Created by M on 2017/7/14.
//  Copyright © 2017年 dabao. All rights reserved.
//

#import "ViewController.h"
#import "LoadingHUD.h"
#import "MOLoadingHUD.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
//    [LoadingHUD showHUD];
//
//
    
    [MOLoadingHUD showHUD];
    
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(0, 0, 40, 30);
    [button setTitle:@"隐藏" forState:UIControlStateNormal];
    [self.view addSubview:button];
    [button addTarget:self action:@selector(dismissloading) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithCustomView:button];
    self.navigationItem.leftBarButtonItem = left;
    
    
    UIButton *button1 = [UIButton buttonWithType:UIButtonTypeSystem];
    button1.frame = CGRectMake(0, 0, 40, 30);
    [button1 setTitle:@"显示" forState:UIControlStateNormal];
    [self.view addSubview:button1];
    [button1 addTarget:self action:@selector(showloading) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithCustomView:button1];
    self.navigationItem.rightBarButtonItem = right;
    
    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeSystem];
    button2.frame = CGRectMake(0, 0, 40, 30);
    [button2 setTitle:@"还原" forState:UIControlStateNormal];
    [self.view addSubview:button2];
    [button2 addTarget:self action:@selector(reductionloading) forControlEvents:UIControlEventTouchUpInside];
//    UIBarButtonItem *center = [[UIBarButtonItem alloc] initWithCustomView:button2];
    self.navigationItem.titleView = button2;
}

- (void)dismissloading {
//    [LoadingHUD dismissHUD];
    [MOLoadingHUD dismissHUD];
}

- (void)showloading {
//    [LoadingHUD showHUD];
    [MOLoadingHUD showHUD];
}

- (void)reductionloading {
    [MOLoadingHUD reductionHUD];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
