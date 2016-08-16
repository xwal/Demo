//
//  ScanViewController.m
//  QRCodeScanner
//
//  Created by Chaosky on 15/10/30.
//  Copyright (c) 2015年 1000phone. All rights reserved.
//

// 使用SDK中AVFoundation.framework自带的二维码扫描识别
// 1、导入AVFoundation
// 2、获取取景设备
// 3、输入设备设置（摄像机）
// 4、输出设备设置（视图控制器上的视图）
// 5、创建会话
// 6、创建预览层
// 7、将预览层添加到UIView的layer上
// 8、开始会话
// 9、获取到解析出来的数据，可以停止会话
#import "ScanViewController.h"

#import <AVFoundation/AVFoundation.h>

@interface ScanViewController () <AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, strong) AVCaptureDevice *device;
@property (nonatomic, strong) AVCaptureDeviceInput *input;
@property (nonatomic, strong) AVCaptureMetadataOutput *output;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *preview;

@end

@implementation ScanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpCamera];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self setScanRegion];
    
    //4、开始会话
    [_session startRunning];
}

- (void)cancelButtonClicked
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

// 实现二维码扫描的流程：
// 1、设置摄像机，并配置相关的属性
- (void)setUpCamera
{
    // 获取系统默认的取景设备
    _device  = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // 根据系统默认的取景设置创建AVCaptureDeviceInput对象
    _input   = [AVCaptureDeviceInput deviceInputWithDevice:_device error:nil];
    
    // 创建输出AVCaptureMetadataOutput对象
    _output  = [AVCaptureMetadataOutput new];
    // 设置接收数据的对象和线程，你可以将其放到子线程中
    // delegate
    // queue
    [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    // 创建取景的会话，将Input和Output联系起来，添加Input和Output
    _session = [AVCaptureSession new];
    [_session addInput:_input];
    [_session addOutput:_output];
    
    // 设置取景的元数据类型，这个地方要识别二维码需要将其设置为AVMetadataObjectTypeQRCode
    _output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
    
    // 设置取景的预览层，摄像机获取到的图像显示在这个层上
    _preview = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    // 类似于UIImageView设置contentMode
    [_preview setVideoGravity:AVLayerVideoGravityResizeAspect];
    [_preview setFrame:self.view.layer.bounds];
    // 将取景预览层添加到self.view(可以是子视图)的层上
    [self.view.layer addSublayer:_preview];
}


// 2、设置扫描区域，也就是识别二维码的区域
- (void)setScanRegion
{
    // 添加一个图片，并设置约束
    UIImageView *overlayImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"overlaygraphic.png"]];
    overlayImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:overlayImageView];
    
    // 使用NSLayoutConstraint布局，将图片居中显示
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view        attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual
                                                             toItem:overlayImageView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view        attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual
                                                             toItem:overlayImageView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    
    
    // 获取屏幕的尺寸
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat screenWidth  = [UIScreen mainScreen].bounds.size.width;
    
    // 设置设备的Output扫描区域，让Output只解析这个区域中获取的图像内容
    _output.rectOfInterest = CGRectMake((screenHeight - 200) / 2 / screenHeight,
                                        (screenWidth  - 260) / 2 / screenWidth,
                                        200 / screenHeight,
                                        260 / screenWidth);
}


// 3、实现AVCaptureMetadataOutputObjectsDelegate协议方法
// 获取解析的数据

// 第一个参数：AVCaptureOutput 取景输出
// 第二个参数：metadataObjects 解析的数据
// 第三个参数：AVCaptureConnection 通过AVSession建立的连接
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    NSString *message;
    
    // 判断数据是否解析出来
    if (metadataObjects.count > 0) {
        
        // 停止AVSession，停止会话
        [_session stopRunning];
        
        // 读取数据
        AVMetadataMachineReadableCodeObject *metadataObject = metadataObjects[0];
        
        message = metadataObject.stringValue;
        
        NSLog(@"%@", message);
    }
}


@end
