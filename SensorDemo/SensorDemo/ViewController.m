//
//  ViewController.m
//  SensorDemo
//
//  Created by Chaosky on 16/1/28.
//  Copyright (c) 2016年 1000phone. All rights reserved.
//

#import "ViewController.h"
#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>

@interface ViewController ()<CLLocationManagerDelegate>

@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, strong) CMStepCounter * stepCounter;
@property (nonatomic, strong) CMPedometer * pedometer;
@property (nonatomic, strong) CLLocationManager * locationManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


#pragma mark - Proximity Sensor
- (IBAction)setupProximitySensor
{
    // 开启距离感应功能
    [UIDevice currentDevice].proximityMonitoringEnabled = YES;
    // 监听距离感应的通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(proximityChange:)
                                                 name:UIDeviceProximityStateDidChangeNotification
                                               object:nil];
}

- (void)proximityChange:(NSNotification *)notification {
    if ([UIDevice currentDevice].proximityState == YES) {
        NSLog(@"某个物体靠近了设备屏幕"); // 屏幕会自动锁住
    } else {
        NSLog(@"某个物体远离了设备屏幕"); // 屏幕会自动解锁
    }
}

#pragma mark - Magnetometer Sensor
- (IBAction)setupMagnetometerSensor
{
    self.locationManager = [[CLLocationManager alloc] init];
    // 请求用户权限
    [self.locationManager requestWhenInUseAuthorization];
    // 设置委托
    self.locationManager.delegate = self;
    // 启动磁力感应
    [self.locationManager startUpdatingHeading];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [manager startUpdatingHeading];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    NSLog(@"指南针：%@", newHeading);
}


#pragma mark - Ambient Light Sensor
- (IBAction)setupAmbientLightSensor
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ambientLightChange:) name:UIScreenBrightnessDidChangeNotification object:nil];
}

- (void)ambientLightChange:(NSNotification *) notif
{
    NSLog(@"notif = %@", notif);
}

#pragma mark - Accelerometer
- (IBAction)pushAccelerometer
{
    // 创建运动管理者对象
    if (!_motionManager) {
        _motionManager = [[CMMotionManager alloc] init];
    }
    // 判断加速计是否可用（最好判断）
    if (_motionManager.isAccelerometerAvailable) {
        // 加速计可用
        // 设置加速计采样频率
        _motionManager.accelerometerUpdateInterval = 1.0/30.0; // 1秒钟采样30次
        
        // 开始采样（采样到数据就会调用handler，handler会在queue中执行）
        [_motionManager startAccelerometerUpdatesToQueue:[[NSOperationQueue alloc] init] withHandler:^(CMAccelerometerData * accelerometerData, NSError * error) {
            CMAcceleration acceleration = accelerometerData.acceleration;
            NSLog(@"CMAcceleration: %f--%f--%f", acceleration.x, acceleration.y, acceleration.z);
        }];
    }
    else {
        // 加速度计不能用
        NSLog(@"加速度计不能用");
    }
}

- (void)pullAccelerometer
{
    // 创建运动管理者对象
    if (!_motionManager) {
        _motionManager = [[CMMotionManager alloc] init];
    }
    // 判断加速计是否可用（最好判断）
    if (_motionManager.isAccelerometerAvailable) {
        // 加速计可用
        
        // 设置加速计采样频率
        _motionManager.accelerometerUpdateInterval = 1.0/30.0; // 1秒钟采样30次
        // 开始采样
        [_motionManager startAccelerometerUpdates];
    }
    
    // 在需要的时候采集加速度数据
    CMAcceleration acceleration = _motionManager.accelerometerData.acceleration;
    NSLog(@"%f, %f, %f", acceleration.x, acceleration.y, acceleration.z);
}

#pragma mark - Gyroscope

