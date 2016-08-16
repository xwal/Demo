//
//  CentralTableViewController.m
//  ITAGDemo
//
//  Created by Chaosky on 16/5/26.
//  Copyright © 2016年 1000phone. All rights reserved.
//

#import "CentralTableViewController.h"
// 蓝牙通信的头文件
#import <CoreBluetooth/CoreBluetooth.h>

@interface CentralTableViewController ()<CBCentralManagerDelegate, CBPeripheralDelegate>
// 扫描外设
- (IBAction)scanAction:(UIBarButtonItem *)sender;
// 报警
- (IBAction)alertAction:(UIBarButtonItem *)sender;
// 取消报警
- (IBAction)cancelAlertAction:(UIBarButtonItem *)sender;

#pragma mark - 蓝牙对象
// 中心管理对象
@property (nonatomic, strong) CBCentralManager * centralManager;
// 存储扫描到外设
@property (nonatomic, strong) NSMutableArray * peripheralArray;
// 记录连接成功的外设
@property (nonatomic, strong) CBPeripheral * connectedPeripheral;
// 记录报警/解除报警的特征
@property (nonatomic, strong) CBCharacteristic * alertCharacteristic;
// 记录蓝牙防丢器按钮点击的特征
@property (nonatomic, strong) CBCharacteristic * keyPressCharacteristic;
@end

@implementation CentralTableViewController

// 懒加载
- (NSMutableArray *)peripheralArray
{
    if (!_peripheralArray) {
        _peripheralArray = [NSMutableArray array];
    }
    return _peripheralArray;
}

// 创建中心角色
- (void)createCentralManager
{
    // 参数1：委托
    // 参数2：协议方法执行的队列，nil表示主队列
    // 参数3：配置选项
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:@{CBCentralManagerOptionShowPowerAlertKey : @YES}];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [self createCentralManager];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.peripheralArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CELL" forIndexPath:indexPath];
    
    // Configure the cell...
    
    cell.textLabel.font = [UIFont systemFontOfSize:18];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:16];
    
    CBPeripheral * peripheral = self.peripheralArray[indexPath.row];
    
    cell.textLabel.text = peripheral.name;
    cell.detailTextLabel.text = peripheral.identifier.UUIDString;
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CBPeripheral * peripheral = self.peripheralArray[indexPath.row];
    // 3. 连接外设
    [self.centralManager connectPeripheral:peripheral options:nil];
}


- (IBAction)scanAction:(UIBarButtonItem *)sender {
    // 参数1：指定包含特定服务UUID的外设，只去扫描包含这些服务的外设
    // 参数2：选项参数，CBCentralManagerScanOptionAllowDuplicatesKey 是否允许重复出现，默认YES
    [self.centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES}];
}

- (IBAction)alertAction:(UIBarButtonItem *)sender {
    if (!self.alertCharacteristic) {
        return;
    }
    int alertNum = 0x02;
    NSData * alertData = [NSData dataWithBytes:&alertNum length:1];
    // 往外设中指定的特征写入数据
    [self.connectedPeripheral writeValue:alertData forCharacteristic:self.alertCharacteristic type:CBCharacteristicWriteWithoutResponse];
}

- (IBAction)cancelAlertAction:(UIBarButtonItem *)sender {
    if (!self.alertCharacteristic) {
        return;
    }
    int alertNum = 0x00;
    NSData * alertData = [NSData dataWithBytes:&alertNum length:1];
    // 往外设中指定的特征写入数据
    [self.connectedPeripheral writeValue:alertData forCharacteristic:self.alertCharacteristic type:CBCharacteristicWriteWithoutResponse];
}

