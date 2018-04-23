//
//  TOBLENotify.m
//  TheOne
//
//  Created by 王涛 on 2017/8/2.
//  Copyright © 2017年 tcl. All rights reserved.
//

#import "TOBLENotify.h"
#import "BLECentralManager.h"
#import "TOBLEStackProtocol.h"


@interface TOBLENotify()

/**
 用于缓存分包协议数据,结构{"特征值":"protocol"}
 */
@property (nonatomic, strong) NSMutableDictionary *protocolDict;

@end

@implementation TOBLENotify

+ (instancetype)shareInstance
{
    static TOBLENotify *instance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}

- (id)init
{
    if (self = [super init]) {

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(BLECenteralDidUpdateValue:) name:BLECentralCharacteristicDidUpdateValue object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:BLECentralCharacteristicDidUpdateValue object:nil];
}

#pragma mark - BLE Centeral Notifcation
- (void)BLECenteralDidUpdateValue:(NSNotification *)notification
{
    CBCharacteristic *characteristic = (CBCharacteristic *)notification.object;

    if (characteristic.value) {
        
    }
}
@end