- (IBAction)pushGyroscope
{
    // 创建运动管理者对象
    if (!_motionManager) {
        _motionManager = [[CMMotionManager alloc] init];
    }
    // 判断陀螺仪是否可用
    if (_motionManager.gyroAvailable) {
        // 设置采样频率
        _motionManager.gyroUpdateInterval = 1 / 10.0; // 1秒钟采样10次
        // 开始采样
        [_motionManager startGyroUpdatesToQueue:[[NSOperationQueue alloc] init] withHandler:^(CMGyroData * gyroData, NSError * error) {
            // 获取陀螺仪的信息
            CMRotationRate rotationRate = gyroData.rotationRate;
            NSLog(@"x:%f y:%f z:%f", rotationRate.x, rotationRate.y, rotationRate.z);
        }];
    }
    else {
        // 陀螺仪不能用
        NSLog(@"陀螺仪不能用");
    }
}

- (void)pullGyroscope
{
    // 创建运动管理者对象
    if (!_motionManager) {
        _motionManager = [[CMMotionManager alloc] init];
    }
    // 判断陀螺仪是否可用
    if (_motionManager.gyroAvailable) {
        // 设置采样频率
        _motionManager.gyroUpdateInterval = 1 / 10.0; // 1秒钟采样10次
        // 开始采样
        [_motionManager startGyroUpdates];
    }
    else {
        // 陀螺仪不能用
        NSLog(@"陀螺仪不能用");
    }
    
    // 在需要的时候采集加速度数据
    CMRotationRate rotationRate = _motionManager.gyroData.rotationRate;
    NSLog(@"x:%f y:%f z:%f", rotationRate.x, rotationRate.y, rotationRate.z);
}

#pragma mark - StepCounter
- (IBAction)stepCount
{
    // 判断当前系统版本，iOS 8 之后CMStepCounter废弃了
    if ([[UIDevice currentDevice].systemVersion floatValue] < 8.0)
    {
        // 1.判断计步器是否可用
        if (![CMStepCounter isStepCountingAvailable]) {
            NSLog(@"计步器不可用");
            return;
        }

        // 创建计步器
        if (!_stepCounter) {
            _stepCounter = [[CMStepCounter alloc] init];
        }
        
        // 开始计步
        // updateOn : 用户走了多少步之后, 更新block
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        [_stepCounter startStepCountingUpdatesToQueue:queue updateOn:5 withHandler:^(NSInteger numberOfSteps, NSDate * timestamp, NSError * error) {
            if (error) {
                NSLog(@"%@", error);
                return;
            }
            NSLog(@"一共走了%ld步", numberOfSteps);
        }];
    }
    else {
        // 判断计步器是否可用
        if (![CMPedometer isStepCountingAvailable]) {
            return;
        }
        
        // 创建计步器
        if (!_pedometer) {
            _pedometer = [[CMPedometer alloc] init];
        }
        
        // 开始计步
        // FromDate : 从什么时间开始计步
        NSDate *date = [NSDate date];
        [_pedometer startPedometerUpdatesFromDate:date withHandler:^(CMPedometerData * pedometerData, NSError * error) {
            if (error) {
                NSLog(@"%@", error);
                return;
            }
            NSLog(@"您一共走了%@步", pedometerData.numberOfSteps);
        }];
        
        // 计算两个时间间隔走了多少步
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        fmt.dateFormat = @"yyyy-MM-dd";
        NSDate *fromDate = [fmt dateFromString:@"2015-9-26"];
        NSDate *toDate = [fmt dateFromString:@"2016-1-28"];
        [_pedometer queryPedometerDataFromDate:fromDate toDate:toDate withHandler:^(CMPedometerData * pedometerData, NSError * error) {
            
            NSLog(@"从%@到%@期间，总共走了%@步，总长%@米，上楼%@层，下楼%@层", pedometerData.startDate, pedometerData.endDate, pedometerData.numberOfSteps, pedometerData.distance, pedometerData.floorsAscended, pedometerData.floorsDescended);
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
