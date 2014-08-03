//
//  NSError+JMCache.m
//  JMCache
//
//  Created by jerome morissard on 27/07/14.
//  Copyright (c) 2014 jerome morissard. All rights reserved.
//

#import "NSError+JMCache.h"

NSString * NSStringFromCacheErrorType(JMCacheErrorType type) {
    switch (type) {
        case JMCacheErrorTypeKeyNotFoundInCache:
            return @"JMCacheErrorTypeKeyNotFoundInCache";
            break;
          
        case JMCacheErrorTypeFileMissing:
            return @"JMCacheErrorTypeFileMissing";
            break;
            
        case JMCacheErrorTypeEncodeDecodeProtocolMissing:
            return @"JMCacheErrorTypeEncodeDecodeProtocolMissing";
            break;
            
        case JMCacheErrorTypeNoObjectFoundOnMemoryAndDiskDisable:
            return @"JMCacheErrorTypeNoObjectFoundOnMemoryAndDiskDisable";
            break;
            
        default:
            return @"default...";
            break;
    }
}

@implementation NSError (JMCache)

+ (NSError *)jmCacheErrorWithType:(JMCacheErrorType)errorType
{
    return [NSError errorWithDomain:@"com.jmcache.error"
                               code:errorType
                           userInfo:@{NSLocalizedDescriptionKey:NSStringFromCacheErrorType(errorType)}];
}

@end
