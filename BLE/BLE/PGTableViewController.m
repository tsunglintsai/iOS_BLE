//
//  PGTableViewController.m
//  BLE
//
//  Created by Henry on 8/7/14.
//  Copyright (c) 2014 Pyrogusto Inc. All rights reserved.
//

#import "PGTableViewController.h"
#import "PGMessage.h"
#import <CoreBluetooth/CoreBluetooth.h>

static NSString* const identifier = @"054A5AC8-FA93-9D3F-2A13-FB0B7CF1C2AC"; // iphone ~ iPad as peripheral
#define connectRatherThanDiscover YES

@interface PGTableViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate>
@property (nonatomic,strong) NSMutableArray *messageList;
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) NSMutableArray *bleDevicesFound;
@property (nonatomic, strong) NSMutableArray *knownPeripherals;
@property (nonatomic, strong) CBPeripheral *connectedPeripheral;
@property (nonatomic, strong) CBCharacteristic *battertCharacteristic;
@end

@implementation PGTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.messageList = [[NSMutableArray alloc] init];
    self.centralManager.delegate = self;


    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.messageList count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"identifier" forIndexPath:indexPath];
    PGMessage *message = [self.messageList objectAtIndex:indexPath.row];

    cell.textLabel.text = [message.time description];
    cell.detailTextLabel.text = message.messageContent;
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/



- (CBCentralManager*) centralManager{
    if(!_centralManager){
        _centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:nil options:nil];
        //_centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:nil options:@{CBCentralManagerOptionRestoreIdentifierKey: @"MyBLECentral"}];
        
    }
    return _centralManager;
}


#pragma mark central manager delegate methods

/*
 - (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)state{
 NSLog(@"==========================centralManager:willRestoreState:%@",[state description]);
 NSArray *peripherals = state[CBCentralManagerRestoredStatePeripheralsKey];
 
 for(CBPeripheral *peripheral in peripherals){
 if ( [peripheral.identifier isEqual:[[NSUUID alloc]initWithUUIDString:identifier]]){
 [self.bleDevicesFound addObject:peripheral];
 peripheral.delegate = self;
 }
 }
 
 }
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    NSLog(@"centralManagerDidUpdateState:%@",central);
    if([central state] != CBCentralManagerStatePoweredOn){
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"No Bluetooth" message:@"Your Bluetooth services are not on. " delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
    } else {
        if(connectRatherThanDiscover){
            [self connectDevice];
        }else{
            [[self centralManager] scanForPeripheralsWithServices:nil options:nil];
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    NSLog(@"Found a BLE Device : %@ ", peripheral);
    
    if( [peripheral.identifier isEqual:[[NSUUID alloc]initWithUUIDString:identifier]] ){
        NSLog(@"***************connecting to TI sendor tag");
        /*
         iOS 6.0 bug workaround : connect to device before displaying UUID !
         The reason for this is that the CFUUID .UUID property of CBPeripheral
         here is null the first time an unkown (never connected before in any app)
         peripheral is connected. So therefore we connect to all peripherals we find.
         */
        if (![self bleDevicesFound]) [self setBleDevicesFound:[[NSMutableArray alloc] init]];
        [[self bleDevicesFound] addObject:peripheral];
        peripheral.delegate = self;
        [[self centralManager] connectPeripheral:peripheral options:@{CBConnectPeripheralOptionNotifyOnConnectionKey : @YES ,CBConnectPeripheralOptionNotifyOnDisconnectionKey :@YES}];
    }
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.fireDate = [[NSDate date] dateByAddingTimeInterval:5];
    notification.alertBody = [NSString stringWithFormat:@"BLE connected:%@",[NSDate date]];
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    
    self.connectedPeripheral = peripheral;
    [self.connectedPeripheral setDelegate:self];
    //[self.connectedPeripheral discoverServices:nil];
    [self.connectedPeripheral discoverServices:@[[CBUUID UUIDWithString:@"0x180F"]]]; // battery
    //[self.connectedPeripheral discoverServices:@[[CBUUID UUIDWithString:@"0x1804"]]]; // Tx Power
    //[self.connectedPeripheral discoverServices:@[[CBUUID UUIDWithString:@"0x1803"]]]; // link lost
    //[self.connectedPeripheral discoverServices:@[[CBUUID UUIDWithString:@"0x1802"]]]; // Immediate Alert
    //[self.connectedPeripheral discoverServices:@[[CBUUID UUIDWithString:@"0x180A"]]]; // Device Info
    //[self.connectedPeripheral discoverServices:@[[CBUUID UUIDWithString:@"0xFFA0"]]]; // Accelerometer
    //[self.connectedPeripheral discoverServices:@[[CBUUID UUIDWithString:@"0xFFE0"]]]; // key press
    //[self.connectedPeripheral discoverServices:@[[CBUUID UUIDWithString:@"BD0F6577-4A38-4D71-AF1B-4E8F57708080"]]]; // virtual
    
    
    
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{

    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.fireDate = [[NSDate date] dateByAddingTimeInterval:5];
    notification.alertBody = [NSString stringWithFormat:@"BLE disconnected:%@",[NSDate date]];
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    
    [self connectDevice];
}

