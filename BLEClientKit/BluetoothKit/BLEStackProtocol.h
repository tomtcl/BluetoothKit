//
//  BLEStackProtocol.h
//  TheOne
//
//  Created by 王涛 on 2017/7/21.
//  Copyright © 2017年 tcl. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 BLE协议栈错误码

 - BLEProtocolErrorNone: 无错误
 - BLEProtocolErrorNoReady: BLE未准备好
 - BLEProtocolErrorCharacteristic: 特征值错误
 - BLEProtocolErrorData: 数据错误不能发送
 - BLEProtocolErrorTimeout: BLE通信超时
 - BLEProtocolErrorSend: 数据发送失败(无应答ack)
 */
typedef NS_ENUM(NSInteger, BLEProtocolError)
{
    BLEProtocolErrorNone            = 0,
    BLEProtocolErrorNoReady         = -1,
    BLEProtocolErrorCharacteristic  = -2,
    BLEProtocolErrorData            = -3,
    BLEProtocolErrorTimeout         = -4,
    BLEProtocolErrorSend            = -5,
};

@protocol BLEStackProtocol <NSObject>

@required
- (instancetype)unbuildingRecvData:(NSData *)data;

/**
 二进制转换
 
 @return 生成Data数据
 */
- (NSData *)buildSendData;

/**
 获取协议命令号，用于唯一表示Request
 
 @return 命令号
 */
- (NSString *)protocolCommand;

@optional

/**
 判断该协议信息中是否有分包未处理完的数据
 
 @return YES or NO
 */
- (BOOL)hasSubPackage;

/**
 检查解释包是否完成，因为存在需要分包的情况
 
 @return YES or NO
 */
- (BOOL)unbuildCompleted;

/**
 判断是否为ACK包，目前所有请求都有ACK包

 @return YES or NO
 */
- (BOOL)isAckPackage;

@end
