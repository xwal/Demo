//
//  ViewController.m
//  MCDemo
//
//  Created by Chaosky on 16/3/13.
//  Copyright (c) 2016年 1000phone. All rights reserved.
//

#import "ViewController.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface ViewController ()<MCSessionDelegate,MCBrowserViewControllerDelegate,MCAdvertiserAssistantDelegate,MCNearbyServiceBrowserDelegate,UITextFieldDelegate>
{
    /*
     //收数据
     MCSessionDelegate
     //搜索列表点击是否完成
     MCBrowserViewControllerDelegate
     //广播服务
     MCAdvertiserAssistantDelegate
     //发现服务
     MCNearbyServiceBrowserDelegate
     
     //区别MCNearbyServiceAdvertiser这个只能负责广播，并不能负责连接
     */
    //标示
    MCPeerID * _peerID;
    
    //负责类似socket的形式的连接
    MCSession * _session;
    //显示发现的列表
    MCBrowserViewController * _browserViewController;
    //广播
    MCAdvertiserAssistant*_advertiser;
    //发现服务
    MCNearbyServiceBrowser*_browser;
}
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property(nonatomic,strong)NSMutableArray*sessionArray;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.sessionArray = [NSMutableArray arrayWithCapacity:0];
    [self createView];
    [self createMC];
}

- (void)createView
{
    self.textField.delegate = self;
}

//发送消息
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField.text.length>0) {
        //发送消息
        //        MCSessionSendDataReliable 可靠连接类似TCP
        //        MCSessionSendDataUnreliable 不可靠连接类似UDP
        [_session sendData:[textField.text dataUsingEncoding:NSUTF8StringEncoding] toPeers:_session.connectedPeers withMode:MCSessionSendDataUnreliable error:nil];
        _textView.text=[NSString stringWithFormat:@"%@我说：%@\n",_textView.text,_textField.text];
        textField.text=nil;
    }
    return YES;
}

- (void)createMC
{
    //首先创建标示
    //可以获取设备的名称,模拟器上会直接显示模拟器
    NSString * name = [UIDevice currentDevice].name;
    //标示
    _peerID=[[MCPeerID alloc]initWithDisplayName:name];
    //建立连接的
    _session=[[MCSession alloc]initWithPeer:_peerID];
    //设置代理
    _session.delegate=self;
    //设置广播服务
    _advertiser=[[MCAdvertiserAssistant alloc]initWithServiceType:@"type" discoveryInfo:nil session:_session];
    //开始广播
    [_advertiser start];
    
    //设置发现服务
    _browser=[[MCNearbyServiceBrowser alloc]initWithPeer:_peerID serviceType:@"type"];
    _browser.delegate=self;
    //开始发现
    [_browser startBrowsingForPeers];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - MCNearbyServiceBrowserDelegate
// 发现附近的广播者
-(void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    //发现到广播
    NSLog(@"昵称~~%@",peerID.displayName);
    
    if (_browserViewController==nil) {
        _browserViewController=[[MCBrowserViewController alloc]initWithServiceType:@"type" session:_session];
        _browserViewController.delegate=self;
        [self presentViewController:_browserViewController animated:YES completion:nil];
    }
    
}
// 附近的广播者停止广播
-(void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    NSLog(@"离开者是~~%@",peerID.displayName);
}

// 发现服务出错
- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error
{
    NSLog(@"Error = %@", error.localizedDescription);
}

#pragma mark - MCBrowserViewControllerDelegate

-(void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController
{
    //点击完成返回
    [self dismissViewControllerAnimated:YES completion:nil];
    _browserViewController=nil;
    //关闭广播服务，停止别人发现我
    [_advertiser stop];
}
-(void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController
{
    //点击取消返回
    [self dismissViewControllerAnimated:YES completion:nil];
    _browserViewController=nil;
    //关闭广播服务，停止别人发现我
    [_advertiser stop];
}

#pragma mark - MCSessionDelegate
-(void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    if (state==MCSessionStateConnected) {
        //保存这个session
        if (![self.sessionArray containsObject:session]) {
            //追加
            [self.sessionArray addObject:session];
        }
    }
}

// 从对端收到二进制数据
-(void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    NSString*message=[NSString stringWithFormat:@"%@说：%@\n",peerID.displayName,[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]];
    //这里是分线程，需要回归主线程
    dispatch_async(dispatch_get_main_queue(), ^{
        _textView.text=[NSString stringWithFormat:@"%@%@",_textView.text,message];
    });
    
}

@end
