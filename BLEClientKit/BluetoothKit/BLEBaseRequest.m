//
//  BLEBaseRequest.m
//  TheOne
//
//  Created by 王涛 on 2017/6/12.
//  Copyright © 2017年 tcl. All rights reserved.
//

#import "BLEBaseRequest.h"
#import "BLECentralManager.h"
#import "BLERequstQueue.h"
#import "TOBLEStackProtocol.h"

#define kBLEMTU                     20
#define kBLEComTimeout              30          //BLE数据通信最大超时时间
#define kRetryMax                   3           //BLE数据重传最大次数
#define kRetryDefalutInterval       2           //BLE数据重发默认间隔时间

@interface BLEBaseRequest()<BLECentralDelegate>
{
    NSDictionary    *_serviceUUIDDict;          //读写特征值{"写特征值":"读特征值"}
    NSDictionary    *_characteristicUUIDDict;   //读写特征值{"写特征值":"读特征值"}
    NSString        *_protocolCMD;              //协议命令号
    NSInteger       _timeout;                   //协议数据发送超时
    BOOL            _isTimerOpen;               //是否打开重发定时器
    NSInteger       _retriedTimes;              //已重传次数
}
@property (nonatomic, strong) BLECentralManager *centralManager;

/**
 * 消息发送队列
 */
@property (nonatomic, strong) dispatch_queue_t bleDispatch;

/**
 * BLE协议，上层需实现协议方法。注意：此处为强引用，故外部调用切勿用强引用
 */
@property (nonatomic, strong) id<BLEStackProtocol> protocol;

@property (nonatomic, strong) NSTimer *timer;
@end

@implementation BLEBaseRequest

#pragma mark - Life Cycle
- (instancetype)init
{
    if (self = [super init]) {
        _serviceUUIDDict = @{@"BFCCE9A0-E479-11E3-AC10-0800200C9A66":@"BFCCE9A0-E479-11E3-AC10-0800200C9A66"};
        _characteristicUUIDDict = @{@"BFCCE9A1-E479-11E3-AC10-0800200C9A66":@"BFCCE9A2-E479-11E3-AC10-0800200C9A66"};
        _bleDispatch = dispatch_queue_create("com.jrd.bleLBridge", DISPATCH_QUEUE_SERIAL);
        _timeout = kBLEComTimeout;
    }
    return self;
}

/**
 请求指定服务特征值,当读写特征值相同时使用该接口
 
 @param service 服务
 @param characteristic 特征值
 @return class
 */
- (instancetype)initWithService:(NSString *)service characteristic:(NSString *)characteristic
{
    self = [super init];
    if (self) {
        _serviceUUIDDict = @{service:service};
        _characteristicUUIDDict = @{characteristic:characteristic};
        _bleDispatch = dispatch_queue_create("com.jrd.bleLBridge", DISPATCH_QUEUE_SERIAL);
        _timeout = kBLEComTimeout;
    }
    return self;
}

/**
 请求指定服务特征值,当读写特征值不同时使用该接口
 
 @param serviceDict 读写服务键值对 {写：读}
 @param characteristicDict 读写特征键值对{写：读}
 @return Class
 */
- (instancetype)initWithServiceDict:(NSDictionary *)serviceDict characteristicDict:(NSDictionary *)characteristicDict
{
    if (self = [super init]) {
        _serviceUUIDDict = serviceDict;
        _characteristicUUIDDict = characteristicDict;
        _bleDispatch = dispatch_queue_create("com.jrd.bleLBridge", DISPATCH_QUEUE_SERIAL);
        _timeout = kBLEComTimeout;
    }
    return self;
}

- (void)dealloc
{
//    NSLog(@"%@ has delloc", [self class]);
}

#pragma mark - Public Method
/**
 发起BLE数据请求，返回数据通过异步方式Block回调
 
 @param protocol BLE协议，需遵守协议规则
 */
- (void)startAsyncRequest:(id<BLEStackProtocol>)protocol
{
    //防止同时访问
    @synchronized(self){

        if ([[BLECentralManager shareManager] state] != BLECentralStateRuning) {
            NSLog(@"BleCentral not readly.  BLE state:%ld", (long)[[BLECentralManager shareManager] state]);
            if (_callBack) {
                NSError *error = [[NSError alloc] initWithDomain:@"" code:BLEProtocolErrorNoReady userInfo:nil];
                _callBack(nil, error);
            }
            return;
        }

        _protocol = protocol;
        NSData *data = nil;
        if ([_protocol respondsToSelector:@selector(buildSendData)]) {
            data = [_protocol buildSendData];
        }

        if (!data) {
            NSLog(@"BleCentral write data is nil");
            if (_callBack) {
                NSError *error = [[NSError alloc] initWithDomain:@"" code:BLEProtocolErrorData userInfo:nil];
                _callBack(nil, error);
            }
            return;
        }
        NSLog(@"buildSenddata=%@",data);

        if ([_protocol respondsToSelector:@selector(protocolCommand)]) {
            _protocolCMD = [_protocol protocolCommand];
        }

        NSString *serviceWriteUUID = [_serviceUUIDDict.allKeys firstObject];
        NSString *characteristicWriteUUID = [_characteristicUUIDDict.allKeys firstObject];
        if (serviceWriteUUID && characteristicWriteUUID) {

            NSString *identifier = [BLEPeripheral generateIdentifierWithService:serviceWriteUUID characteristic:characteristicWriteUUID];

            if (_isTimerOpen) {
                [self timerEnable:@{identifier:data}];
            }
            [self timeoutEnable];

            [self writeData:data forIdentifier:identifier];

        }
        else
        {
            NSLog(@"BleCentral Characteristic is not init");
            if (_callBack) {
                NSError *error = [[NSError alloc] initWithDomain:@"" code:BLEProtocolErrorCharacteristic userInfo:nil];
                _callBack(nil, error);
            }
            return;
        }
    }
}


