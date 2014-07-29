//
//  JMCache+InMemory.h
//  JMCache
//
//  Created by jerome morissard on 29/07/14.
//  Copyright (c) 2014 jerome morissard. All rights reserved.
//

#import "JMCache.h"

@interface JMCache (InMemory)

- (void)cachedObjectInMemoryForKey:(NSString *)key withCompletionBlock:(JMCacheCompletionBlockObjectError)block;

@end
