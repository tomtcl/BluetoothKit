//
//  TOBLERequest.m
//  TheOne
//
//  Created by 王涛 on 2017/7/6.
//  Copyright © 2017年 tcl. All rights reserved.
//

#import "TOBLERequest.h"


@implementation TOBLERequest
@synthesize moduleId, keyId, dataValue;

- (id)initWithCommendId:(UInt8)mId KeyId:(UInt8)kId {
   self = [super init];
   if (self) {
      moduleId = mId;
      keyId = kId;
   }
   return self;
}

- (id)initWithCommendId:(UInt8)mId KeyId:(UInt8)kId DataValue:(NSData *)dv {
   self = [super init];
   if (self) {
      moduleId = mId;
      keyId = kId;
      dataValue = dv;
   }
   return self;
}
/**
 * 配置BLE协议栈报文

 @return 协议结构体
 */
- (TOBLEStackProtocol *)configCommand
{
    TOBLEStackProtocol * protocol = [[TOBLEStackProtocol alloc] init];
    protocol.magic = kMagic;
    protocol.moduleId = self.moduleId;
    protocol.eventId = self.keyId;
    
    return protocol;
}

@end

#pragma mark - BANDProtocolModuleBindLogin -
@implementation TOBleBindDeviceRequest

- (instancetype)initWithUserID:(NSString *)userId isFirstBind:(BOOL)isFirstBind isUTF8Encode:(BOOL)isUTF8
{
    if (self = [super init]) {
       _userId = userId;
       _isFirstBind = isFirstBind;
       if (_isFirstBind) {
          _isUTF8Encode = NO;
       }else{
          _isUTF8Encode = isUTF8;
       }
       self.moduleId = BANDProtocolModuleBindLogin;
       if (_isFirstBind) {
          self.keyId = BANDBindProtocolKeyBind;
       }else{
          self.keyId = BANDBindProtocolkeyLogin;
       }

    }
    return self;
}

- (TOBLEStackProtocol *)configCommand
{
    return protocol;
}
@end






