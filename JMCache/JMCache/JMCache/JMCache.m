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
#import "NSObject+JMCache.h"

#import "JMCacheMemory.h"

void dispatch_optional_queue_async(dispatch_queue_t optionalQueue, dispatch_block_t block)
{
    if (optionalQueue) {
        dispatch_async(optionalQueue, block);
    } else {
        block();
    }
}

@interface JMCache() <NSCacheDelegate>
@property (strong, nonatomic) NSMutableArray *allKeys;
@property (strong, nonatomic) JMCacheMemory *cacheInMemory;
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
        _cacheType = JMCacheTypeInMemoryThenOnDisk;
        [self cacheAllKeysInitialize];
    }
    return self;
}

-(void)setValueTransformer:(JMCacheValueTransformer *)valueTransformer
{
    _valueTransformer = valueTransformer;
    [self cacheAllKeysInitialize];
}

- (JMCacheMemory *)cacheInMemory
{
    if (_cacheInMemory == nil) {
        _cacheInMemory = [JMCacheMemory sharedCache];
    }
    return _cacheInMemory;
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
            [self.cacheInMemory cachedObjectInMemoryForKey:key withCompletionBlock:^(id obj, NSError *error) {
                if (obj){
                    dispatch_optional_queue_async(self.preferredCompletionQueue,^{
                        JM_BLOCK_SAFE_RUN(block,obj,nil);
                    });
                    return;
                }
            }];
        } else {
            if(self.cacheType & JMCacheTypeOnDisk){
                [self cachedObjectOnDiskForKey:key withCompletionBlock:block];
            } else {
                dispatch_optional_queue_async(self.preferredCompletionQueue,^{
                    JM_BLOCK_SAFE_RUN(block,nil,[NSError jmCacheErrorWithType:JMCacheErrorTypeNoObjectFoundOnMemoryAndDiskDisable]);
                });
            }
        }
    });
}

