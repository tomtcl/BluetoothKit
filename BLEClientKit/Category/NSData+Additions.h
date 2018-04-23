//
//  NSData+Additions.h
//  TheOne
//
//  Created by kcl on 2017/7/17.
//  Copyright © 2017年 tcl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (Additions)

- (NSString *)macAddrString;

- (UInt16)crc16;
@end
