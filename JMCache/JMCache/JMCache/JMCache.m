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

#define JM_BLOCK_SAFE_RUN(block, ...) block ? block(__VA_ARGS__) : nil

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
        [self cacheInMemoryInitialize];
        [self cacheAllKeysInitialize];
    }
    return self;
}

-(void)setValueTransformer:(JMCacheValueTransformer *)valueTransformer
{
    _valueTransformer = valueTransformer;
    [self cacheAllKeysInitialize];
}

- (void)cacheInMemoryInitialize
{
    _memoryCache = [[NSCache alloc] init];
    _memoryCache.name = @"com.jmcache.in.memory.cache";
    _memoryCache.countLimit = 100;
    _memoryCache.delegate = self;
}

- (void)cacheAllKeysInitialize
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
 
    [self loadKeysWithCompletionBlock:^(BOOL resul) {
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}

#pragma mark - Async Get Cached data

- (void)cachedObjectForKey:(NSString *)key withCompletionBlock:(JMCacheCompletionBlockObjectError)block
{
    dispatch_async(propertySafeQueue, ^{
        if(self.cacheType & JMCacheTypeInMemory){
            id obj = [self.memoryCache objectForKey:key];
            if (obj){
                JM_BLOCK_SAFE_RUN(block,obj,nil);
                return; //stop with memmoy check if found
            }
        }
        
        JMCacheKey *cacheKey = [self cacheKeyForKey:key];
        if (cacheKey) {
            NSString *path = [self filePathForKey:key];
            
            if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
                if (self.preferredCompletionQueue) {
                    dispatch_async(self.preferredCompletionQueue, ^{
                        JM_BLOCK_SAFE_RUN(block,nil,[NSError jmCacheErrorWithType:JMCacheErrorTypeFileMissing]);
                    });
                } else {
                    JM_BLOCK_SAFE_RUN(block,nil,[NSError jmCacheErrorWithType:JMCacheErrorTypeFileMissing]);
                }
                return ;
            }
            
            [self decodeObjectForFilePath:path withCompletionBlock:^(id obj) {
                [self.memoryCache setObject:obj forKey:key];
                if (self.preferredCompletionQueue) {
                    dispatch_async(self.preferredCompletionQueue, ^{
                        JM_BLOCK_SAFE_RUN(block,obj,nil);
                    });
                } else {
                    JM_BLOCK_SAFE_RUN(block,obj,nil);
                }
            }];
        } else {
            if (self.preferredCompletionQueue) {
                dispatch_async(self.preferredCompletionQueue, ^{
                    JM_BLOCK_SAFE_RUN(block,nil,[NSError jmCacheErrorWithType:JMCacheErrorTypeKeyMissing]);
                });
            } else {
                JM_BLOCK_SAFE_RUN(block,nil,[NSError jmCacheErrorWithType:JMCacheErrorTypeKeyMissing]);
            }
        }
    });
}

- (void)cacheObject:(NSObject *)obj forKey:(NSString *)key withCompletionBlock:(JMCacheCompletionBlockBoolError)block
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        //Test if encode/decode is possible
        if ([obj.class canBeCoded]==NO || [obj.class canBeDecoded]==NO) {
            if (self.preferredCompletionQueue) {
                dispatch_async(self.preferredCompletionQueue, ^{
                    JM_BLOCK_SAFE_RUN(block,NO, [NSError jmCacheErrorWithType:JMCacheErrorTypeKeyMissing]);
                });
            } else {
                JM_BLOCK_SAFE_RUN(block,NO, [NSError jmCacheErrorWithType:JMCacheErrorTypeKeyMissing]);
            }
            
            return;
        }
        
        NSString *path = [self filePathForKey:key];
        JMCacheCompletionBlockBool block2 = ^(BOOL res){
            if(res) {
                JMCacheKey *cacheKey = [JMCacheKey cacheKeyWithKey:key andClass:obj.class];
                __weak JMCache *weakSelf = self;
                [self addCacheKey:cacheKey withCompletionBlock:^(BOOL resul) {
                    __strong JMCache *strongSelf = weakSelf;
                    [strongSelf.memoryCache setObject:obj forKey:key];
                    
                    if (strongSelf.preferredCompletionQueue) {
                        dispatch_async(strongSelf.preferredCompletionQueue, ^{
                            JM_BLOCK_SAFE_RUN(block,res, nil);
                        });
                    } else {
                        JM_BLOCK_SAFE_RUN(block,res, nil);
                    }
                }];
            }
        };
        
        [self encodeObject:obj inFilePath:path withCompletionBlock:block2];
    });
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
                [self removeCacheKey:cacheKey withCompletionBlock:^(BOOL resul) {
                    __strong JMCache *strongSelf = weakSelf;
                    [strongSelf.memoryCache removeObjectForKey:cacheKey.key];
                    JM_BLOCK_SAFE_RUN(block,res, error);
                }];
            }
        } else {
            JM_BLOCK_SAFE_RUN(block,NO, [NSError jmCacheErrorWithType:JMCacheErrorTypeKeyMissing]);
        }
    });
}

