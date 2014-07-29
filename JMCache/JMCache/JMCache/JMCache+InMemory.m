//
//  JMCache+InMemory.m
//  JMCache
//
//  Created by jerome morissard on 29/07/14.
//  Copyright (c) 2014 jerome morissard. All rights reserved.
//

#import "JMCache+InMemory.h"

@implementation JMCache (InMemory)

- (void)cachedObjectInMemoryForKey:(NSString *)key withCompletionBlock:(JMCacheCompletionBlockObjectError)block
{
    
}

#pragma mark - NSCacheDelegate

- (void)cache:(NSCache *)cache willEvictObject:(id)obj
{
    
}

@end
