//
//  BluetoothHelper.m
//  BluetoothDemo
//
//  Created by Chaosky on 15/12/30.
//  Copyright © 2015年 1000phone. All rights reserved.
//

#import "BLECentralHelper.h"

@interface BLECentralHelper()

@property (nonatomic, strong) CBCentralManager *manager;//本地中央
@property (nonatomic, strong) NSMutableArray *nDevices;//搜索到的外围设备
@property (nonatomic, strong) CBCharacteristic *writeCharacteristic;//外围设备写数据的特征
@property (nonatomic, strong) CBCharacteristic *  notifyCharacteristic; // 外围设备通知的特征

@end

@implementation BLECentralHelper

+ (BLECentralHelper *)sharedInstance
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init
{
    if ((self = [super init])) {
        self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        self.nDevices = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)scanForBluetooth
{
    [self.manager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
}

- (void)stopScanForBluetooth
{
    [self.manager stopScan];
}

- (void)connectToPeripheral:(CBPeripheral *)peripheral
{
    self.peripheral = peripheral;
    [self.manager connectPeripheral:peripheral options:nil];
}

- (void)writeData:(NSData *)data
{
    if (self.writeCharacteristic) {
        [self.peripheral writeValue:data
                  forCharacteristic:self.writeCharacteristic
                               type:CBCharacteristicWriteWithResponse];
    }
    
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"centralManagerDidUpdateState");
    
    if (central.state == CBCentralManagerStatePoweredOn) {
        self.bluetoothConnectStatus = YES;
        [self scanForBluetooth];
        
    }
    else {
        self.bluetoothConnectStatus = NO;
        self.peripheral = nil;
        self.nDevices = nil;
        if (self.devicesBlock) {
            self.devicesBlock(self.nDevices);
        }
        [self stopScanForBluetooth];
    }
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    NSLog(@"didDiscoverPeripheral %@", peripheral);
    BOOL isContained = NO;
    for (CBPeripheral *cbPeripheral in self.nDevices) {
        if ([cbPeripheral.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]) {
            isContained = YES;
            break;
        }
    }
    if (!isContained) {
        NSLog(@"add Devices");
        [self.nDevices addObject:peripheral];
    }
    if (self.devicesBlock) {
        self.devicesBlock(self.nDevices);
    }
}

- (void)centralManager:(CBCentralManager *)central
  didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Connected to peripheral %@", peripheral);
    self.bluetoothConnectStatus = YES;
    [self.manager stopScan];
    [self.peripheral setDelegate:self];
    [self.peripheral discoverServices:nil];
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)aPeripheral
didDiscoverServices:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering service: %@", [error localizedDescription]);
        return;
    }
    NSLog(@"service count : %lu", (unsigned long)aPeripheral.services.count);
    for (CBService *service in aPeripheral.services) {
        // Discovers the characteristics for a given service
            NSLog(@"Service found with UUID: %@", service.UUID);
            [self.peripheral discoverCharacteristics:nil
                                          forService:service];
    }
}

//扫描到Characteristics
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    if (error)
    {
        NSLog(@"error Discovered characteristics for %@ with error: %@", service.UUID, [error localizedDescription]);
        return;
    }
    
    for (CBCharacteristic *characteristic in service.characteristics)
    {
        NSLog(@"service:%@ 的 Characteristic: %@",service.UUID,characteristic.UUID);
        //读取Characteristic的值，读到数据会进入方法：-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
        [peripheral readValueForCharacteristic:characteristic];
        
        //搜索Characteristic的Descriptors，读到数据会进入方法：-(void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
        [peripheral discoverDescriptorsForCharacteristic:characteristic];
        
        // 获取只写的Characteristic
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:writeCharacteristicUUID]]) {
            self.writeCharacteristic = characteristic;
        }
        
        // 监听通知的Characteristic
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:notifyCharacteristicUUID]])
        {
            self.notifyCharacteristic = characteristic;
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}

//搜索到Characteristic的Descriptors
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    
    //打印出Characteristic和他的Descriptors
    NSLog(@"characteristic uuid:%@",characteristic.UUID);
    for (CBDescriptor *d in characteristic.descriptors) {
        NSLog(@"Descriptor uuid:%@",d.UUID);
    }
    
}

//获取的charateristic的值
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    //打印出characteristic的UUID和值
    //!注意，value的类型是NSData，具体开发时，会根据外设协议制定的方式去解析数据
    NSLog(@"characteristic uuid:%@  value:%@",characteristic.UUID, [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding]);
    if (self.notifyCharacteristic == characteristic) {
        if (self.msgBlock) {
            self.msgBlock(characteristic.value);
        }
    }
}

//获取到Descriptors的值
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error{
    //打印出DescriptorsUUID 和value
    //这个descriptor都是对于characteristic的描述，一般都是字符串，所以这里我们转换成字符串去解析
    NSLog(@"characteristic uuid:%@  value:%@",[NSString stringWithFormat:@"%@",descriptor.UUID],descriptor.value);
}

- (void)peripheral:(CBPeripheral *)peripheral
didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    NSLog(@"%@", characteristic.value);
}

@end
