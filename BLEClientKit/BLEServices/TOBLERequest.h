//
//  TOBLERequest.h
//  TheOne
//
//  Created by 王涛 on 2017/7/6.
//  Copyright © 2017年 tcl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLEBaseRequest.h"
#import "TOBLEStackProtocol.h"

@protocol SBBleRequestProtocol

@required
- (TOBLEStackProtocol *)configCommand;
@end


@interface TOBLERequest : BLEBaseRequest<SBBleRequestProtocol>

@property (nonatomic, assign) UInt8  moduleId;
@property (nonatomic, assign) UInt8  keyId;
@property (nonatomic, strong) NSData *dataValue;
- (id)initWithCommendId:(UInt8)mId KeyId:(UInt8)kId;
- (id)initWithCommendId:(UInt8)mId KeyId:(UInt8)kId DataValue:(NSData *)dv;
@end


#pragma mark - BANDProtocolModuleBindLogin -
@interface TOBleBindDeviceRequest : TOBLERequest {
    NSString *_userId;
    BOOL _isFirstBind;
    BOOL _isUTF8Encode;
}

- (instancetype)initWithUserID:(NSString *)userId isFirstBind:(BOOL)isFirstBind isUTF8Encode:(BOOL)isUTF8;
@end

@interface TOBleWatchUnpairRequest : TOBLERequest



@end

@interface TOBleDisconnectedRequest : TOBLERequest{

}

@end

@interface TOBleSetTokenRequest : TOBLERequest{

}

@end

@interface TOBleGetTokenRequest : TOBLERequest{

}

@end


#pragma mark - BANDProtocolModuleSetting -


@interface TOBleSetGoalsRequest : TOBLERequest {
}
/**
 *  发送手机端设置的goals到手环端
 *
 *  @param steps    steps goal
 *  @param calories calories goal
 *  @param distance distance goal
 *  @param duration duration goal
 *  @param sleep    sleep goal
 *
 *  @return 初始化返回
 */
- (instancetype)initWithSteps:(UInt32)steps
                     calories:(UInt32)calories
                     distance:(UInt32)distance
                     duration:(UInt32)duration
                        sleep:(UInt32)sleep;
@property(nonatomic, assign) UInt32 steps;
@property(nonatomic, assign) UInt32 calories;
@property(nonatomic, assign) UInt32 distance;
@property(nonatomic, assign) UInt32 duration;
@property(nonatomic, assign) UInt32 sleep;
@end


@interface TOBleGetSerialPort : TOBLERequest{

}

@end

@interface TOBleGetDeviceNameRequset : TOBLERequest{

}

@end

@interface TOBleGetMACAddressRequest : TOBLERequest{

}

@end



@interface TOBleSyncTimeRequest : TOBLERequest{

}

@end

@interface TOBleResetDevice : TOBLERequest{

}

@end


@interface TOBleSettingGetBatteryRequest : TOBLERequest{

}

@end
@interface TOBleRenameRequest : TOBLERequest{
}
- (instancetype)initWithName:(NSString *)nameString;
@end




#pragma mark - BANDProtocolModuleSensorData -

@interface TOBleRealTimeSwitchRequest : TOBLERequest {
   BOOL _isOn;
}
- (id)initWithIsOn:(BOOL)isOn;

@end

@interface TOBleGetHistoryDataStartRequest : TOBLERequest


- (id)initWithTimeStamp:(long long)timeStamp;
@end

#pragma mark - BANDProtocolModuleFind -

@interface TOBleFindMeResultRequest : TOBLERequest

- (id) init;

@end

#pragma mark - BANDProtocolModuleNotification -


@interface TOBleNotificationRequest : TOBLERequest
{
   
}
- (instancetype)initWithNotiData:(NSData *)data ;

@end





@interface TOBleSettingSwitchRequest : TOBLERequest {
}

- (id)initWithisOn:(BOOL)isOn;
@end



@interface TOBleCameraMusicStateRequest : TOBLERequest

- (id)initWithKeyId:(UInt8)mkeyId;


@end


/// 发送音乐播放状态
@interface TOBleMusicStateRequest : TOBLERequest {
    BOOL _isPlaying;
}

- (instancetype)initWithPlayState:(BOOL)isPlaying;

@end

@interface TOBleMusicUnusualStateRequest : TOBLERequest {
    UInt8 _unusualState;
}

- (instancetype)initWithState:(UInt8)state;

@end


@interface TOBleCameraRequest : TOBLERequest

- (id)initWithKeyId:(UInt8)mkeyId;

@end


#pragma mark - BANDProtocolModuleAlarm -

@interface TOBleSetAlarmsRequest : TOBLERequest{

}
- (instancetype)initWithAlarms:(NSArray *)arrayAlarms;
@end


@interface TOBleStopAlarmsSettings : TOBLERequest{

}

@end

