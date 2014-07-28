//
//  JMCache+ReadWrite.h
//  JMCache
//
//  Created by jerome morissard on 27/07/14.
//  Copyright (c) 2014 jerome morissard. All rights reserved.
//

#import "JMCache.h"

@interface JMCache (ReadWrite)

- (id)decodeObjectForFilePath:(NSString *)filePath;
- (void)decodeObjectForFilePath:(NSString *)filePath withCompletionBlock:(JMCacheCompletionBlockObject)block;

- (BOOL)encodeObject:(id)object inFilePath:(NSString *)filePath;
- (void)encodeObject:(id)object inFilePath:(NSString *)filePath withCompletionBlock:(JMCacheCompletionBlockBool)block;

@end
