//
//  BleCentralManager.m
//  TheOne
//
//  Created by 王涛 on 2017/6/8.
//  Copyright © 2017年 tcl. All rights reserved.
//

#import "BLECentralManager.h"


NSString *const BLECentralStateDidChangedNotification = @"BLECentralStateDidChangedNotification";
NSString *const BLECentralCharacteristicDidUpdateValue = @"BLECentralCharacteristicDidUpdateValue";
NSString *const BLECentralCharacteristicDidWriteValue = @"BLECentralCharacteristicDidWriteValue";
@interface BLECentralManager()<CBCentralManagerDelegate,CBPeripheralDelegate>

@property (nonatomic, strong, readwrite) CBCentralManager *centralManager;  //中心设备管理器
@property (nonatomic, strong, readwrite) NSMutableArray *peripherals;       //发现的外围设备
@property (nonatomic, strong, readwrite) NSMutableArray *tmpPeripherals;
@property (nonatomic, strong, readwrite) BLEPeripheral *pb;
@property (nonatomic, assign) BLECentralState    state;

@end

#define kDefalutTaskTimeout                 15

@implementation BLECentralManager

#pragma mark - Life Cycle
+ (instancetype)shareManager
{
    static BLECentralManager *manager = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    
    return manager;
}

- (id)init
{
    self = [super init];
    if (self) {
        _centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:nil options:nil];
        
        _pb = [[BLEPeripheral alloc] init];
    }
    return self;
}

- (void)dealloc
{
    self.centralManager = nil;
}

#pragma mark - Public Function
- (void)startScan
{
    if (self.state == BLECentralStateInvalid) {
        NSLog(@"BLECentral:: Please open device bluetooth first...");
        return;
    }
    
    if (self.state == BLECentralStateScaning) {
        [self stopScan];
    }
    
    if (self.peripherals.count) {
        [self.peripherals removeAllObjects];
    }
    
    if (self.tmpPeripherals.count) {
        [self.tmpPeripherals removeAllObjects];
    }
    
    NSLog(@"BLECentral:: Start to scan...");
    [_centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
    self.state = BLECentralStateScaning;
    
    [self performSelector:@selector(taskTimeout:) withObject:@(self.state) afterDelay:kDefalutTaskTimeout];
}

- (void)startScanWithTimeout:(NSInteger)timeout
{
    if (self.state == BLECentralStateInvalid) {
        NSLog(@"BLECentral:: Please open device bluetooth first...");
        return;
    }
    
    if (self.state == BLECentralStateScaning) {
        [self stopScan];
    }
    
    if (self.peripherals.count) {
        [self.peripherals removeAllObjects];
    }
    
    if (self.tmpPeripherals.count) {
        [self.tmpPeripherals removeAllObjects];
    }
    
    NSLog(@"BLECentral:: Start to scan...");
    [_centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
    self.state = BLECentralStateScaning;
    
    [self performSelector:@selector(taskTimeout:) withObject:@(self.state) afterDelay:timeout];
}

- (void)stopScan
{
    [_centralManager stopScan];
    
    NSLog(@"BLECentral:: Scaning stoped...");
    if (self.state < BLECentralStateDiscovered && self.state > BLECentralStateIdle) {
        self.state = BLECentralStateIdle;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(taskTimeout:) object:@(BLECentralStateScaning)];
}

- (void)connect:(BLEPeripheral *)bracelet
{
    if (self.state == BLECentralStateInvalid) {
        NSLog(@"BLECentral:: Please open device bluetooth first...");
        return;
    }
    
    if (bracelet) {
        NSLog(@"BLECentral:: Start to connecting [%@]", bracelet.cbPeripheral.name);
        self.state = BLECentralStateConnecting;

        _pb.cbPeripheral = bracelet.cbPeripheral;
        [_centralManager connectPeripheral:bracelet.cbPeripheral options:nil];

        [self performSelector:@selector(taskTimeout:) withObject:@(self.state) afterDelay:kDefalutTaskTimeout];
    }
}

- (void)disConnect
{
    if (_pb.cbPeripheral) {
        [_centralManager cancelPeripheralConnection:_pb.cbPeripheral];
        
        self.state = BLECentralStateUnConnected;
    }
}

- (void)retrieveKnownPeripherals:(NSString *)uuidStr macstr:(NSString *)macstr
{
    NSMutableArray *identifiers = [NSMutableArray array];
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidStr];
    if (uuid) {
        [identifiers addObject:uuid];
    }
    if ([identifiers count] > 0) {
        NSArray *result = [_centralManager retrievePeripheralsWithIdentifiers:identifiers];
        for (CBPeripheral *aperipheral in result) {
            NSLog(@"BLECentral:: Start to connecting [%@]", aperipheral.name);
            _pb.cbPeripheral = aperipheral;

            [_centralManager connectPeripheral:aperipheral options:nil];
            self.state = BLECentralStateConnecting;
            [self performSelector:@selector(taskTimeout:) withObject:@(self.state) afterDelay:kDefalutTaskTimeout];
        }
    }else{
        NSArray *result = [_centralManager retrieveConnectedPeripheralsWithServices:@[[CBUUID UUIDWithString:@""]]];
    }
}

- (void)subscribeService:(NSString *)serviceUUID characteristic:(NSString *)charactUUID
{
    if (_pb) {
        [_pb addService:serviceUUID characteristic:charactUUID];
    }
}

#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"BLECentral:: CBManagerState did changed:%ld", (long)central.state);
    BOOL state = (central.state == CBCentralManagerStatePoweredOn) ? YES : NO;
    
    self.state = (state) ? BLECentralStateIdle : BLECentralStateInvalid;
}


- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
//    NSLog(@"BLECentral:: Did discover peripheral[%@, %@, %@]", peripheral.name, RSSI, advertisementData);

    if (peripheral) {
        self.state = BLECentralStateDiscovered;
        BLEPeripheral *bracelet = [[BLEPeripheral alloc] init];
        bracelet.cbPeripheral = peripheral;
        
        if(![self.tmpPeripherals containsObject:peripheral]){
            [self.tmpPeripherals addObject:peripheral];
            
            [self.peripherals addObject:bracelet];
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"BLECentral:: Did Connected peripheral[%@]", peripheral.name);
    
    peripheral.delegate=self;
    self.state = BLECentralStateConnected;
    [peripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"BLECentral:: Did fail to connect peripheral:%@ error[%@]", peripheral.name, error);
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(taskTimeout:) object:@(BLECentralStateConnecting)];
    
    self.state = BLECentralStateUnConnected;
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"BLECentral:: Did disconnect peripheral:%@ error[%@]", peripheral.name, error);
    if (error) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(taskTimeout:) object:@(BLECentralStateConnecting)];
        
        if (error.code == 6) {
            [self connect:_pb];  //iphone BLE 异常断开处理
        }
        self.state = BLECentralStateUnConnected;
    }
}

#pragma mark - CBPeripheralDelegate
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        NSLog(@"BLECentral:: Did discover services error[%@]", error);
        return;
    }
    
    NSLog(@"BLECentral:: Did discover services");
    
    for (CBService *service in peripheral.services) {
        //外围设备查找指定服务中的特征
        [peripheral discoverCharacteristics:nil forService:service];
    }
    
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{

    if (error) {
        NSLog(@"BLECentral:: Did discover characteristics error[%@]", error);
        return;
    }
    NSLog(@"BLECentral:: Did discover characteristics for service %@", service);

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(taskTimeout:) object:@(BLECentralStateConnecting)];


    NSArray *services = [_pb services];
    if (services.count && [services indexOfObject:service.UUID.UUIDString] != NSNotFound) {

        NSArray *characteristics = [_pb characteristicForService:service.UUID.UUIDString];
        for (CBCharacteristic *characteristic in service.characteristics) {
            //            NSLog(@"BLECentral:: Did discover characteristics: %@", characteristic);

            if (characteristics.count && [characteristics indexOfObject:characteristic.UUID.UUIDString] != NSNotFound) {
                NSLog(@"BLECentral:: Did Subscribe Characterisic: %@", characteristic);
                
                [_pb registerForService:service characteristic:characteristic];

                if ((characteristic.properties & CBCharacteristicPropertyNotify) == CBCharacteristicPropertyNotify) {
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                    
                }
    
                //Test Characteristic value
                [peripheral readValueForCharacteristic:characteristic];
                if (characteristic.value) {
                    
                    self.state = BLECentralStateRuning;
                    
                    NSLog(@"BLECentral:: Did Enable Read Characterisic value: %@", [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding]);
                }
            }
        }
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{

    if (error) {
        NSLog(@"BLECentral:: Did update notification Characteristic[%@] error: %@",characteristic, error );
        return;
    }
    
    NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    
    NSLog(@"BLECentral:: Did update notification state for characteristic [%@:%@]", characteristic, stringFromData);
    
    self.state = BLECentralStateRuning;

    if (characteristic.properties == CBCharacteristicPropertyRead) {
        [peripheral readValueForCharacteristic:characteristic];
    }

}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"BLECentral:: Did update value Characteristic[%@] error: %@",characteristic, error );
        return;
    }
    NSLog(@"receive Data = %@",characteristic.value);
    self.state = BLECentralStateRuning;
    
    BOOL isRequestData = NO;
    if ([_delegate respondsToSelector:@selector(BLECentralDidReceiveDataForCharacteristic:error:)]) {
        isRequestData = [_delegate BLECentralDidReceiveDataForCharacteristic:characteristic error:error];
    }
    
    if (!isRequestData && characteristic.isNotifying && !error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:BLECentralCharacteristicDidUpdateValue object:characteristic];
    }

}
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
   if (error) {
       NSLog(@"BLECentral:: Did Write value error %@", error);
   }else{
       NSLog(@"BLECentral:: Did write value %@ ",characteristic.value);
       [[NSNotificationCenter defaultCenter] postNotificationName:BLECentralCharacteristicDidWriteValue object:characteristic];
   }
}
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error
{
   if (!error) {
      NSLog(@"did write success %@",descriptor.value);
   }else{
      NSLog(@"BLECentral:: Did update value error %@", error);
   }
}