- (void)cacheObject:(NSObject *)obj forKey:(NSString *)key withCompletionBlock:(JMCacheCompletionBlockBoolError)block
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        //Test if encode/decode is possible
        if ([obj.class canBeCoded]==NO || [obj.class canBeDecoded]==NO) {
            dispatch_optional_queue_async(self.preferredCompletionQueue,^{
                JM_BLOCK_SAFE_RUN(block,NO, [NSError jmCacheErrorWithType:JMCacheErrorTypeEncodeDecodeProtocolMissing]);
            });
            return;
        }
        
        NSString *path = [self filePathForKey:key];
        JMCacheCompletionBlockBool block2 = ^(BOOL res){
            if(res) {
                JMCacheKey *cacheKey = [JMCacheKey cacheKeyWithKey:key andClass:obj.class];
                __weak JMCache *weakSelf = self;
                [self addCacheKey:cacheKey withCompletionBlock:^(BOOL resul) {
                    __strong JMCache *strongSelf = weakSelf;
                    if (strongSelf.cachePathType & JMCacheTypeInMemory) {
                        [strongSelf.cacheInMemory cacheObject:obj forKey:key withCompletionBlock:^(BOOL resul, NSError *error) {
                            dispatch_optional_queue_async(strongSelf.preferredCompletionQueue,^{
                                JM_BLOCK_SAFE_RUN(block,res, nil);
                            });
                        }];
                    } else {
                        dispatch_optional_queue_async(strongSelf.preferredCompletionQueue,^{
                            JM_BLOCK_SAFE_RUN(block,res, nil);
                        });
                    }
                }];
            }
        };
        
        if (self.cacheType & JMCacheTypeOnDisk) {
            [self encodeObject:obj inFilePath:path withCompletionBlock:block2];
        } else {
            block2(YES);
        }
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
            [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
            
            __weak JMCache *weakSelf = self;
            [self removeCacheKey:cacheKey withCompletionBlock:^(BOOL resul) {
                __strong JMCache *strongSelf = weakSelf;
                [strongSelf.cacheInMemory removeCachedObjectInMemoryForKey:key withCompletionBlock:^(BOOL resul, NSError *error) {
                    dispatch_optional_queue_async(strongSelf.preferredCompletionQueue,^{
                        JM_BLOCK_SAFE_RUN(block,YES, error);
                    });
                }];
            }];
        } else {
            dispatch_optional_queue_async(self.preferredCompletionQueue,^{
                JM_BLOCK_SAFE_RUN(block,NO, [NSError jmCacheErrorWithType:JMCacheErrorTypeKeyNotFoundInCache]);
            });
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
        dispatch_optional_queue_async(self.preferredCompletionQueue,^{
            JM_BLOCK_SAFE_RUN(block,YES);
        });
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

        if (self.cachePathType & JMCacheTypeInMemory) {
            [self.cacheInMemory cacheObject:obj forKey:key withCompletionBlock:^(BOOL resul, NSError *error) {
                dispatch_semaphore_signal(semaphore);
            }];
        } else {
            dispatch_semaphore_signal(semaphore);
        }
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
        
        if (self.cachePathType & JMCacheTypeInMemory) {
            [self.cacheInMemory removeCachedObjectInMemoryForKey:key withCompletionBlock:^(BOOL resul, NSError *error) {
                dispatch_semaphore_signal(semaphore);
            }];
        } else {
            dispatch_semaphore_signal(semaphore);
        }
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

#pragma mark - Private methods disk cache

- (void)cachedObjectOnDiskForKey:(NSString *)key withCompletionBlock:(JMCacheCompletionBlockObjectError)block
{
    dispatch_async(propertySafeQueue, ^{
        JMCacheKey *cacheKey = [self cacheKeyForKey:key];
        if (cacheKey) {
            NSString *path = [self filePathForKey:key];
            
            if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
                dispatch_optional_queue_async(self.preferredCompletionQueue,^{
                    JM_BLOCK_SAFE_RUN(block,nil,[NSError jmCacheErrorWithType:JMCacheErrorTypeFileMissing]);
                });
                return ;
            }
            
            [self decodeObjectForFilePath:path withCompletionBlock:^(id obj) {
                if (self.cachePathType & JMCacheTypeInMemory) {
                    [self.cacheInMemory cacheObject:obj forKey:key withCompletionBlock:^(BOOL resul, NSError *error) {
                        dispatch_optional_queue_async(self.preferredCompletionQueue,^{
                            JM_BLOCK_SAFE_RUN(block,obj,nil);
                        });
                    }];
                } else {
                    dispatch_optional_queue_async(self.preferredCompletionQueue,^{
                        JM_BLOCK_SAFE_RUN(block,obj,nil);
                    });
                }
            }];
        } else {
            dispatch_optional_queue_async(self.preferredCompletionQueue,^{
                JM_BLOCK_SAFE_RUN(block,nil,[NSError jmCacheErrorWithType:JMCacheErrorTypeKeyNotFoundInCache]);
            });
        }
    });
}

#pragma mark - Private methods Cache keys

- (void)addCacheKey:(JMCacheKey *)cacheKey withCompletionBlock:(JMCacheCompletionBlockBool)block
{
    dispatch_async(propertySafeQueue, ^{
        [self.allKeys addObject:cacheKey];
        if (self.cacheType & JMCacheTypeOnDisk) {
            [self encodeObject:self.allKeys inFilePath:[self filePathForAllKeys] useTransformer:NO withCompletionBlock:block];
        } else {
            block(YES);
        }
    });
}

- (void)removeCacheKey:(JMCacheKey *)cacheKey withCompletionBlock:(JMCacheCompletionBlockBool)block
{
    dispatch_async(propertySafeQueue, ^{
        [self.allKeys removeObject:cacheKey];
        if (self.cacheType & JMCacheTypeOnDisk) {
            [self encodeObject:self.allKeys inFilePath:[self filePathForAllKeys] useTransformer:NO withCompletionBlock:block];
        } else {
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

- (void)loadKeys
{
    @try {
        NSString *path = [self filePathForAllKeys];
        _allKeys = [[self decodeObjectForFilePath:path useTransformer:NO] mutableCopy];
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
