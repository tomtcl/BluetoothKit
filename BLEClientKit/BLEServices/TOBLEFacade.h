//
//  TOBLEAuthService.h
//  TheOne
//
//  Created by 王涛 on 2017/7/6.
//  Copyright © 2017年 tcl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TOBLERequest.h"
#import "BLEBaseRequest.h"

@interface TOBLEFacade : NSObject

/**
 *  绑定设备
 *
 *  @param userId      用户UID
 *  @param isFirstBind <#isFirstBind description#>
 *  @param isUTF8      <#isUTF8 description#>
 *  @param callback    <#callback description#>
 */
+ (void)requestBindDeviceWithUserID:(NSString *)userId
                        isFirstBind:(BOOL)isFirstBind
                       isUTF8Encode:(BOOL)isUTF8
                       withCallback:(BleCallBack)callback;

@end
