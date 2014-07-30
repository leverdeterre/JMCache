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
typedef void (^JMCacheCompletionBlockBool)(BOOL boole);
typedef void (^JMCacheCompletionBlockBoolError)(BOOL boole, NSError *error);

typedef NS_ENUM(NSUInteger, JMCachePathType) {
    JMCachePathPublic,
    JMCachePathPrivate,
    JMCachePathOffline
};

typedef NS_OPTIONS(NSUInteger, JMCacheType) {
    JMCacheTypeInMemory = 1,
    JMCacheTypeOnDisk   = 1 << 1,
    JMCacheTypeBoth     = 1 << 2
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
@property (strong, nonatomic) dispatch_queue_t preferredCompletionQueue;
@property (readonly, nonatomic) NSMutableArray *allKeys;

//Get cached data
//- (NSObject *)cachedObjectForKey:(NSString *)key;
- (void)cachedObjectForKey:(NSString *)key withCompletionBlock:(JMCacheCompletionBlockObjectError)block;

//Set cached data
//- (BOOL)cacheObject:(NSObject <NSCoding>*)obj forKey:(NSString *)key;
- (void)cacheObject:(NSObject <NSCoding>*)obj forKey:(NSString *)key withCompletionBlock:(JMCacheCompletionBlockBool)block;

//Remove cached data
- (void)removeCachedObjectForKey:(NSString *)key withCompletionBlock:(JMCacheCompletionBlockBoolError)block;
- (void)clearCacheWithCompletionBlock:(JMCacheCompletionBlockBool)block;

@end
