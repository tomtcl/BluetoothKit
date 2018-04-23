//
//  BLERequstQueue.h
//  TheOne
//
//  Created by 王涛 on 2017/7/5.
//  Copyright © 2017年 tcl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLEBaseRequest.h"

@interface BLERequstQueue : NSObject

+ (instancetype)shareInstance;

+ (void)deinit;

/**
 * 当前队列中成员个数
 */
- (NSInteger)requestQueueCount;

/**
 * 请求对象实例加入队列中
 *
 * @param request 请求实例
 */
- (void)pushQueue:(BLEBaseRequest *)request;


/**
 * 从请求队列中查找对应的请求实例, 请求实例出队列
 *
 @param identifier 请求标识符
 @return 请求对象实例
 */
- (BLEBaseRequest *)popQueue:(NSString *)identifier;


/**
 从请求队列中查找对应的请求实例, 请求实例仍在队列中
 
 @param identifier 请求标识符
 @return 请求对象实例
 */
- (BLEBaseRequest *)queueWithTag:(NSString *)identifier;

/**
 * 从请求队列中查找分包接收数据的请求实例，注意：该API只适用于当前队列只可能存
 * 一个分包接收的Request 
 @param UUIDString 特征值
 @return 请求对象实例
 */
- (BLEBaseRequest *)queueSubpackWithTag:(NSString *)UUIDString;
@end
