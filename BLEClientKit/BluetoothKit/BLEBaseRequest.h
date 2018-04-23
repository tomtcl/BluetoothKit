//
//  BLEBaseRequest.h
//  TheOne
//
//  Created by 王涛 on 2017/6/12.
//  Copyright © 2017年 tcl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLEStackProtocol.h"
#import "BLECentralManager.h"
typedef void (^BleCallBack)(id result, NSError *error);

@interface BLEBaseRequest : NSObject

@property (nonatomic, copy) BleCallBack callBack;

/**
 * BLE协议，上层需实现协议方法。注意：此处为强引用，故外部调用切勿用强引用
 */
@property (nonatomic, strong, readonly) id<BLEStackProtocol> protocol;

/**
 请求指定服务特征值,当读写特征值相同时使用该接口

 @param service 服务
 @param characteristic 特征值
 @return class
 */
- (instancetype)initWithService:(NSString *)service characteristic:(NSString *)characteristic;


/**
 请求指定服务特征值,当读写特征值不同时使用该接口

 @param serviceDict 读写服务键值对 {写：读}
 @param characteristicDict 读写特征键值对{写：读}
 @return Class
 */
- (instancetype)initWithServiceDict:(NSDictionary *)serviceDict characteristicDict:(NSDictionary *)characteristicDict;

/**
 发起BLE数据请求，返回数据通过异步方式Block回调

 @param protocol BLE协议，需遵守协议规则
 */
- (void)startAsyncRequest:(id<BLEStackProtocol>)protocol;

- (void)startAsyncRequest:(id<BLEStackProtocol>)protocol withTimeout:(NSInteger)timeout;

- (void)startAsyncRequest:(id<BLEStackProtocol>)protocol withTimer:(BOOL)timer;

- (NSString *)identifier;


/**
 发送OTA包 不带BLEStackProtocol 协议

 @param data 数据包
 */
- (void)startSendOTAData:(NSData *)data;

@end

