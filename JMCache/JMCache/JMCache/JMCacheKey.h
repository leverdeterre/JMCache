//
//  JMCacheKey.h
//  JMCache
//
//  Created by jerome morissard on 31/07/14.
//  Copyright (c) 2014 jerome morissard. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JMCacheKey : NSObject

@property (strong, nonatomic) NSString *key;
@property (assign, nonatomic) Class objClass;

+ (instancetype)cacheKeyWithKey:(NSString *)key andClass:(Class)objClass;

@end
