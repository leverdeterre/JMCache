//
//  JMCache.m
//  JMCache
//
//  Created by jerome morissard on 27/07/14.
//  Copyright (c) 2014 jerome morissard. All rights reserved.
//

#import "JMCache.h"
#import "JMCacheKey.h"

#import "JMCache+filePath.h"
#import "JMCache+ReadWrite.h"
#import "JMCache+InMemory.h"
#import "NSObject+JMCache.h"

@interface JMCache() <NSCacheDelegate>
@property (strong, nonatomic) NSCache *memoryCache;
@property (strong, nonatomic) NSMutableArray *allKeys;
@end

@implementation JMCache

+ (instancetype)sharedCache
{
    static JMCache *cache;
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
        writingQueue = dispatch_queue_create("com.jmcache.writingQueue", NULL);
        readingQueue = dispatch_queue_create("com.jmcache.readingQueue", NULL);
        propertySafeQueue = dispatch_queue_create("com.jmcache.propertySafeQueue", NULL);
        _cachePathType = JMCachePathPrivate;
        _cacheType = JMCacheTypeInMemory;
        //[self loadKeys];
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

#pragma mark - Get Cached data

/*
- (NSObject *)cachedObjectForKey:(NSString *)key
{
    if ([self.allKeys containsObject:key]) {
        NSString *path = [self filePathForKey:key];
        return [self decodeObjectForFilePath:path];
    }
    return nil;
}
 */

- (void)loadKeys
{
    NSString *path = [self filePathForAllKeys];
    _allKeys = [[self decodeObjectForFilePath:path] mutableCopy];
    if (nil == _allKeys) {
        _allKeys = [NSMutableArray new];
    }
}

- (void)cachedObjectForKey:(NSString *)key withCompletionBlock:(JMCacheCompletionBlockObjectError)block
{
    dispatch_async(propertySafeQueue, ^{
        if(self.cacheType & JMCacheTypeInMemory){
            id obj = [self.memoryCache objectForKey:key];
            if (obj){
                block(obj,nil);

                return; //stop with memmoy check if found
            }
        }
        
        
        JMCacheKey *cacheKey = [self cacheKeyForKey:key];
        if (cacheKey) {
            NSString *path = [self filePathForKey:key];
            
            if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
                block(nil,[NSError jmCacheErrorWithType:JMCacheErrorTypeFileMissing]);
                return ;
            }
            
            [self decodeObjectForFilePath:path withCompletionBlock:^(id obj) {
                [self.memoryCache setObject:obj forKey:key];
                block(obj,nil);
            }];
        } else {
            block(nil,[NSError jmCacheErrorWithType:JMCacheErrorTypeKeyMissing]);
        }
    });
}

/*
- (BOOL)cacheObject:(NSObject <NSCoding>*)obj forKey:(NSString *)key
{
    NSString *path = [self filePathForKey:key];
    BOOL res = [self encodeObject:obj inFilePath:path];
    if (res) {
        [self addKey:key];
    }
    return res;
}
 */

- (void)cacheObject:(NSObject *)obj forKey:(NSString *)key withCompletionBlock:(JMCacheCompletionBlockBoolError)block
{
    //Test if encode/decode is possible
    if ([obj.class canBeCoded]==NO || [obj.class canBeDecoded]==NO) {
        block(NO,[NSError jmCacheErrorWithType:JMCacheErrorTypeKeyMissing]);
        return;
    }

    NSString *path = [self filePathForKey:key];
    JMCacheCompletionBlockBool block2 = ^(BOOL res){
        if(res) {
            JMCacheKey *cacheKey = [JMCacheKey cacheKeyWithKey:key andClass:obj.class];
            __weak JMCache *weakSelf = self;
            [self addCacheKey:cacheKey withCompletionBlock:^(BOOL boole) {
                [weakSelf.memoryCache setObject:obj forKey:key];
                if (block) {
                    block(res, nil);
                }
            }];
        }
    };
    
    [self encodeObject:obj inFilePath:path withCompletionBlock:block2];
}

//Remove cached data
- (void)removeCachedObjectForKey:(NSString *)key withCompletionBlock:(JMCacheCompletionBlockBoolError)block
{
    dispatch_async(propertySafeQueue, ^{
        JMCacheKey *cacheKey = [self cacheKeyForKey:key];
        if (cacheKey) {
            NSString *path = [self filePathForKey:cacheKey.key];
            NSError *error;
            BOOL res = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
            
            if (res) {
                __weak JMCache *weakSelf = self;
                [self removeCacheKey:cacheKey withCompletionBlock:^(BOOL boole) {
                    [weakSelf.memoryCache removeObjectForKey:cacheKey.key];
                    if (block) {
                        block(res, error);
                    }
                }];
            }
        } else {
            block(NO,[NSError jmCacheErrorWithType:JMCacheErrorTypeKeyMissing]);
        }
    });
}

- (void)addCacheKey:(JMCacheKey *)cacheKey withCompletionBlock:(JMCacheCompletionBlockBool)block
{
    dispatch_async(propertySafeQueue, ^{
        [self.allKeys addObject:cacheKey];
        [self encodeObject:self.allKeys inFilePath:[self filePathForAllKeys] withCompletionBlock:block];
    });
}

- (void)removeCacheKey:(JMCacheKey *)cacheKey withCompletionBlock:(JMCacheCompletionBlockBool)block
{
    dispatch_async(propertySafeQueue, ^{
        [self.allKeys removeObject:cacheKey];
        [self.memoryCache removeObjectForKey:cacheKey];
        [self encodeObject:self.allKeys inFilePath:[self filePathForAllKeys] withCompletionBlock:block];
    });
}

- (void)clearCacheWithCompletionBlock:(JMCacheCompletionBlockBool)block;
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        dispatch_group_t group = dispatch_group_create();
        
        for(NSString *key in [self.allKeys valueForKey:@"key"]){
            dispatch_group_enter(group);
            [self removeCachedObjectForKey:key withCompletionBlock:^(BOOL boole, NSError *error) {
                dispatch_group_leave(group);
            }];
        }
        
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        if (block) {
            block(YES);
        }
    });
}

- (JMCacheKey *)cacheKeyForKey:(NSString *)key
{
    if (self.allKeys == nil) {
        [self loadKeys];
    }
    
    NSInteger index = [[self.allKeys valueForKey:@"key"] indexOfObject:key];
    if (index != NSNotFound) {
        return self.allKeys[index];
    }
    
    return nil;
}

@end
