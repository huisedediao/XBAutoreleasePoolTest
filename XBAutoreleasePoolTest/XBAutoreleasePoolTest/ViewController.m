//
//  ViewController.m
//  XBAutoreleasePoolTest
//
//  Created by 谢贤彬 on 2019/1/3.
//  Copyright © 2019年 谢贤彬. All rights reserved.
//

#import "ViewController.h"
#import "TestViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UILabel *label = [UILabel new];
    [self.view addSubview:label];
    label.frame = CGRectMake(10, 100, 200, 100);
    label.text = @"点击屏幕进入测试页面";
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    TestViewController *vc = [TestViewController new];
    [self presentViewController:vc animated:YES completion:nil];
}

@end