/**
 OTA

 @param data 发送包
 @param responseType 是否有回掉
 */
- (void)startSendOTAData:(NSData *)data
{
    NSString *serviceWriteUUID = [_serviceUUIDDict.allKeys firstObject];
    NSString *characteristicWriteUUID = [_characteristicUUIDDict.allKeys firstObject];
    if (serviceWriteUUID && characteristicWriteUUID) {

        NSString *identifier = [BLEPeripheral generateIdentifierWithService:serviceWriteUUID characteristic:characteristicWriteUUID];

        if (_isTimerOpen) {
            [self timerEnable:@{identifier:data}];
        }
        [self timeoutEnable];

        [self writeData:data forIdentifier:identifier];

    }
    else
    {
        NSLog(@"BleCentral Characteristic is not init");
        if (_callBack) {
            NSError *error = [[NSError alloc] initWithDomain:@"" code:BLEProtocolErrorCharacteristic userInfo:nil];
            _callBack(nil, error);
        }
        return;
    }
}


- (void)startAsyncRequest:(id<BLEStackProtocol>)protocol withTimeout:(NSInteger)timeout
{
    _timeout = timeout;
    [self startAsyncRequest:protocol];
}

- (void)startAsyncRequest:(id<BLEStackProtocol>)protocol withTimer:(BOOL)timer
{
    _isTimerOpen = timer;
    [self startAsyncRequest:protocol];
}


#pragma mark - Private Method
- (void)timeoutEnable
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSelector:@selector(timeoutTask) withObject:nil afterDelay:_timeout];
    });
}

- (void)timeoutDisable
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeoutTask) object:nil];
    });
}
- (void)timeoutTask
{
    [[BLERequstQueue shareInstance] popQueue:[self identifier]];
    _protocol = nil;
    
    if (_callBack) {
        NSError *error = [[NSError alloc] initWithDomain:@"" code:BLEProtocolErrorTimeout userInfo:nil];
        _callBack(nil, error);
    }
}

- (void)timerEnable:(id)userInfo
{
    if (_timer && [_timer isValid]) {
        [_timer invalidate];
        _timer = nil;
    }
    
    _retriedTimes = 0;
    dispatch_async(dispatch_get_main_queue(), ^{
        _timer = [NSTimer scheduledTimerWithTimeInterval:kRetryDefalutInterval target:self selector:@selector(timerTask:) userInfo:userInfo repeats:YES];
    });
}

- (void)timerDisable
{
    if (_timer && [_timer isValid]) {
        [_timer invalidate];
        _timer = nil;
    }
}

- (void)timerTask:(NSTimer *)timer
{
    if (_retriedTimes >= kRetryMax) {
        [self timerDisable];
        [self timeoutDisable];
        
        [[BLERequstQueue shareInstance] popQueue:[self identifier]];
        _protocol = nil;
        
        if (_callBack) {
            NSError *error = [[NSError alloc] initWithDomain:@"" code:BLEProtocolErrorSend userInfo:nil];
            _callBack(nil, error);
        }

        return;
    }
    [_timer setFireDate:[[NSDate date] dateByAddingSeconds:kRetryDefalutInterval + _retriedTimes]];
    _retriedTimes++;
    
    NSString *identifier = [[timer.userInfo allKeys] firstObject];
    NSData *data = nil;
    if (identifier) {
        data = [timer.userInfo objectForKey:identifier];
    }
    
    if (data) {
        [self writeData:data forIdentifier:identifier];
    }
}

- (void)writeData:(NSData *)data forIdentifier:(NSString *)identifier
{
//    NSLog(@"BLE Request write data[times=%ld]:%@", (long)_retriedTimes, data);
    dispatch_async(_bleDispatch, ^{
        UInt32 indexData = 0;
        UInt32 curMTU = 0;
        while ([data length] > indexData) {
            curMTU = kBLEMTU;
            if ([data length] < indexData + kBLEMTU) {
                curMTU = (UInt32)[data length] - indexData;
            }
            NSData *sendData = [data subdataWithRange:NSMakeRange(indexData, curMTU)];
            indexData = indexData + curMTU;
            
            [self.centralManager.pb writeValue:sendData forIdentifier:identifier];
        }
        [[BLERequstQueue shareInstance] pushQueue:self];
    });
}


