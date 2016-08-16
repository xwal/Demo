//
//  ViewController.m
//  IAPDemo
//
//  Created by Chaosky on 16/1/24.
//  Copyright (c) 2016年 1000phone. All rights reserved.
//

#import "ViewController.h"
#import <StoreKit/StoreKit.h>

//在内购项目中创建的商品单号
#define ProductID_IAP_FTHJ @"com.1000phone.IAPDemo.fthj_purple" // 方天画戟 488元
#define ProductID_IAP_XYJ @"com.1000phone.IAPDemo.xyj" // 轩辕剑 6,498元
#define ProductID_IAP_JB @"com.1000phone.IAPDemo.jb" // 金币 6元=6金币

#define PAY_BUTTON_BEGIN_TAG 100

@interface ViewController ()<SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (nonatomic, assign) NSInteger buyType; // 购买类型

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createViews];
    // 监听购买结果
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

- (void)dealloc
{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

- (void)createViews
{
    NSArray * buttonNames = @[@"轩辕剑 6498元", @"方天画戟 488元", @"金币6元=6金币"];
    __weak typeof(self) weakSelf = self;
    [buttonNames enumerateObjectsUsingBlock:^(NSString * buttonName, NSUInteger idx, BOOL * stop) {
        UIButton * button = [UIButton buttonWithType:UIButtonTypeSystem];
        [weakSelf.view addSubview:button];
        button.frame = CGRectMake(100, 100 + idx   * 60, 150, 50);
        button.titleLabel.font = [UIFont systemFontOfSize:18];
        [button setTitle:buttonName forState:UIControlStateNormal];
        
        // 设置tag值
        button.tag = PAY_BUTTON_BEGIN_TAG + idx;
        [button addTarget:self action:@selector(buyProduct:) forControlEvents:UIControlEventTouchUpInside];
    }];
}

- (void)buyProduct:(UIButton *) sender
{
    self.buyType = sender.tag - PAY_BUTTON_BEGIN_TAG;
    if ([SKPaymentQueue canMakePayments]) {
        // 执行下面提到的第5步：
        [self requestProductData];
        NSLog(@"允许程序内付费购买");
    }
    else
    {
        NSLog(@"不允许程序内付费购买");
        UIAlertView *alerView =  [[UIAlertView alloc] initWithTitle:@"提示"
                                                            message:@"您的手机没有打开程序内付费购买"
                                                           delegate:nil cancelButtonTitle:NSLocalizedString(@"关闭",nil) otherButtonTitles:nil];
        
        [alerView show];
        
    }
}

// 下面的ProductId应该是事先在itunesConnect中添加好的，已存在的付费项目。否则查询会失败。
- (void)requestProductData {
    NSLog(@"---------请求对应的产品信息------------");
    NSArray *product = nil;
    switch (self.buyType) {
        case 0:
            product = [NSArray arrayWithObject:ProductID_IAP_XYJ];
            break;
        case 1:
            product = [NSArray arrayWithObject:ProductID_IAP_FTHJ];
            break;
        case 2:
            product = [NSArray arrayWithObject:ProductID_IAP_JB];
            break;
    }
    NSSet *nsset = [NSSet setWithArray:product];
    SKProductsRequest *request=[[SKProductsRequest alloc] initWithProductIdentifiers: nsset];
    request.delegate=self;
    [request start];
}

#pragma mark - SKProductsRequestDelegate
// 收到的产品信息回调
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
    
    NSLog(@"-----------收到产品反馈信息--------------");
    NSArray *myProduct = response.products;
    if (myProduct.count == 0) {
        NSLog(@"无法获取产品信息，购买失败。");
        return;
    }
    NSLog(@"产品Product ID:%@",response.invalidProductIdentifiers);
    NSLog(@"产品付费数量: %d", (int)[myProduct count]);
    // populate UI
    for(SKProduct *product in myProduct){
        NSLog(@"product info");
        NSLog(@"SKProduct 描述信息%@", [product description]);
        NSLog(@"产品标题 %@" , product.localizedTitle);
        NSLog(@"产品描述信息: %@" , product.localizedDescription);
        NSLog(@"价格: %@" , product.price);
        NSLog(@"Product id: %@" , product.productIdentifier);
    }
    SKPayment * payment = [SKPayment paymentWithProduct:myProduct[0]];
    NSLog(@"---------发送购买请求------------");
    [[SKPaymentQueue defaultQueue] addPayment:payment];
    
}

//弹出错误信息
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error{
    NSLog(@"-------弹出错误信息----------");
    UIAlertView *alerView =  [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Alert",NULL) message:[error localizedDescription]
                                                       delegate:nil cancelButtonTitle:NSLocalizedString(@"Close",nil) otherButtonTitles:nil];
    [alerView show];
    
}

-(void) requestDidFinish:(SKRequest *)request
{
    NSLog(@"----------反馈信息结束--------------");
}

#pragma mark - SKPaymentTransactionObserver
// 处理交易结果
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased://交易完成
                NSLog(@"transactionIdentifier = %@", transaction.transactionIdentifier);
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed://交易失败
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored://已经购买过该商品
                [self restoreTransaction:transaction];
                break;
            case SKPaymentTransactionStatePurchasing:      //商品添加进列表
                NSLog(@"商品添加进列表");
                break;
            default:
                break;
        }
    }
    
}

// 交易完成
- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    NSString * productIdentifier = transaction.payment.productIdentifier;
//    NSString * receipt = [transaction.transactionReceipt base64EncodedString];
    if ([productIdentifier length] > 0) {
        // 向自己的服务器验证购买凭证
    }
    
    // Remove the transaction from the payment queue.
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    
}

// 交易失败
- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    if(transaction.error.code != SKErrorPaymentCancelled) {
        NSLog(@"购买失败");
    } else {
        NSLog(@"用户取消交易");
    }
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

// 已购商品
- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    // 对于已购商品，处理恢复购买的逻辑
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

@end