#pragma mark - CBCentralManagerDelegate
/**
 *  蓝牙状态变更的回调
 *
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case CBCentralManagerStateUnknown: {
            NSLog(@"蓝牙设备未知");
            break;
        }
        case CBCentralManagerStateResetting: {
            NSLog(@"蓝牙设备重置中");
            break;
        }
        case CBCentralManagerStateUnsupported: {
            NSLog(@"当前设备不支持蓝牙");
            break;
        }
        case CBCentralManagerStateUnauthorized: {
            NSLog(@"未授权");
            break;
        }
        case CBCentralManagerStatePoweredOff: {
            NSLog(@"蓝牙关闭");
            break;
        }
        case CBCentralManagerStatePoweredOn: {
            NSLog(@"蓝牙开启");
            break;
        }
    }
}

/**
 *  扫描到外设
 *
 *  @param central
 *  @param peripheral        扫描到的外设对象
 *  @param advertisementData 字典，广告包数据
 *  @param RSSI              信号强度
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"advertisementData = %@", advertisementData);
    NSLog(@"RSSI = %@", RSSI);
    
    // 判断数组中是否已存在
    BOOL isFind = NO;
    for (CBPeripheral * temp in self.peripheralArray) {
        // 判断UUID是否一致
        if ([temp.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]) {
            // 找到相同，替换
            NSUInteger index = [self.peripheralArray indexOfObject:temp];
            [self.peripheralArray replaceObjectAtIndex:index withObject:peripheral];
            isFind = YES;
            break;
        }
    }
    // 在数组不存在
    if (!isFind) {
        // 将新扫描到外设添加到数组中
        [self.peripheralArray addObject:peripheral];
    }
    // 显示出来，刷新视图
    [self.tableView reloadData];
    
}

/**
 *  连接外设成功的回调
 *
 *  @param central
 *  @param peripheral
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    // 停止扫描外设
    [self.centralManager stopScan];
    
    NSString * msg = [NSString stringWithFormat:@"外设连接成功，设备名：%@ UUID：%@", peripheral.name, peripheral.identifier.UUIDString];
    UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"连接外设" message:msg delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alertView show];
    
    self.connectedPeripheral = peripheral;
    
    // 设置委托
    self.connectedPeripheral.delegate = self;
    // 扫描服务和特征
    [self.connectedPeripheral discoverServices:nil];
}

/**
 *  连接外设失败
 *
 *  @param central
 *  @param peripheral
 *  @param error
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    
}

#pragma mark - CBPeripheralDelegate
/**
 *  扫描外设中可用的服务
 *
 *  @param peripheral 外设对象
 *  @param error      错误信息
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        NSLog(@"%s error = %@", __func__, error.localizedDescription);
        return;
    }
    // 遍历所有服务
    for (CBService * service in peripheral.services) {
        NSLog(@"service UUID = %@", service.UUID.UUIDString);
        // 扫描服务中包含的特征
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

/**
 *  扫描到外设中指定服务的特征
 *
 *  @param peripheral 外设
 *  @param service    服务
 *  @param error      错误信息
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error) {
        NSLog(@"%s error = %@", __func__, error.localizedDescription);
        return;
    }
    // 遍历服务中所有特征
    for (CBCharacteristic * characteristic in service.characteristics) {
        // 判断报警的特征
        if ([service.UUID.UUIDString isEqualToString:@"1802"] && [characteristic.UUID.UUIDString isEqualToString:@"2A06"]) {
            self.alertCharacteristic = characteristic;
        }
        // 判断按钮点击的特征
        if ([service.UUID.UUIDString isEqualToString:@"FFE0"] && [characteristic.UUID.UUIDString isEqualToString:@"FFE1"]) {
            self.keyPressCharacteristic = characteristic;
            // 监听特征的变化，notify属性的特征
            [peripheral setNotifyValue:YES forCharacteristic:self.keyPressCharacteristic];
        }
        
        NSLog(@"characteristic UUID = %@", characteristic.UUID);
        // 扫描特征中的描述
        [peripheral discoverDescriptorsForCharacteristic:characteristic];
    }
}

/**
 *  扫描到特征中所有描述
 *
 *  @param peripheral     外设
 *  @param characteristic 特征
 *  @param error          错误信息
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"%s error = %@", __func__, error.localizedDescription);
        return;
    }
    // 遍历特征中的所有描述
    for (CBDescriptor * descriptor in characteristic.descriptors) {
        NSLog(@"descriptor UUID = %@", descriptor.UUID.UUIDString);
    }
}

/**
 *  当特征中的值变化时的回调方法
 *
 *  @param peripheral     外设
 *  @param characteristic 特征
 *  @param error          错误信息
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"%s error = %@", __func__, error.localizedDescription);
        return;
    }
    if (characteristic == self.keyPressCharacteristic) {
        static int count = 0;
        count++;
        NSLog(@"蓝牙防丢器点击 %d 次", count);
        // 创建本地通知
        UILocalNotification * localNotif = [[UILocalNotification alloc] init];
        // 属性
        localNotif.alertBody = @"蓝牙防丢器找手机，么么哒";
        localNotif.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];
        localNotif.soundName = UILocalNotificationDefaultSoundName;
        // 添加到系统队列中
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
    }
}

@end
