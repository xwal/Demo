//
//  ViewController.m
//  SwizzleDemo
//
//  Created by Chaosky on 2016/10/26.
//  Copyright © 2016年 1000phone. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSArray * colorArray = @[[UIColor redColor], [UIColor brownColor], [UIColor blueColor], [UIColor purpleColor]];
    __weak typeof(self) weakSelf = self;
    [colorArray enumerateObjectsUsingBlock:^(UIColor * color, NSUInteger idx, BOOL * stop) {
        UIButton * button = [UIButton buttonWithType:UIButtonTypeSystem];
        [weakSelf.view addSubview:button];
        [button setTitle:@"点我" forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:20];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button.frame = CGRectMake(100, 100 + idx * 100, 200, 50);
        button.backgroundColor = color;
        
        // 需要添加target/action，模拟按钮点击事件的绑定
        [button addTarget:weakSelf action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    }];
    
}

- (void)buttonTapped:(UIButton *) sender {
    // 方法实现根据应用具体功能实现，本demo不实现具体内容
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
