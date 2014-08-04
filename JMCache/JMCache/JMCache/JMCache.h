//
//  JMCache.h
//  JMCache
//
//  Created by jerome morissard on 27/07/14.
//  Copyright (c) 2014 jerome morissard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JMCacheValueTransformer.h"
#import "NSError+JMCache.h"

typedef void (^JMCacheCompletionBlockObjectError)(id obj, NSError *error);
typedef void (^JMCacheCompletionBlockObject)(id obj);
typedef void (^JMCacheCompletionBlockBool)(BOOL resul);
typedef void (^JMCacheCompletionBlockBoolError)(BOOL resul, NSError *error);

void dispatch_optional_queue_async(dispatch_queue_t optionalQueue, dispatch_block_t block);

#define JM_BLOCK_SAFE_RUN(block, ...) block ? block(__VA_ARGS__) : nil

typedef NS_ENUM(NSUInteger, JMCachePathType) {
    JMCachePathPublic,
    JMCachePathPrivate,
    JMCachePathOffline
};

typedef NS_OPTIONS(NSUInteger, JMCacheType) {
    JMCacheTypeInMemory             = 1,
    JMCacheTypeOnDisk               = 1 << 1,
    JMCacheTypeInMemoryThenOnDisk   = (JMCacheTypeInMemory | JMCacheTypeOnDisk)
};

@interface JMCache : NSObject
{
    dispatch_queue_t readingQueue;
    dispatch_queue_t writingQueue;
    dispatch_queue_t propertySafeQueue;
}

+ (instancetype)sharedCache;

// https://github.com/nicklockwood/FastCoding
// zip / crypt data
//

@property (assign, nonatomic) JMCachePathType cachePathType;
@property (assign, nonatomic) JMCacheType cacheType;
@property (strong, nonatomic) JMCacheValueTransformer *valueTransformer;
@property (nonatomic, strong) dispatch_queue_t preferredCompletionQueue;

// Async API
- (void)cachedObjectForKey:(NSString *)key withCompletionBlock:(JMCacheCompletionBlockObjectError)block;
- (void)cacheObject:(NSObject *)obj forKey:(NSString *)key withCompletionBlock:(JMCacheCompletionBlockBoolError)block;
- (void)removeCachedObjectForKey:(NSString *)key withCompletionBlock:(JMCacheCompletionBlockBoolError)block;
- (void)clearCacheWithCompletionBlock:(JMCacheCompletionBlockBool)block;

// Sync API
- (id)cachedObjectForKey:(NSString *)key;
- (BOOL)cacheObject:(NSObject *)obj forKey:(NSString *)key;
- (NSInteger)numberOfObjectInJMCache;

@end
