//
//  TOBLEStackself.m
//  TheOne
//
//  Created by 王涛 on 2017/7/14.
//  Copyright © 2017年 tcl. All rights reserved.
//

#import "TOBLEStackProtocol.h"

@interface TOBLEStackProtocol()

/**
 * 当接收数据超出MTU时，需分包。此属性用于缓存分包数据，结构类型：{"特征值":data}
 */
@property (nonatomic, strong) NSMutableData  *recvData;  //存储分包数据

@property (nonatomic, assign) NSInteger  leftData;
@end

@implementation TOBLEStackProtocol


#pragma mark - Required Protocol Delegate
- (instancetype)unbuildingRecvData:(NSData *)data
{
    if ([self hasSubPackage]) {
        [_recvData appendData:data];
        
        _leftData -= data.length;

        if (_leftData == 0) {
            _data = [[_recvData subdataWithRange:NSMakeRange(kLength, _recvData.length - kLength)] copy];
        }
        return  self;
    }
    else if (data && data.length >= kLength) {
        
        [self copyFromData:data];
        
        if (![self isValid:data]) {
            return  nil;
        }
        
        if (_dataLength == data.length) {
            if (data.length > kLength) {
                _data = [data subdataWithRange:NSMakeRange(kLength, data.length - kLength)];
            }
            _leftData = 0;
            return self;
        }
        else {//分包处理
            _recvData = [NSMutableData data];
            [_recvData appendData:data];
            _leftData = _dataLength - data.length;
//            DDLogInfo(@"BLE Protocol handle sub package recv data[%@] left:%ld", _recvData, (long)_leftData);
            return self;
        }
        
    }

    return nil;
}

- (NSData *)buildSendData
{
    NSMutableData *data = [NSMutableData data];
    
    NSData *magicData = [NSData dataWithBytes:&_magic length:sizeof(_magic)];
    if (magicData) {
       [data appendData:magicData];
    }
    
    _dataLength = _data.length;
    UInt16 length = kLength;
    if (_data) {
       length = [_data length] + kLength;
       NSData *lenData = [NSData dataWithBytes:&length length:sizeof(length)];
       [data appendData:lenData];
    }else{
       NSData *lengthData = [NSData dataWithBytes:&length length:sizeof(UInt16)];
       [data appendData:lengthData];
    }

    [data appendBytes:&_packageType length:sizeof(_packageType)];
    
    [data appendBytes:&_headVersion length:sizeof(_headVersion)];
    
    [data appendBytes:&_moduleId length:sizeof(_moduleId)];
    
    [data appendBytes:&_eventId length:sizeof(_eventId)];
    
    [data appendData:_data];
    
    return data;
}



- (NSString *)protocolCommand
{
    return [NSString stringWithFormat:@"%02x+%02x", _moduleId, _eventId];
}


#pragma mark - Optional Protocol Delegate
- (BOOL)hasSubPackage
{
    return (_recvData && _recvData.length >= kLength);
}

- (BOOL)isAckPackage
{
    return ((_dataLength == kLength) && (_headVersion == 0x01));
}

- (BOOL)unbuildCompleted
{
    return ((_dataLength) && (_dataLength == (kLength + _data.length)));
}

#pragma mark - Private Method
- (void)copyFromData:(NSData *)data
{
    UInt8 buf[kLength] = {0};
    UInt8 *pbuf = buf;
    
    [data getBytes:buf length:kLength];

    memcpy(&_magic, pbuf, sizeof(_magic));
    pbuf += sizeof(_magic);
    
    memcpy(&_dataLength, pbuf, sizeof(_dataLength));
    pbuf += sizeof(_dataLength);
    
    memcpy(&_packageType, pbuf, sizeof(_packageType));
    pbuf += sizeof(_packageType);
    
    memcpy(&_headVersion, pbuf, sizeof(_headVersion));
    pbuf += sizeof(_headVersion);
    
    memcpy(&_moduleId, pbuf, sizeof(_moduleId));
    pbuf += sizeof(_moduleId);
    
    memcpy(&_eventId, pbuf, sizeof(_eventId));
    pbuf += sizeof(_eventId);
}

- (BOOL)isValid:(NSData *)data
{
    if (_magic != kMagic) {
        DDLogInfo(@"BLE protocol magic invalid");
        return NO;
    }

    if (_moduleId >= BANDProtocolModuleMax) {
        DDLogInfo(@"BLE protocol moduleId invalid");
        return NO;
    }
    
    if (_dataLength < kLength) {
        DDLogInfo(@"BLE protocol data length invalid");
        return NO;
    }
    
    if (_dataLength < data.length) {
        DDLogInfo(@"BLE protocol data length invalid");
        return NO;
    }
    
    return YES;
}

- (NSString *)macAdress
{
    NSString *mac1Str = [[self.data subdataWithRange:NSMakeRange(0, 1)] description];
    NSString *mac2Str = [[self.data subdataWithRange:NSMakeRange(1, 1)] description];
    NSString *mac3Str = [[self.data subdataWithRange:NSMakeRange(2, 1)] description];
    NSString *mac4Str = [[self.data subdataWithRange:NSMakeRange(3, 1)] description];
    NSString *mac5Str = [[self.data subdataWithRange:NSMakeRange(4, 1)] description];
    NSString *mac6Str = [[self.data subdataWithRange:NSMakeRange(5, 1)] description];
    NSString *macAddr = [NSString stringWithFormat:@"%@:%@:%@:%@:%@:%@",mac6Str,mac5Str,mac4Str,mac3Str,mac2Str,mac1Str];

    return macAddr;
}
@end
