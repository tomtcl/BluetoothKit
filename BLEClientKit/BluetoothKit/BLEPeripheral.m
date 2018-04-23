//
//  BLEPeripheral.m
//  TheOne
//
//  Created by 王涛 on 2017/6/13.
//  Copyright © 2017年 tcl. All rights reserved.
//

#import "BLEPeripheral.h"

@interface BLEPeripheral()

/**
 * 订阅外设服务和特征字典，结构：{"serviceUUID":@["charUUID", "charUUID"]}
 */
@property (nonatomic, strong) NSDictionary *serviceCharacterDict;

/**
 * 特征服务是否启用通知配置，结构：{"serviceUUID+charUUID"：@(YES/NO)}
 */
@property (nonatomic, strong) NSDictionary *characterNotifyDict;

/**
 * 已订阅的特征实例，结构:{"serviceUUID+charUUID":"CBCharacteristic"}
 */
@property (nonatomic, strong) NSDictionary *characterisiticDict;



@end

@implementation BLEPeripheral

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral
{
    self = [super init];
    if (self) {
        _cbPeripheral = peripheral;
    }
    return self;
}

- (void)addService:(NSString *)serviceUUID characteristic:(NSString *)charactUUID
{
    if (![self isValidUUID:serviceUUID] || ![self isValidUUID:charactUUID]) {
        return;
    }
    
    NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc] initWithDictionary:_serviceCharacterDict];
    CBUUID *sUUID = [CBUUID UUIDWithString:serviceUUID];
    CBUUID *cUUID = [CBUUID UUIDWithString:charactUUID];
    if (!sUUID || !cUUID) {
        return;
    }
    
    NSArray *array = [mutableDict objectForKey:sUUID.UUIDString];
    if (!array) {
        [mutableDict setObject:@[cUUID.UUIDString] forKey:sUUID.UUIDString];
    }
    else
    {
        NSMutableArray *characters = [NSMutableArray arrayWithArray:array];

        if ([characters indexOfObject:cUUID.UUIDString] == NSNotFound) {
            [characters addObject:cUUID.UUIDString];
        }
        
        [mutableDict setObject:characters forKey:sUUID.UUIDString];
    }
    
    _serviceCharacterDict = [mutableDict copy];
#if 0 //deprecated
    mutableDict = [[NSMutableDictionary alloc] initWithDictionary:_characterNotifyDict];
    NSString *key = [NSString stringWithFormat:@"%@+%@", sUUID.UUIDString, cUUID.UUIDString];
    [mutableDict setObject:@(notify) forKey:key];
    
    _characterNotifyDict = [mutableDict copy];
#endif
}

- (void)registerForService:(CBService *)service characteristic:(CBCharacteristic *)characteristic
{
    NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc] initWithDictionary:_characterisiticDict];
    CBUUID *sUUID = [CBUUID UUIDWithString:service.UUID.UUIDString];
    CBUUID *cUUID = [CBUUID UUIDWithString:characteristic.UUID.UUIDString];
    
    NSString *key = [NSString stringWithFormat:@"%@+%@", sUUID.UUIDString, cUUID.UUIDString];
    [mutableDict setObject:characteristic forKey:key];
    
    _characterisiticDict = [mutableDict copy];
}

- (NSArray *)services
{
    return [_serviceCharacterDict allKeys];
}

- (NSArray *)characteristicForService:(NSString *)uuidString
{
    if (uuidString) {
        return [_serviceCharacterDict objectForKey:uuidString];
    }
    return nil;
}

+ (NSString *)generateIdentifierWithService:(NSString *)serviceUUID characteristic:(NSString *)charactUUID
{
    return [NSString stringWithFormat:@"%@+%@", serviceUUID, charactUUID];
}

- (BOOL)isNotifyForService:(CBService *)service characteristic:(CBCharacteristic *)characteristic
{
    NSString *identifier = [BLEPeripheral generateIdentifierWithService:service.UUID.UUIDString characteristic:characteristic.UUID.UUIDString];
    
    return [[_characterNotifyDict objectForKey:identifier] boolValue];
}

- (void)writeValue:(NSData *)data forIdentifier:(NSString *)identifier
{
    if (data && identifier) {
        CBCharacteristic *characteristic = [_characterisiticDict objectForKey:identifier];
        if (characteristic) {
            
            if ((characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) == CBCharacteristicPropertyWriteWithoutResponse) {
                [_cbPeripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
            }
            else if ((characteristic.properties & CBCharacteristicPropertyWrite) == CBCharacteristicPropertyWrite){
                [_cbPeripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
            }
        }
    }
}

- (void)writeDataWithResponseValue:(NSData *)data forIdentifier:(NSString *)identifier
{
    if (data && identifier) {
        CBCharacteristic *characteristic = [_characterisiticDict objectForKey:identifier];
        if (characteristic) {

            [_cbPeripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
        }
    }
}


- (void)readValueForIndetifier:(NSString *)indetifier
{
    if (indetifier) {
        CBCharacteristic *characteristic = [_characterisiticDict objectForKey:indetifier];
        if (characteristic) {
            [_cbPeripheral readValueForCharacteristic:characteristic];
        }
    }
}

- (BOOL)isValidUUID:(NSString *)uuidString
{
    if (!uuidString || !uuidString.length) {
        return NO;
    }
    
    NSArray *array = [uuidString componentsSeparatedByString:@"-"];
    if (array.count == 1) {
        return ([array[0] length] == 4);
    }
    
    if (array.count == 5) {
        NSArray *tmp = @[@(8), @(4), @(4), @(4), @(12)];
        for (int i = 0; i < array.count; i++) {
            NSString *string = [array objectAtIndex:i];
            if ([string isKindOfClass:[NSString class]]) {
                if (string.length != [tmp[i] integerValue]) {
                    return NO;
                }
            }
            else
            {
                return NO;
            }
        }
    }
    
    return YES;
}
@end
