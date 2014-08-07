//
//  PGViewController.m
//  BLE
//
//  Created by Henry on 7/21/14.
//  Copyright (c) 2014 Pyrogusto Inc. All rights reserved.
//

#import "PGViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import <AudioToolbox/AudioToolbox.h>

//static NSString* const identifier = @"CE415BDB-AD52-DFED-4B79-C87EE20FFD61"; // iphone ~ TI fob
//static NSString* const identifier = @"6A8F6CDB-873B-BB2C-37AC-DA31868E4EF8"; // iphone ~ TI sensor tag

//static NSString* const identifier = @"8DB4A492-6C51-527A-0C01-75A0FE1F65FE"; // iPad ~ TI fob

//static NSString* const identifier = @"F17387A8-1E33-ED78-8451-95B8DDC4DCD3"; // iPhone 5c virtual Peripheral

//static NSString* const identifier = @"4F096348-282F-2FB4-F0AF-63062229C6B0"; // iphone ~ estimote light blue


static NSString* const identifier = @"054A5AC8-FA93-9D3F-2A13-FB0B7CF1C2AC"; // iphone ~ iPad as peripheral

#define connectRatherThanDiscover YES

//054A5AC8-FA93-9D3F-2A13-FB0B7CF1C2AC

@interface PGViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate>
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) NSMutableArray *bleDevicesFound;
@property (nonatomic, strong) NSMutableArray *knownPeripherals;
@property (nonatomic, strong) CBPeripheral *connectedPeripheral;
@property (nonatomic, strong) CBCharacteristic *battertCharacteristic;
@property (nonatomic) SystemSoundID pewPewSound;

@end

@implementation PGViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.centralManager.delegate = self;
}

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
    NSLog(@"---------didConnectPeripheral");
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
    NSLog(@"***********************************************************************************************didDisconnectPeripheral");
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
    [self playSound];    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [peripheral readValueForCharacteristic:characteristic];
    });
}

- (void)playSound{
    NSString *soundPath=[[NSBundle mainBundle] pathForResource:@"pew-pew-lei" ofType:@"caf"];
    SystemSoundID sound;
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:soundPath],&sound);
    AudioServicesPlaySystemSound(sound);
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSLog(@"=============================didUpdateNotificationStateForCharacteristic");
//    UInt8 batteryLevel = ((UInt8*)characteristic.value.bytes)[0];
    NSLog(@"[%@] the value:%@",characteristic.UUID,[characteristic.value description]);
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSLog(@"didWriteValueForCharacteristic:%@",[error description]);
}

@end
