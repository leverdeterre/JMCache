//
//  JMCache+filePath.h
//  JMCache
//
//  Created by jerome morissard on 27/07/14.
//  Copyright (c) 2014 jerome morissard. All rights reserved.
//

#import "JMCache.h"

@interface JMCache (filePath)

- (NSString *)filePathForKey:(NSString *)key;
- (NSString *)filePathForAllKeys;

@end
