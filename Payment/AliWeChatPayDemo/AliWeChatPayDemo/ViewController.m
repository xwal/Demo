//
//  ViewController.m
//  AliWeChatPayDemo
//
//  Created by Chaosky on 16/5/24.
//  Copyright © 2016年 1000phone. All rights reserved.
//

#import "ViewController.h"
// 配置文件
#import "PayWayConfig.h"

// 支付宝支付头文件
#import <AlipaySDK/AlipaySDK.h>
#import "DataSigner.h"
#import "Order.h"

// 微信支付头文件
#import "WXApi.h"
#import "payRequsestHandler.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    UIButton * aliPayButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.view addSubview:aliPayButton];
    aliPayButton.frame = CGRectMake(100, 100, 200, 50);
    [aliPayButton setTitle:@"支付宝支付" forState:UIControlStateNormal];
    // 添加事件响应
    [aliPayButton addTarget:self action:@selector(aliPayAction:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton * wechatButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.view addSubview:wechatButton];
    wechatButton.frame = CGRectMake(100, 200, 200, 50);
    [wechatButton setTitle:@"微信支付" forState:UIControlStateNormal];
    [wechatButton addTarget:self action:@selector(wechatPayAction:) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - 支付宝支付
- (void)aliPayAction:(UIButton *) sender
{
    // 创建订单信息
    Order *order = [[Order alloc] init];
    order.partner = PartnerID; // 商户ID
    order.seller = SellerID; // 账号ID
    order.tradeNO = @"20160524153212113"; //订单ID（由商家自行制定），由服务器生成或者由客户端生成
    order.productName = @"Apple Watch 2"; //商品标题
    order.productDescription = @"520特价，儿童节特价"; //商品描述
    order.amount = @"0.01"; //商品价格(单位：元)
    order.notifyURL =  @"http://www.chaosky.me"; //回调URL，支付成功或者失败回调通知自己的服务器进行订单状态变更
    order.service = @"mobile.securitypay.pay";
    order.paymentType = @"1";
    order.inputCharset = @"utf-8";
    order.itBPay = @"30m";
    order.showUrl = @"m.alipay.com";
    
    // 应用注册scheme,在AlixPayDemo-Info.plist定义URL types
    NSString *appScheme = @"AliPayDemo";
    
    //将商品信息拼接成字符串
    NSString *orderSpec = [order description];
    NSLog(@"orderSpec = %@",orderSpec);
    
    //获取私钥并将商户信息签名,外部商户可以根据情况存放私钥和签名,只需要遵循RSA签名规范,并将签名字符串base64编码和UrlEncode
    id<DataSigner> signer = CreateRSADataSigner(PartnerPrivKey);
    NSString *signedString = [signer signString:orderSpec];
    
    //将签名成功字符串格式化为订单字符串,请严格按照该格式
    NSString *orderString = nil;
    if (signedString != nil) {
        orderString = [NSString stringWithFormat:@"%@&sign=\"%@\"&sign_type=\"%@\"",
                       orderSpec, signedString, @"RSA"];
        
        [[AlipaySDK defaultService] payOrder:orderString fromScheme:appScheme callback:^(NSDictionary * resultDic) {
            NSLog(@"reslut = %@",resultDic);
        }];
    }
    
}

#pragma mark - 微信支付
- (void)wechatPayAction:(UIButton *) sender
{
    // 判断用户是否安装微信
    if (![WXApi isWXAppInstalled]) {
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"请安装微信客户端" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alertView show];
        return;
    }
    
    // 实现支付
    [self sendPay_demo];
}

- (void)sendPay_demo
{
    //{{{
    //本实例只是演示签名过程， 请将该过程在商户服务器上实现
    
    // 配置微信支付的参数
    //创建支付签名对象
    payRequsestHandler *req = [[payRequsestHandler alloc] init];
    //初始化支付签名对象
    [req init:__WXappID mch_id:__WXmchID];
    //设置密钥
    [req setKey:__WXpaySignKey];
    
    //}}}
    
    //获取到实际调起微信支付的参数后，在app端调起支付
    NSMutableDictionary *dict = [req sendPay_demo];
    
    if(dict == nil){
        //错误提示
        NSString *debug = [req getDebugifo];
        
        [self alert:@"提示信息" msg:debug];
        
        NSLog(@"%@\n\n",debug);
    }else{
        NSLog(@"%@\n\n",[req getDebugifo]);
        //[self alert:@"确认" msg:@"下单成功，点击OK后调起支付！"];
        
        NSMutableString *stamp  = [dict objectForKey:@"timestamp"];
        
        //调起微信支付
        PayReq* req             = [[PayReq alloc] init];
        req.openID              = [dict objectForKey:@"appid"];
        req.partnerId           = [dict objectForKey:@"partnerid"];
        req.prepayId            = [dict objectForKey:@"prepayid"];
        req.nonceStr            = [dict objectForKey:@"noncestr"];
        req.timeStamp           = stamp.intValue;
        req.package             = [dict objectForKey:@"package"];
        req.sign                = [dict objectForKey:@"sign"];
        
        // 调用微信支付
        [WXApi sendReq:req];
    }
}

//客户端提示信息
- (void)alert:(NSString *)title msg:(NSString *)msg
{
    UIAlertView *alter = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
    [alter show];
}

@end