#pragma mark - Getter & Setter
- (NSMutableArray *)peripherals
{
    if (!_peripherals) {
        _peripherals = [NSMutableArray array];
    }
    return _peripherals;
}

- (NSMutableArray *)tmpPeripherals
{
    if (!_tmpPeripherals) {
        _tmpPeripherals = [NSMutableArray array];
    }
    
    return _tmpPeripherals;
}

- (void)setState:(BLECentralState)state
{
    if (_state != state || state == BLECentralStateDiscovered) {
        _state = state;
        
        [self updateCentralManagerState:_state userInfo:nil];
    }
}


#pragma mark - Private Function

- (void)updateCentralManagerState:(BLECentralState)state userInfo:(NSDictionary *)userInfo
{
    NSLog(@"BLECentral:: Ble state did changed:%ld", (long)_state);
    [[NSNotificationCenter defaultCenter] postNotificationName:BLECentralStateDidChangedNotification object:self.pb userInfo:userInfo];
}

- (void)taskTimeout:(NSNumber *)state
{
    NSLog(@"BLECentral:: Task timeout on state:%ld", (long)_state);
    switch ([state integerValue]) {
        case BLECentralStateScaning:
        {
            [self stopScan];
        }
            break;
        case BLECentralStateConnecting:
        {
            [self disConnect];
        }
            break;
        default:
            break;
    }
}

@end
