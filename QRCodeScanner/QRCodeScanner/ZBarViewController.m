//
//  ZBarViewController.m
//  QRCodeScanner
//
//  Created by Chaosky on 15/10/30.
//  Copyright © 2015年 1000phone. All rights reserved.
//

#import "ZBarViewController.h"
#import <ZBarSDK.h>

@interface ZBarViewController ()<ZBarReaderViewDelegate, ZBarReaderDelegate>

@property (nonatomic, strong) UISwitch * switchView;
@property (nonatomic, strong) ZBarReaderView * readerView;

@end

@implementation ZBarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // UISwitch
    _switchView = [[UISwitch alloc] initWithFrame:CGRectMake(50, 70, 100, 40)];
    [_switchView addTarget:self action:@selector(showZBarReaderView:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = _switchView;
    
    // ZBarSDK集成方式分两种：

    // 自定义照相机视图，使用ZBar提供的可以嵌在其他视图中的ZBarReaderView
    //二维码/条形码识别设置
    // 创建扫描类，只负责解析
    ZBarImageScanner *scanner = [[ZBarImageScanner alloc] init];
    // 设置扫描的类别和配置
    [scanner setSymbology: ZBAR_I25
                   config: ZBAR_CFG_ENABLE
                       to: 0];

    // 创建ZBar读取视图，主要是扫描（二维码）
    self.readerView = [[ZBarReaderView alloc] initWithImageScanner:scanner];
    self.readerView.frame = CGRectMake(100, 100, 200, 200);
    self.readerView.readerDelegate = self;
    [self.view addSubview:self.readerView];
    
    
    // 直接调用ZBar提供的ZBarReaderViewController打开一个扫描界面
    UIBarButtonItem * rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"启动扫描界面" style:UIBarButtonItemStylePlain target:self action:@selector(openReaderViewController)];
    self.navigationItem.rightBarButtonItem = rightBarButtonItem;
}

- (void)showZBarReaderView:(UISwitch *) sender
{
    if (sender.isOn) {
        //启动，必须启动后，手机摄影头拍摄的即时图像菜可以显示在readview上
        [self.readerView start];
    }
    else
    {
        [self.readerView stop];
        [self.readerView flushCache];
    }
}

// 创建ZBarReaderViewController的方式扫描二维码
- (void)openReaderViewController
{
    ZBarReaderViewController * reader = [ZBarReaderViewController new];
    reader.readerDelegate = self;
    // 同上设置Scanner的属性
    ZBarImageScanner * scanner = reader.scanner;
    [scanner setSymbology:ZBAR_I25 config:ZBAR_CFG_ENABLE to:0];
    
    // 是否显示控制
    reader.showsZBarControls = YES;
    
    [self presentViewController:reader animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - ZBarReaderViewDelegate
// 获取解析的数据
- (void)readerView:(ZBarReaderView *)readerView didReadSymbols:(ZBarSymbolSet *)symbols fromImage:(UIImage *)image
{
    ZBarSymbol * symbol;
    for(symbol in symbols)
        break;
    NSLog(@"%@", symbol.data);
}

#pragma mark - ZBarReaderDelegate
// 获取解析数据
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    id<NSFastEnumeration> results = [info objectForKey:ZBarReaderControllerResults];
    ZBarSymbol * symbol;
    for(symbol in results)
        break;
    NSLog(@"%@", symbol.data);
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