#pragma mark - Getter & Setter
- (NSString *)identifier
{
    NSString *serviceReadUUID = [_serviceUUIDDict objectForKey:[_serviceUUIDDict.allKeys firstObject]];
    NSString *characteristicReadUUID = [_characteristicUUIDDict objectForKey:[_characteristicUUIDDict.allKeys firstObject]];
    return [NSString stringWithFormat:@"%@+%@+%@", serviceReadUUID, characteristicReadUUID,_protocolCMD];
}

- (BLECentralManager *)centralManager
{
    if (!_centralManager) {

        _centralManager = [BLECentralManager shareManager];
        _centralManager.delegate = self;
    }
    
    return _centralManager;
}

#pragma mark - BLECentralDelegate
- (BOOL)BLECentralDidReceiveDataForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    id protocol = [[[_protocol class] alloc] init];
    NSString *identifier = [BLEPeripheral generateIdentifierWithService:characteristic.service.UUID.UUIDString characteristic:characteristic.UUID.UUIDString];

    // 检查队列中是否存在分包接收数据的request
    BLEBaseRequest *request = [[BLERequstQueue shareInstance] queueSubpackWithTag:identifier];
    if (request) {
        protocol = request.protocol;
        
        //按照业务层协议解包
        if ([protocol respondsToSelector:@selector(unbuildingRecvData:)]) {
            protocol = [protocol unbuildingRecvData:characteristic.value];
        }
        
        if (!protocol) {
            return NO;
        }
        
        //检查解析包是否完成
        if ([protocol respondsToSelector:@selector(unbuildCompleted)]) {
            if (![protocol unbuildCompleted]) {
                return YES;
            }
        }
        
        //查找请求队列
        if ([protocol respondsToSelector:@selector(protocolCommand)]) {
            identifier = [NSString stringWithFormat:@"%@+%@", identifier, [protocol protocolCommand]];
        }
    }
    else
    {
        //按照业务层协议解包
        if ([protocol respondsToSelector:@selector(unbuildingRecvData:)]) {
            protocol = [protocol unbuildingRecvData:characteristic.value];
        }
        
        if (!protocol) {
            return NO;
        }
        
        //查找请求队列
        if ([protocol respondsToSelector:@selector(protocolCommand)]) {
            identifier = [NSString stringWithFormat:@"%@+%@", identifier, [protocol protocolCommand]];
        }

        request = [[BLERequstQueue shareInstance] queueWithTag:identifier];
        if (!request) {
//            NSLog(@"BLE cannot find request:[identifier=%@]", identifier);
            return NO;
        }
        request.protocol = protocol;
        
        //检查是否为ACK包
        if ([protocol respondsToSelector:@selector(isAckPackage)]) {
            if ([protocol isAckPackage]) {
                //Timer 关闭
                [request timerDisable];
                return YES;
            }
        }
        
        //检查解析包是否完成，若存在分包情况，则可能包还未接收完成
        if ([protocol respondsToSelector:@selector(unbuildCompleted)]) {
            if (![protocol unbuildCompleted]) {
                return YES;
            }
        }
    }
    
    //包已经解析完成，则pop出队列
    request = [[BLERequstQueue shareInstance] popQueue:identifier];
    if (request && request.callBack) {

        [request timeoutDisable];
        [request timerDisable];

        request.callBack(request.protocol, error);
    }

    return YES;
}

#warning For test, will remove
- (void)test
{
    TOBLEStackProtocol *protocol = [[TOBLEStackProtocol alloc] init];
    protocol.magic = kMagic;
    protocol.eventId = BANDFindProtocolKeyFindBand;
    protocol.moduleId = BANDProtocolModuleFind;
    protocol.dataLength = kLength;
    
    NSString *serviceReadUUID = [_serviceUUIDDict objectForKey:[_serviceUUIDDict.allKeys firstObject]];
    NSString *characteristicReadUUID = [_characteristicUUIDDict objectForKey:[_characteristicUUIDDict.allKeys firstObject]];
    CBUUID *uuid = [CBUUID UUIDWithString:characteristicReadUUID];
    CBMutableCharacteristic *cb = [[CBMutableCharacteristic alloc] initWithType:uuid properties:CBCharacteristicPropertyNotify value:[protocol buildSendData] permissions:CBAttributePermissionsReadable];
    
    uuid = [CBUUID UUIDWithString:serviceReadUUID];
    CBMutableService *service = [[CBMutableService alloc] initWithType:uuid primary:YES];
    [cb setValue:service forKeyPath:@"service"];
    
    [self BLECentralDidReceiveDataForCharacteristic:cb error:nil];
}
@end
