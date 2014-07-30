//
//  JMCache.m
//  JMCache
//
//  Created by jerome morissard on 27/07/14.
//  Copyright (c) 2014 jerome morissard. All rights reserved.
//

#import "JMCache.h"
#import "JMCache+filePath.h"
#import "JMCache+ReadWrite.h"
#import "JMCache+InMemory.h"

@interface JMCache() <NSCacheDelegate>
@property (strong, nonatomic) NSCache *memoryCache;
@end

@implementation JMCache

@synthesize allKeys = _allKeys;

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

#pragma mark - Overided accessors

- (NSMutableArray *)allKeys
{
    if (nil == _allKeys) {
        NSString *path = [self filePathForAllKeys];
        _allKeys = [[self decodeObjectForFilePath:path] mutableCopy];
        if (nil == _allKeys) {
            _allKeys = [NSMutableArray new];
        }
    }
    
    return _allKeys;
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

- (void)cachedObjectForKey:(NSString *)key withCompletionBlock:(JMCacheCompletionBlockObjectError)block
{
    dispatch_async(propertySafeQueue, ^{
        if(self.cacheType & JMCacheTypeInMemory){
            id obj = [self.memoryCache objectForKey:key];
            if (obj){
                if (self.preferredCompletionQueue) {
                    dispatch_async(self.preferredCompletionQueue, ^{
                        block(obj,nil);
                    });
                } else {
                    block(obj,nil);
                }
                return; //stop with memmoy check if found
            }
        }
            
        if ([self.allKeys containsObject:key]) {
            NSString *path = [self filePathForKey:key];
            
            if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
                if (self.preferredCompletionQueue) {
                    dispatch_async(self.preferredCompletionQueue, ^{
                        block(nil,[NSError jmCacheErrorWithType:JMCacheErrorTypeFileMissing]);
                    });
                } else {
                    block(nil,[NSError jmCacheErrorWithType:JMCacheErrorTypeFileMissing]);
                }
                return ;
            }
            
            [self decodeObjectForFilePath:path withCompletionBlock:^(id obj) {
                [self.memoryCache setObject:obj forKey:key];
                
                if (self.preferredCompletionQueue) {
                    dispatch_async(self.preferredCompletionQueue, ^{
                        block(obj,nil);
                    });
                } else {
                    block(obj,nil);
                }
            }];
        } else {
            if (self.preferredCompletionQueue) {
                dispatch_async(self.preferredCompletionQueue, ^{
                    block(nil,[NSError jmCacheErrorWithType:JMCacheErrorTypeKeyMissing]);
                });
            } else {
                block(nil,[NSError jmCacheErrorWithType:JMCacheErrorTypeKeyMissing]);
            }
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

- (void)cacheObject:(NSObject<NSCoding> *)obj forKey:(NSString *)key withCompletionBlock:(JMCacheCompletionBlockBool)block
{
    NSString *path = [self filePathForKey:key];
    JMCacheCompletionBlockBool block2 = ^(BOOL res){
        if(res) {
            [self addKey:key];
            [self.memoryCache setObject:obj forKey:key];
        }
        
        if (block) {
            if (self.preferredCompletionQueue) {
                dispatch_async(self.preferredCompletionQueue, ^{
                    block(res);
                });
            } else {
                block(res);
            }
        }
    };
    
    [self encodeObject:obj inFilePath:path withCompletionBlock:block2];
}

//Remove cached data
- (void)removeCachedObjectForKey:(NSString *)key withCompletionBlock:(JMCacheCompletionBlockBoolError)block
{
    dispatch_async(propertySafeQueue, ^{
        if ([self.allKeys containsObject:key]) {
            NSString *path = [self filePathForKey:key];
            NSError *error;
            BOOL res = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
            
            if (res) {
                [self removeKey:key];
                [self.memoryCache removeObjectForKey:key];
            }
            
            if (block) {
                if (self.preferredCompletionQueue) {
                    dispatch_async(self.preferredCompletionQueue, ^{
                        block(res, error);
                    });
                } else {
                    block(res, error);
                }
            }
        } else {
            if (self.preferredCompletionQueue) {
                dispatch_async(self.preferredCompletionQueue, ^{
                    block(NO,[NSError jmCacheErrorWithType:JMCacheErrorTypeKeyMissing]);
                });
            } else {
                block(NO,[NSError jmCacheErrorWithType:JMCacheErrorTypeKeyMissing]);
            }
        }
    });
}

- (void)addKey:(NSString *)key
{
    dispatch_async(propertySafeQueue, ^{
        [self.allKeys addObject:key];
        [self encodeObject:self.allKeys inFilePath:[self filePathForAllKeys]];
    });
}

- (void)removeKey:(NSString *)key
{
    dispatch_async(propertySafeQueue, ^{
        [self.allKeys removeObject:key];
        [self.memoryCache removeObjectForKey:key];
        [self encodeObject:self.allKeys inFilePath:[self filePathForAllKeys]];
    });
}

- (void)clearCacheWithCompletionBlock:(JMCacheCompletionBlockBool)block;
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        dispatch_group_t group = dispatch_group_create();
        
        for(NSString *key in self.allKeys){
            dispatch_group_enter(group);
            [self removeCachedObjectForKey:key withCompletionBlock:^(BOOL boole, NSError *error) {
                NSLog(@"clear Key (%@) DONE", key);
                dispatch_group_leave(group);
            }];
        }
        
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        if (block) {
            if (self.preferredCompletionQueue) {
                dispatch_async(self.preferredCompletionQueue, ^{
                    block(YES);
                });
            } else {
                block(YES);
            }
        }
    });
}

@end
