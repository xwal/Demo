//
//  DiscoverPeripheralTableViewController.m
//  BluetoothDemo
//
//  Created by Chaosky on 16/3/13.
//  Copyright © 2016年 1000phone. All rights reserved.
//

#import "DiscoverPeripheralTableViewController.h"
#import "BLECentralHelper.h"

@interface DiscoverPeripheralTableViewController ()

@property (nonatomic, weak) NSArray * peripheralArray;

@end

@implementation DiscoverPeripheralTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.clearsSelectionOnViewWillAppear = NO;
    __weak typeof(self) weakSelf = self;
    [BLECentralHelper sharedInstance].devicesBlock = ^(NSArray * devices) {
        weakSelf.peripheralArray = devices;
        [weakSelf.tableView reloadData];
    };
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[BLECentralHelper sharedInstance] scanForBluetooth];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[BLECentralHelper sharedInstance] stopScanForBluetooth];
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
    CBPeripheral * peripheral = self.peripheralArray[indexPath.row];
    cell.textLabel.text = peripheral.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu 服务", peripheral.services.count];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CBPeripheral * peripheral = self.peripheralArray[indexPath.row];
    [[BLECentralHelper sharedInstance] connectToPeripheral:peripheral];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController * destinationVC = segue.destinationViewController;
    CBPeripheral * peripheral = self.peripheralArray[self.tableView.indexPathForSelectedRow.row];
    destinationVC.title = peripheral.name;
}

@end
