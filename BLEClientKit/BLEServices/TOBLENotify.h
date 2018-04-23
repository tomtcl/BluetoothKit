//
//  TOBLENotify.h
//  TheOne
//
//  Created by 王涛 on 2017/8/2.
//  Copyright © 2017年 tcl. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString *const BLENotifyOTA;
extern NSString *const BLENotifyAlarm;

@interface TOBLENotify : NSObject

+ (instancetype)shareInstance;

@end