- (void)clearCacheWithCompletionBlock:(JMCacheCompletionBlockBool)block;
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        dispatch_group_t group = dispatch_group_create();
        
        for(NSString *key in [self.allKeys valueForKey:@"key"]){
            dispatch_group_enter(group);
            [self removeCachedObjectForKey:key withCompletionBlock:^(BOOL resul, NSError *error) {
                dispatch_group_leave(group);
            }];
        }
        
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        if (self.preferredCompletionQueue) {
            dispatch_async(self.preferredCompletionQueue, ^{
                JM_BLOCK_SAFE_RUN(block,YES);
            });
        } else {
            JM_BLOCK_SAFE_RUN(block,YES);
        }
    });
}

#pragma mark - Sync Get Cached data

- (id)cachedObjectForKey:(NSString *)key
{
    if (!key)
        return nil;
    
    __block id objectForKey = nil;
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self cachedObjectForKey:key withCompletionBlock:^(id obj, NSError *error) {
        objectForKey = obj;
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return objectForKey;
}

- (BOOL)cacheObject:(NSObject *)obj forKey:(NSString *)key
{
    if (!key)
        return NO;
    
    __block BOOL bresult = NO;

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [self cacheObject:obj forKey:key withCompletionBlock:^(BOOL resul, NSError *error) {
        bresult = resul;
        dispatch_semaphore_signal(semaphore);
    }];
 
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return bresult;
}

- (NSInteger)numberOfObjectInJMCache
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSInteger nb = 0;
    [self allKeysWithCompletionBlock:^(id obj) {
        nb = [obj count];
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return nb;
}

#pragma mark - Private methods

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

- (void)loadKeys
{
    @try {
        NSString *path = [self filePathForAllKeys];
        _allKeys = [[self decodeObjectForFilePath:path] mutableCopy];
        if (nil == _allKeys) {
            _allKeys = [NSMutableArray new];
        }
    }
    @catch (NSException *exception) {
        //Probably decode impossible because of valueTransformer
    }
    @finally {
        
    }

}

- (void)loadKeysWithCompletionBlock:(JMCacheCompletionBlockBool)block
{
    dispatch_async(propertySafeQueue, ^{
        [self loadKeys];
        block(YES);
    });
}

- (void)allKeysWithCompletionBlock:(JMCacheCompletionBlockObject)block
{
    dispatch_async(propertySafeQueue, ^{
        block([self.allKeys copy]);
    });
}

- (NSString *)description
{
    NSMutableString *desc = [NSMutableString new];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    __block NSArray *allCacheKeys;
    [self allKeysWithCompletionBlock:^(id obj) {
        allCacheKeys = obj;
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    for (JMCacheKey *cacheKey in allCacheKeys) {
        [desc appendFormat:@"%@ (class : %@)\n", cacheKey.key,NSStringFromClass(cacheKey.objClass)];
    }
    
    return desc;
}


@end
