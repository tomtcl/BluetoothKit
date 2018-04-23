//
//  BleCentralManager.h
//  TheOne
//
//  Created by 王涛 on 2017/6/8.
//  Copyright © 2017年 tcl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BLEPeripheral.h"

/**
 * @enum BLECentralState
 *
 * @discussion BLE 中心设备管理器状态机
 * @constant BLECentralStateInvalid: 无效状态，蓝牙未开启 or 蓝牙不可用
 * @constant BLECentralStateIdle: 空闲状态，没有开始工作 or 工作中断
 * @constant BLECentralStateScaning: 正在扫描周边设备状态
 * @constant BLECentralStateUnDiscovered: 未发现周边状态，超时或者其他原因
 * @constant BLECentralStateDiscovered: 已发现周边状态
 * @constant BLECentralStateConnecting: 正在连接外设状态
 * @constant BLECentralStateUnConnected: 未连接成功，连接失败状态
 * @constant BLECentralStateConnected: 连接成功状态，注意：此状态表示外设已经连接且有可用服务
 * @constant BLECentralStateRuning: BLE中心设备正常工作状态，表示可以进行蓝牙数据通信
 */
typedef NS_ENUM(NSInteger, BLECentralState)
{
    BLECentralStateInvalid,
    BLECentralStateIdle,
    BLECentralStateScaning,
    BLECenteralStateUnDiscovered,
    BLECentralStateDiscovered,
    BLECentralStateConnecting,
    BLECentralStateUnConnected,
    BLECentralStateConnected,
    BLECentralStateRuning,
};


/**
 * BLE Centeral 状态变化采用通知的方式上报给业务层，考虑存在多个业务模块监听BLE状态，
 * 所以使用通知作为交互模式。
 */
extern NSString *const  BLECentralStateDidChangedNotification;
extern NSString *const  BLECentralUpdatePeripheralList;
/**
 * Characteristic 值发生变化，如果监听该特征则会收到特征值变化通知
 */
extern NSString *const  BLECentralCharacteristicDidUpdateValue;
extern NSString *const  BLECentralCharacteristicDidWriteValue;
@protocol BLECentralDelegate <NSObject>

@optional

/**
 接收处理主动请求的数据

 @param characteristic 特征
 @param error 错误码
 @return YES:是主动请求数据 NO:非主动请求数据
 */
- (BOOL)BLECentralDidReceiveDataForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error;

@end

@interface BLECentralManager : NSObject

@property (nonatomic, weak) id<BLECentralDelegate> delegate;

@property (nonatomic, strong, readonly) NSMutableArray *peripherals;
@property (nonatomic, strong, readonly) BLEPeripheral *pb;

+ (instancetype)shareManager;


/**
 * BleCentralManager 状态机的状态
 */
- (BLECentralState)state;


/**
 * 开始扫描周边外围设备,直到调用stopScan
 */
- (void)startScan;


/**
 * 开始扫描周边外围设备
 *
 * @param timeout 扫描超时时间
 */
- (void)startScanWithTimeout:(NSInteger)timeout;


/**
 * 停止扫描
 */
- (void)stopScan;


/**
 * 开始连接外设
 *
 * @param bracelet 外围设备属性
 */
- (void)connect:(BLEPeripheral *)bracelet;

/**
 * 订阅外设服务，注：未订阅的服务不提供读写操作
 *
 * @param serviceUUID Serice UUID
 * @param charactUUID Characteristic UUID
 */
- (void)subscribeService:(NSString *)serviceUUID characteristic:(NSString *)charactUUID;
/**
 *  断开蓝牙连接
 */
- (void)disConnect;


/**
 重连蓝牙设备

 @param uuidStr 重连的UUID
 */
- (void)retrieveKnownPeripherals:(NSString *)uuidStr macstr:(NSString *)macstr;

@end
