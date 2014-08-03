//
//  JMCacheMemory.h
//  JMCache
//
//  Created by jerome morissard on 03/08/14.
//  Copyright (c) 2014 jerome morissard. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "JMCache.h"

@interface JMCacheMemory : NSObject

+ (instancetype)sharedCache;

- (void)cachedObjectInMemoryForKey:(NSString *)key withCompletionBlock:(JMCacheCompletionBlockObjectError)block;
- (void)removeCachedObjectInMemoryForKey:(NSString *)key withCompletionBlock:(JMCacheCompletionBlockBoolError)block;
- (void)cacheObject:(NSObject *)obj forKey:(NSString *)key withCompletionBlock:(JMCacheCompletionBlockBoolError)block;

@end
