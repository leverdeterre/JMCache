//
//  JMCacheMemory.m
//  JMCache
//
//  Created by jerome morissard on 03/08/14.
//  Copyright (c) 2014 jerome morissard. All rights reserved.
//

#import "JMCacheMemory.h"

@interface JMCacheMemory() <NSCacheDelegate>
{
    dispatch_queue_t privateQueue;
}

@property (strong, nonatomic) NSCache *memoryCache;
@end


@implementation JMCacheMemory

+ (instancetype)sharedCache
{
    static JMCacheMemory *cache;
    static dispatch_once_t predicate;
    
    dispatch_once(&predicate, ^{
        cache = [[self alloc] init];
    });
    
    return cache;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        privateQueue = dispatch_queue_create("com.jmcache.memory.privateQueue", NULL);
        [self cacheInMemoryInitialize];
    }
    return self;
}

- (void)cacheInMemoryInitialize
{
    _memoryCache = [[NSCache alloc] init];
    _memoryCache.name = @"com.jmcache.in.memory.cache";
    _memoryCache.countLimit = 100;
    _memoryCache.delegate = self;
}

- (void)cachedObjectInMemoryForKey:(NSString *)key withCompletionBlock:(JMCacheCompletionBlockObjectError)block
{
    dispatch_async(privateQueue, ^{
        id obj = [self.memoryCache objectForKey:key];
        JM_BLOCK_SAFE_RUN(block,obj,nil);
    });
}

- (void)removeCachedObjectInMemoryForKey:(NSString *)key withCompletionBlock:(JMCacheCompletionBlockBoolError)block
{
    dispatch_async(privateQueue, ^{
        [self.memoryCache removeObjectForKey:key];
        JM_BLOCK_SAFE_RUN(block,YES,nil);
    });
}

- (void)cacheObject:(NSObject *)obj forKey:(NSString *)key withCompletionBlock:(JMCacheCompletionBlockBoolError)block
{
    dispatch_async(privateQueue, ^{
        [self.memoryCache setObject:obj forKey:key];
        JM_BLOCK_SAFE_RUN(block,YES,nil);
    });
}

@end
