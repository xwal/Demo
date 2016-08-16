//
//  ViewController.m
//  ApplePayDemo
//
//  Created by Chaosky on 16/8/8.
//  Copyright © 2016年 1000phone. All rights reserved.
//

#import "ViewController.h"

// Apple Pay 支付框架：PassKit.framework
#import <PassKit/PassKit.h>

@interface ViewController ()<PKPaymentAuthorizationViewControllerDelegate>

@property (nonatomic, strong) PKPaymentButton * paymentButton;

@property (nonatomic, strong) PKContact * selectedContact;

@property (nonatomic, strong) PKShippingMethod * selectedShippingMethod;

@property (nonatomic, strong) NSArray * summaryItems;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // 银行卡类型
    NSArray * supportedNetworks = @[PKPaymentNetworkChinaUnionPay, PKPaymentNetworkPrivateLabel, PKPaymentNetworkInterac];
    
    // 判断是否支持Apple Pay
    if ([PKPaymentAuthorizationViewController canMakePayments]) {
        self.paymentButton = [PKPaymentButton buttonWithType:PKPaymentButtonTypeBuy style:PKPaymentButtonStyleWhiteOutline];
        [self.paymentButton addTarget:self action:@selector(paymentTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    else if ([PKPaymentAuthorizationViewController canMakePaymentsUsingNetworks:supportedNetworks]) {
        // 添加银行卡
        self.paymentButton = [[PKPaymentButton alloc] initWithPaymentButtonType:PKPaymentButtonTypeSetUp paymentButtonStyle:PKPaymentButtonStyleWhiteOutline];
        [self.paymentButton addTarget:self action:@selector(paymentSetupTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    if (self.paymentButton != nil) {
        [self.view addSubview:self.paymentButton];
        self.paymentButton.center = CGPointMake(200, 100);
    }
}

- (void)paymentSetupTapped:(PKPaymentButton *) sender {
    // 判断是否打开卡包
    if ([PKPassLibrary isPassLibraryAvailable]) {
        PKPassLibrary * pk = [[PKPassLibrary alloc] init];
        [pk openPaymentSetup];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)paymentTapped:(PKPaymentButton *) sender {
    // 创建支付请求
    PKPaymentRequest * paymentRequest = [[PKPaymentRequest alloc] init];
    
    // 配置商家ID
    paymentRequest.merchantIdentifier = @"merchant.me.chaosky.applepay";
    
    // 配置货币代码及国家代码
    paymentRequest.currencyCode = @"CNY";
    paymentRequest.countryCode = @"CN";
    
    // 支持的支付网络，用户能使用类型的银行卡
    paymentRequest.supportedNetworks = @[PKPaymentNetworkChinaUnionPay, PKPaymentNetworkPrivateLabel];
    
    // 商家支付能力，商家的支付网络
    paymentRequest.merchantCapabilities = PKMerchantCapability3DS | PKMerchantCapabilityEMV;
    
    // 是否显示发票收货地址
    paymentRequest.requiredBillingAddressFields = PKAddressFieldNone;
    
    // 是否显示快递地址
    paymentRequest.requiredShippingAddressFields = PKAddressFieldAll;
    
    
    // 自定义联系信息
    PKContact *contact = [[PKContact alloc] init];
    
    NSPersonNameComponents *name = [[NSPersonNameComponents alloc] init];
    name.givenName = @"天祥";
    name.familyName = @"林";
    contact.name = name;
    
    CNMutablePostalAddress *address = [[CNMutablePostalAddress alloc] init];
    address.street = @"天府广场";
    address.city = @"成都";
    address.state = @"四川";
    address.postalCode = @"614100";
    contact.postalAddress = address;
    
    contact.emailAddress = @"chaosky.me@gmail.com";
    contact.phoneNumber = [CNPhoneNumber phoneNumberWithStringValue:@"1234567890"];
    paymentRequest.shippingContact = contact;
    
    // 配送方式
    paymentRequest.shippingMethods = [self shippingMethodsForContact:contact];
    
    // 默认配送类型
    paymentRequest.shippingType = PKShippingTypeShipping;
    
    // 更新邮费
    self.selectedShippingMethod = paymentRequest.shippingMethods[0];
    [self updateShippingCost:self.selectedShippingMethod];
    
    // 支付汇总项
    paymentRequest.paymentSummaryItems = self.summaryItems;
    
    // 附加数据
    paymentRequest.applicationData = [@"buyid=123456" dataUsingEncoding:NSUTF8StringEncoding];
    
    // 验证用户支付授权
    PKPaymentAuthorizationViewController * paymentAuthVC = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:paymentRequest];
    paymentAuthVC.delegate = self;
    
    [self presentViewController:paymentAuthVC animated:YES completion:nil];
}

// 更新邮费
- (void)updateShippingCost:(PKShippingMethod *) shippingMethod {
    // 支付汇总项
    // 12.75 小计
    NSDecimalNumber * subtotalAmount = [NSDecimalNumber decimalNumberWithMantissa:1275 exponent:-2 isNegative:NO];
    PKPaymentSummaryItem * subtotal = [PKPaymentSummaryItem summaryItemWithLabel:@"小计" amount:subtotalAmount];
    
    // 2.00 折扣优惠
    NSDecimalNumber * discountAmount = [NSDecimalNumber decimalNumberWithMantissa:200 exponent:-2 isNegative:YES];
    PKPaymentSummaryItem * discount = [PKPaymentSummaryItem summaryItemWithLabel:@"折扣" amount:discountAmount];
    
    // 邮费
    PKPaymentSummaryItem * shippingCost = [PKPaymentSummaryItem summaryItemWithLabel:@"邮费" amount:shippingMethod.amount];
    
    // 总计项
    // 总计
    NSDecimalNumber *totalAmount = [NSDecimalNumber zero];
    totalAmount = [totalAmount decimalNumberByAdding:subtotal.amount];
    totalAmount = [totalAmount decimalNumberByAdding:discount.amount];
    totalAmount = [totalAmount decimalNumberByAdding:shippingCost.amount];
    PKPaymentSummaryItem * total = [PKPaymentSummaryItem summaryItemWithLabel:@"千锋互联" amount:totalAmount];
    
    self.summaryItems = @[subtotal, discount, shippingCost, total];
}

// 根据用户地址获取配送方式
- (NSArray *)shippingMethodsForContact:(PKContact *) contact {
    //配置快递方式
    NSDecimalNumber * sfAmount = [NSDecimalNumber decimalNumberWithString:@"20.00"];
    PKShippingMethod * sfShipping = [PKShippingMethod summaryItemWithLabel:@"顺丰" amount:sfAmount];
    sfShipping.identifier = @"shunfeng";
    sfShipping.detail = @"24小时内送达";
    
    NSDecimalNumber * stAmount = [NSDecimalNumber decimalNumberWithString:@"10.00"];
    PKShippingMethod * stShipping = [PKShippingMethod summaryItemWithLabel:@"申通" amount:stAmount];
    stShipping.identifier = @"shentong";
    stShipping.detail = @"3天内送达";
    
    NSDecimalNumber * tcAmount = [NSDecimalNumber decimalNumberWithString:@"8.00"];
    PKShippingMethod * tcShipping = [PKShippingMethod summaryItemWithLabel:@"同城快递" amount:tcAmount];
    tcShipping.identifier = @"tongcheng";
    tcShipping.detail = @"12小时送达";
    
    NSArray * shippingMethods = nil;
    if ([contact.postalAddress.city isEqualToString:@"成都"]) {
        shippingMethods = [NSArray arrayWithObjects:sfShipping, stShipping, tcShipping, nil];
    }
    else {
        shippingMethods = @[sfShipping, stShipping];
    }
    
    return shippingMethods;
}

#pragma mark - PKPaymentAuthorizationViewControllerDelegate

// 用户更改配送地址
- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller didSelectShippingContact:(PKContact *)contact completion:(void (^)(PKPaymentAuthorizationStatus, NSArray<PKShippingMethod *> * _Nonnull, NSArray<PKPaymentSummaryItem *> * _Nonnull))completion {
    self.selectedContact = contact;
    
    NSArray *shippingMethods = [self shippingMethodsForContact:contact];
    // 重新计算邮费
    self.selectedShippingMethod = shippingMethods[0];
    [self updateShippingCost:self.selectedShippingMethod];
    
    completion(PKPaymentAuthorizationStatusSuccess, shippingMethods, self.summaryItems);
}

// 用户更改配送方式
- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller didSelectShippingMethod:(PKShippingMethod *)shippingMethod completion:(void (^)(PKPaymentAuthorizationStatus, NSArray<PKPaymentSummaryItem *> * _Nonnull))completion {
    self.selectedShippingMethod = shippingMethod;
    [self updateShippingCost: shippingMethod];
    completion(PKPaymentAuthorizationStatusSuccess, self.summaryItems);
}

- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller didAuthorizePayment:(PKPayment *)payment completion:(void (^)(PKPaymentAuthorizationStatus))completion
{
    // 将付款信息与其它处理订单的必需信息一起发送至你的服务器。如支付令牌、配送地址、账单地址。
    // ...
    // ...
    
    // 从你的服务器获取支付授权状态，验证支付结果
    PKPaymentAuthorizationStatus status = PKPaymentAuthorizationStatusSuccess;
    completion(status);
}

@end
