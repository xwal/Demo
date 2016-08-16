//
//  ViewController.m
//  QRCodeScanner
//
//  Created by Chaosky on 15/10/30.
//  Copyright (c) 2015年 1000phone. All rights reserved.
//

#import "ViewController.h"
#import "ZBarViewController.h"
#import "ScanViewController.h"

@interface ViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray * dataArray;
@property (nonatomic, strong) UITableView * tableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.title = @"二维码扫描";
    
    self.dataArray =  @[@"ZBarSDK", @"ZXingObjC", @"AVFoundation"];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"CELL"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CELL"];
    }
    cell.textLabel.text = self.dataArray[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString * title = self.dataArray[indexPath.row];
    switch (indexPath.row) {
        case 0:
        {
            ZBarViewController * zbarVC = [[ZBarViewController alloc] init];
            zbarVC.title = title;
            [self.navigationController pushViewController:zbarVC animated:YES];
        }
            break;
        case 2:
        {
            ScanViewController * scanVC = [[ScanViewController alloc] init];
            scanVC.title = title;
            [self.navigationController pushViewController:scanVC animated:YES];
        }
            break;
        default:
            break;
    }
}

@end
