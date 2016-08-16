//
//  ViewController.m
//  iBeaconDemo
//
//  Created by Chaosky on 16/3/14.
//  Copyright (c) 2016年 1000phone. All rights reserved.
//

#import "ViewController.h"
//使用iBeacon需要添加2个库的支持
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#define UUID @"E2C56DB5-DFFB-48D2-B060-D0F5A71096E4"
#define IDENTIFIER [NSBundle mainBundle].bundleIdentifier


@interface ViewController ()<CLLocationManagerDelegate,CBPeripheralManagerDelegate>
{
    //建立服务端，只负责发送出去数据
    CLBeaconRegion*serverBeaconRegion;
    CBPeripheralManager*peripheralMsg;
    
    //建立客户端,只负责接收数据
    CLLocationManager * locationManager;
    CLBeaconRegion*findBeaconRegion;
    //对于商场应用，我们多数可能只需要客户端，而不一定需要服务端
    
    //我们还需要字典，记录发送端的返回数据
    NSMutableDictionary*regionData;
    
    //记录有多少个TextView
    int num;
    
}
@property (weak, nonatomic) IBOutlet UIButton *iBeaconServerButton;
- (IBAction)iBeaconServerAction:(UIButton *)sender;
@property (weak, nonatomic) IBOutlet UIButton *iBeaconClientButton;
- (IBAction)iBeaconClientAction:(UIButton *)sender;

@end

@implementation ViewController

- (IBAction)iBeaconServerAction:(UIButton *)sender {
    //初始创建服务端
    [self createServerBeacon];
}
- (IBAction)iBeaconClientAction:(UIButton *)sender {
    //初始创建客户端，执行发现服务
    [self createFindBeacon];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void)createServerBeacon{
    //服务端设置主频和副频 unsigned short最大数不超过65535
    //主频
    CLBeaconMajorValue major=1430;
    //副频
    CLBeaconMinorValue minor= arc4random_uniform(65535);
    //创建UUID
    NSUUID*user=[[NSUUID alloc]initWithUUIDString:UUID];
    
    //创建发现信息
    serverBeaconRegion=[[CLBeaconRegion alloc]initWithProximityUUID:user major:major minor:minor identifier:IDENTIFIER];
    //发现信息计算成字典
    regionData=[serverBeaconRegion peripheralDataWithMeasuredPower:nil];
    
    //创建服务
    peripheralMsg=[[CBPeripheralManager alloc]initWithDelegate:self queue:dispatch_get_main_queue()];
}

-(void)createFindBeacon{
    //不用设置主频和副频，需要设置UUID
    NSUUID *user=[[NSUUID alloc]initWithUUIDString:UUID];
    //注意这里初始化和服务端的初始化有所区别
    findBeaconRegion=[[CLBeaconRegion alloc]initWithProximityUUID:user identifier:IDENTIFIER];
    locationManager=[[CLLocationManager alloc]init];
    locationManager.delegate=self;
    // NSLocationAlwaysUsageDescription
    // 请求用户权限
    [locationManager requestAlwaysAuthorization];
    //开启搜索
    [locationManager startRangingBeaconsInRegion:findBeaconRegion];
    [locationManager startMonitoringForRegion:findBeaconRegion];
    [locationManager requestStateForRegion:findBeaconRegion];
}

#pragma mark - CBPeripheralManagerDelegate

-(void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    //检测状态
    if (peripheral.state==CBPeripheralManagerStatePoweredOn) {
        //可以开始
        [peripheralMsg startAdvertising:regionData];
    }else{
        if (peripheral.state==CBPeripheralManagerStatePoweredOff) {
            //关闭
            [peripheral stopAdvertising];
            
        }
    }
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusAuthorizedAlways) {
        //开启iBeacon搜索
        [manager startRangingBeaconsInRegion:findBeaconRegion];
        [manager startMonitoringForRegion:findBeaconRegion];
        [manager requestStateForRegion:findBeaconRegion];
    }
    
}

-(void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    //近距离回调，有三个状态，三个状态分别在我们距离1米以内的时候触发
    if (state==CLRegionStateInside) {
        //在1米以内
    }else{
        if (state==CLRegionStateOutside) {
            //在1米以外
        }else{
            //不知道CLRegionStateUnknown;
            
        }
    }
}
-(void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    //该方法在推出后台，并且锁屏情况下依然可以触发，我们可以设置当我们进入后台时候，设置本地推送来提示用户进入一个范围即可
    //判断是否在后台
    UIApplicationState back=[UIApplication sharedApplication].applicationState;
    if (back==UIApplicationStateBackground) {
        //在后台，我们需要执行推送告知用户
        UILocalNotification*local=[[UILocalNotification alloc]init];
        //设置时间
        local.fireDate=[NSDate date];
        //设置文字
        local.alertBody=@"我们进入一个店铺";
        //加入推送
        [[UIApplication sharedApplication]scheduleLocalNotification:local];
        
        
    }
    
    NSLog(@"进入了一个iBeacon，欢迎光临");
    
}
-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    NSLog(@"离开了一个iBeacon，欢迎再次光临");
}
-(void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    //扫描结果
    NSLog(@"扫描结果，该函数会一直调用");
    
    for (int i=0; i<beacons.count; i++) {
        //读取灯塔
        CLBeacon*beacon=beacons[i];
        //其中的数据转换为字符串
        NSString*message= [self beaconValue:beacon];
        
        NSLog(@"beacon~~~%@",message);
        
        //设置复用过程
        UITextView*textView=(UITextView*)[self.view viewWithTag:beacon.minor.integerValue];
        if (textView) {
            textView.text=message;
        }else{
            //创建
            
            textView=[[UITextView alloc]initWithFrame:CGRectMake(num%3*110, num/3*200+64, 100, 190)];
            textView.backgroundColor=[UIColor blackColor];
            textView.textColor=[UIColor whiteColor];
            //复用的关键
            textView.tag=beacon.minor.integerValue;
            [self.view addSubview:textView];
            //设置num+1
            num=num+1;
            textView.text=message;
            
        }
        
    }
    
    
    
    
}
-(NSString*)beaconValue:(CLBeacon*)beacon{
    //获取主频和副频
    NSString*major=beacon.major.stringValue;
    NSString*minor=beacon.minor.stringValue;
    //获取距离
    NSString*acc=[NSString stringWithFormat:@"%lf",beacon.accuracy];
    //获取感知，当距离非常近的时候告诉我接近程度 proximity是一个枚举
    NSString*px=[NSString stringWithFormat:@"%ld",beacon.proximity];
    //信号强度
    NSString*rssi=[NSString stringWithFormat:@"%ld",beacon.rssi];
    
    //组装字符串
    NSString*message=[NSString stringWithFormat:@"主频~%@\n副频~%@\n距离~%@\n感知~%@\n信号强度~%@\n",major,minor,acc,px,rssi];
    
    return message;
}
-(void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    NSLog(@"扫描失败");
    //当扫描启动失败以后，也就是用户没有开启蓝牙导致的失败，我们需要提示用户如何打开iBeacon，这个过程其实是诱导用户打开，判断是否在后台如果在后台就不进行任何操作了
    //该功能在iOS7下的各个版本表现不一样，iOS7.0时候启动失败，就算打开蓝牙开关也无效，只能通过重启手机办法才可以做到，iOS7.1.2的时候，苹果明确说明了特意修复了该功能，但是实际表现结果依然差劲，还是需要重启解决，但是这个说明在上线时候，苹果对审核的时候，也表示可以理解，并在会发一封致歉信给苹果开发者
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
