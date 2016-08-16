//
//  BLEPeripheralHelper.h
//  BluetoothDemo
//
//  Created by Chaosky on 16/3/4.
//  Copyright © 2016年 1000phone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

typedef void(^ReceiveCentralMsgBlock)(NSData * data);

@interface BLEPeripheralHelper : NSObject<CBPeripheralManagerDelegate>

@property (nonatomic, strong) CBCentral *central;//标示当前连接的中心

@property (nonatomic, assign) BOOL bluetoothConnectStatus;//当前蓝牙连接的状态，YES为连接，NO为没有连接

// 接收到的数据block回调
@property (nonatomic, copy) ReceiveCentralMsgBlock msgBlock;

//单例
+ (BLEPeripheralHelper *)sharedInstance;

// 开始广播数据
- (void)startAdvertising;
// 停止广播数据
- (void)stopAdvertising;

//写入数据
- (BOOL)writeData:(NSData *)data;

@end
