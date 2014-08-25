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

/**
 *  JMCachePathType
 */
typedef NS_ENUM(NSUInteger, JMCachePathType) {
    /**
     *  Save Cache into public path
     */
    JMCachePathPublic,
    /**
     *  Save Cache into private path
     */
    JMCachePathPrivate,
    /**
     *  Save Cache into online path
     */
    JMCachePathOffline
};

/**
 *  JMCacheType
 */
typedef NS_OPTIONS(NSUInteger, JMCacheType) {
    /**
     *  JMCache just in memory
     */
    JMCacheTypeInMemory             = 1,
    /**
     *  JMCache just on disk
     */
    JMCacheTypeOnDisk               = 1 << 1,
    /**
     *  JMCache just on memory / disk
     */
    JMCacheTypeInMemoryThenOnDisk   = (JMCacheTypeInMemory | JMCacheTypeOnDisk)
};

@interface JMCache : NSObject
{
    dispatch_queue_t readingQueue;
    dispatch_queue_t writingQueue;
    dispatch_queue_t propertySafeQueue;
}

+ (instancetype)sharedCache;

/**
 *  Configure your JMCachePath
 */
@property (assign, nonatomic) JMCachePathType cachePathType;

/**
 *  Configure your JMCacheType
 */
@property (assign, nonatomic) JMCacheType cacheType;

/**
 *  Configure a global JMCacheValueTransformer, whitch is going to be use for each encode / decode encoding methods
 */
@property (strong, nonatomic) JMCacheValueTransformer *valueTransformer;

/**
 *  Configure a preferredCompletionQueue
 */
@property (nonatomic, strong) dispatch_queue_t preferredCompletionQueue;

/**
 *  Get oject for key (Async)
 *
 *  @param key   NString
 *  @param block completionBlock
 */
- (void)objectForKey:(NSString *)key withCompletionBlock:(JMCacheCompletionBlockObjectError)block;

/**
 *  Set oject for key (Async)
 *
 *  @param obj   id object
 *  @param key   NString
 *  @param block completionBlock
 */
- (void)setObject:(NSObject *)obj forKey:(NSString *)key withCompletionBlock:(JMCacheCompletionBlockBoolError)block;

/**
 *  Remove oject for key (Async)
 *
 *  @param key   NString
 *  @param block completionBlock
 */
- (void)removeObjectForKey:(NSString *)key withCompletionBlock:(JMCacheCompletionBlockBoolError)block;

/**
 *  Remove all objects for key (Async)
 *
 *  @param block completionBlock
 */
- (void)clearCacheWithCompletionBlock:(JMCacheCompletionBlockBool)block;

// Sync API
/**
 *  Get oject for key (Sync)
 *
 *  @param key NString
 *
 *  @return id stored object
 */
- (id)objectForKey:(NSString *)key;

/**
 *  Set oject for key (Sync)
 *
 *  @param obj id stored object
 *  @param key NString
 *
 *  @return Boolean value
 */
- (BOOL)setObject:(NSObject *)obj forKey:(NSString *)key;

/**
 *  Get number of stored ojects (Sync)
 *
 *  @return NSInteger
 */
- (NSInteger)numberOfCachedObjects;

@end
