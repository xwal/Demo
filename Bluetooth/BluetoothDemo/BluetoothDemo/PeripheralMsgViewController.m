//
//  PeripheralViewController.m
//  BluetoothDemo
//
//  Created by Chaosky on 16/3/13.
//  Copyright © 2016年 1000phone. All rights reserved.
//

#import "PeripheralMsgViewController.h"
#import "BLEPeripheralHelper.h"

@interface PeripheralMsgViewController ()<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextView *msgTextView;
@property (weak, nonatomic) IBOutlet UITextField *msgTextField;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *msgTextFieldBottomOutlet;

@end

@implementation PeripheralMsgViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showKeyBoard:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideKeyBoard:) name:UIKeyboardWillHideNotification object:nil];
    self.msgTextField.delegate = self;
    
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap)];
    [self.msgTextView addGestureRecognizer:tap];
    
    __weak typeof(self) weakSelf = self;
   
    [BLEPeripheralHelper sharedInstance].msgBlock = ^(NSData * data) {
         NSString * centralName = [BLEPeripheralHelper sharedInstance].central.identifier.UUIDString;
        NSString * msgStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        weakSelf.msgTextView.text = [NSString stringWithFormat:@"%@%@说：%@\n", self.msgTextView.text, centralName, msgStr];
    };
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[BLEPeripheralHelper sharedInstance] startAdvertising];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[BLEPeripheralHelper sharedInstance] stopAdvertising];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)showKeyBoard:(NSNotification *) notify {
    NSLog(@"%@", notify);
    [UIView animateWithDuration:0.25 animations:^{
        self.msgTextFieldBottomOutlet.constant = 258;
    }];
    
}

- (void)hideKeyBoard:(NSNotification *) notify {
    NSLog(@"%@", notify);
    [UIView animateWithDuration:0.25 animations:^{
        self.msgTextFieldBottomOutlet.constant = 0;
    }];
}

- (void)onTap {
    [self.msgTextField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSString * msg = self.msgTextField.text;
    [[BLEPeripheralHelper sharedInstance] writeData:[msg dataUsingEncoding:NSUTF8StringEncoding]];
    self.msgTextView.text = [NSString stringWithFormat:@"%@我说：%@\n", self.msgTextView.text, msg];
    textField.text = nil;
    return YES;
}
@end
