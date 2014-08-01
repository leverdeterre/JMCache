//
//  NSError+JMCache.h
//  JMCache
//
//  Created by jerome morissard on 27/07/14.
//  Copyright (c) 2014 jerome morissard. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, JMCacheErrorType) {
    JMCacheErrorTypeKeyMissing,
    JMCacheErrorTypeFileMissing,
    JMCacheErrorTypeEncodeDecodeProtocolMissing
};

@interface NSError (JMCache)

+ (NSError *)jmCacheErrorWithType:(JMCacheErrorType)errorType;

@end