- (void) connectDevice{
    
    self.knownPeripherals = [[self.centralManager retrievePeripheralsWithIdentifiers:@[[[NSUUID alloc]initWithUUIDString:identifier]]] mutableCopy];
    NSLog(@"%@",self.knownPeripherals);
    if( [self.knownPeripherals count] > 0 ){
        [[self centralManager] connectPeripheral:[self.knownPeripherals lastObject] options:@{
                                                                                              CBConnectPeripheralOptionNotifyOnConnectionKey : @YES ,
                                                                                              CBConnectPeripheralOptionNotifyOnDisconnectionKey : @YES,
                                                                                              CBConnectPeripheralOptionNotifyOnNotificationKey : @YES}];
    }else{
        [[self centralManager] scanForPeripheralsWithServices:nil options:nil];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    NSLog(@"========================didDiscoverServices%@",error);
    for (CBService *service in peripheral.services) {
        NSLog(@"Discovered service %@", service);
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    for (CBCharacteristic *characteristic in service.characteristics) {
        NSLog(@"Discovered characteristic %@", characteristic);
        self.battertCharacteristic = characteristic;
        
        
        
        // read value from BLE device
        [peripheral readValueForCharacteristic:characteristic];
        
        // setup observer of BLE device
        //[peripheral setNotifyValue:YES forCharacteristic:characteristic];
        
        // write value to BLE device
        /*
         NSLog(@"write data to device");
         unsigned char mydata = 1;
         NSData *dataToWrite = [NSMutableData dataWithBytes:&mydata length:sizeof(mydata)];
         [peripheral writeValue:dataToWrite forCharacteristic:characteristic
         type:CBCharacteristicWriteWithoutResponse];
         */
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSLog(@"======================didUpdateValueForCharacteristic");
    NSLog(@"[%@] the value:%@ :%@",characteristic.UUID,[characteristic.value description], [error description]);
    
    PGMessage *message = [[PGMessage alloc]init];
    message.time = [NSDate date];
    message.messageContent = [NSString stringWithFormat:@"[%@] the value:%@",characteristic.UUID,[characteristic.value description]];
    [self.messageList insertObject:message atIndex:0];
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [peripheral readValueForCharacteristic:characteristic];
    });
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSLog(@"=============================didUpdateNotificationStateForCharacteristic");
    //UInt8 batteryLevel = ((UInt8*)characteristic.value.bytes)[0];
    NSLog(@"[%@] the value:%@",characteristic.UUID,[characteristic.value description]);

}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSLog(@"didWriteValueForCharacteristic:%@",[error description]);
}
@end
