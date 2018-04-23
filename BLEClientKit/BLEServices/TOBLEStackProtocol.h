//
//  TOBLEStackProtocol.h
//  TheOne
//
//  Created by 王涛 on 2017/7/14.
//  Copyright © 2017年 tcl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLEStackProtocol.h"

#define kMagic          0xABBA
#define kLength         8

/*
 * MB12 BLE 通讯协议数据结构
 * | MagicNum | DataLength | PackageType | HeadVer | ModuleID | EventID |  Data  |
 *    2 Bytes    2 Bytes        1 Byte      1 Byte    1 Byte     1 Byte   0 ~ 120
 *
 */
@interface TOBLEStackProtocol : NSObject<BLEStackProtocol>

@property (nonatomic, assign) UInt16 magic;

@property (nonatomic, assign) UInt16 dataLength;

@property (nonatomic, assign) UInt8  packageType;

@property (nonatomic, assign) UInt8  headVersion;

@property (nonatomic, assign) UInt8  moduleId;

@property (nonatomic, assign) UInt8  eventId;

@property (nonatomic, strong) NSData *data;

- (NSString *)macAdress;
@end
