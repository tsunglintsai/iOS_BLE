//
//  PGMessage.h
//  BLE
//
//  Created by Henry on 8/7/14.
//  Copyright (c) 2014 Pyrogusto Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PGMessage : NSObject
@property (nonatomic,strong) NSDate *time;
@property (nonatomic,strong) NSString *messageContent;
@end
