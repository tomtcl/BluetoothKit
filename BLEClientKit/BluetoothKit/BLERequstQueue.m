//
//  BLERequstQueue.m
//  TheOne
//
//  Created by 王涛 on 2017/7/5.
//  Copyright © 2017年 tcl. All rights reserved.
//

#import "BLERequstQueue.h"


@interface BLERequstQueue()

/**
 * 请求队列，存储所有请求对象实例，当队列未空时，BLERequstQueue对象销毁
 */
@property (nonatomic, strong) NSDictionary *queue;

@end

static BLERequstQueue *shareInstance = nil;
static dispatch_once_t onceToken;

@implementation BLERequstQueue

#pragma mark - Life Cycle
+ (instancetype)shareInstance
{
    dispatch_once(&onceToken, ^{
        shareInstance = [[self alloc] init];
    });
    
    return shareInstance;
}

+ (void)deinit
{
    if (shareInstance) {
        shareInstance = nil;
        onceToken = 0l;
    }
}

- (void)dealloc
{
//    NSLog(@"%@ has delloc", [self class]);
}

#pragma mark - Public Method
- (NSInteger)requestQueueCount
{
    @synchronized (self) {
        return [_queue.allKeys count];
    }
}

- (void)pushQueue:(BLEBaseRequest *)request
{
    @synchronized (self) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:_queue];
    
        [dict setObject:request forKey:[request identifier]];
    
        _queue = [dict copy];

    }
}

- (BLEBaseRequest *)popQueue:(NSString *)identifier
{
    if (identifier) {
        @synchronized (self) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:_queue];

            BLEBaseRequest *request = [dict objectForKey:identifier];
            
            [dict removeObjectForKey:identifier];
            _queue = [dict copy];
        
            if (![self requestQueueCount]) {
                [[self class] deinit];
            }
            return request;
        }
    }
    
    return nil;
}

- (BLEBaseRequest *)queueWithTag:(NSString *)identifier
{
    if (identifier) {
        @synchronized (self) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:_queue];
            BLEBaseRequest *request = [dict objectForKey:identifier];
            return request;
        }
    }
    
    return nil;
}

- (BLEBaseRequest *)queueSubpackWithTag:(NSString *)UUIDString
{
    if (UUIDString) {
        @synchronized (self) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:_queue];
            
            for (NSString *key in dict.allKeys) {
                if ([key rangeOfString:UUIDString].location != NSNotFound) {
                    BLEBaseRequest *request = [dict objectForKey:key];
                    if ([request.protocol respondsToSelector:@selector(hasSubPackage)]) {
                        if ([request.protocol hasSubPackage]){
                            return request;
                        }
                    }
                }
            }
        }

    }
    
    return nil;
}
@end
