//
//  ViewController.m
//  BLEPeripheral
//
//  Created by Henry Tsai on 7/31/14.
//  Copyright (c) 2014 Pandora. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

#define characteristicId @"DDCA9B49-A6F5-462F-A89A-C2144083CA7F"
#define serviceId @"BD0F6577-4A38-4D71-AF1B-4E8F57708080"
#define keepBroadCasting YES


@interface ViewController () <CBPeripheralManagerDelegate>
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) CBMutableService *service;
@property (nonatomic, strong) CBMutableCharacteristic *characteristic;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:nil];

}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    NSLog(@"peripheralManagerDidUpdateState: %d", (int)peripheral.state);
    
    if (CBPeripheralManagerStatePoweredOn == peripheral.state) {
        
        self.characteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:characteristicId] properties:CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable];
        
        self.service = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:serviceId] primary:YES];
        self.service.characteristics = @[self.characteristic];
        
        [self.peripheralManager addService:self.service];
        [self broadCastMessage];
    } else {
        [peripheral stopAdvertising];
        [peripheral removeAllServices];
    }
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    NSLog(@"peripheralManagerDidStartAdvertising: %@", error);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
    NSLog(@"peripheralManagerDidAddService: %@ %@", service, error);
    
    [peripheral startAdvertising:@{
                                   CBAdvertisementDataLocalNameKey: @"hello2"
                                   }];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request{
    NSLog(@"=======================didReceiveReadRequest");
    unsigned char mydata = 1;
    NSData *dataToWrite = [NSMutableData dataWithBytes:&mydata length:sizeof(mydata)];
    
    self.characteristic.value = dataToWrite;
    request.value = [self.characteristic.value
                     subdataWithRange:NSMakeRange(request.offset,
                                                  self.characteristic.value.length - request.offset)];
    [self.peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
}

- (void) broadCastMessage{
    NSLog(@"broadCastMessage");
    unsigned char mydata = 1;
    NSData *dataToWrite = [NSMutableData dataWithBytes:&mydata length:sizeof(mydata)];
    [self.peripheralManager updateValue:dataToWrite forCharacteristic:self.characteristic onSubscribedCentrals:nil];
    if(keepBroadCasting){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self broadCastMessage];
        });
    }
}


@end
