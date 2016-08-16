//
//  BluetoothHelper.h
//  BluetoothDemo
//
//  Created by Chaosky on 15/12/30.
//  Copyright © 2015年 1000phone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

typedef void(^DevicesUpdateBlock)(NSArray * devices);
typedef void(^ReceivePeripheralMsgBlock)(NSData * data);

@interface BLECentralHelper : NSObject<CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, strong) CBPeripheral *peripheral;//标示当前连接的外围设备

@property (nonatomic, assign) BOOL bluetoothConnectStatus;//当前蓝牙连接的状态，YES为连接，NO为没有连接

@property (nonatomic, copy) DevicesUpdateBlock devicesBlock; // 当有新的外围设备发现时，会通知列表视图刷新
@property (nonatomic, copy) ReceivePeripheralMsgBlock msgBlock; // 获取外设的通知信息


//单例
+ (BLECentralHelper *)sharedInstance;

//扫描搜索蓝牙
- (void)scanForBluetooth;

//停止扫描
- (void)stopScanForBluetooth;

//连接到指定的外围
- (void)connectToPeripheral:(CBPeripheral *)peripheral;

//写入数据
- (void)writeData:(NSData *)data;

@end
