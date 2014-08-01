//
//  JMCacheKey.m
//  JMCache
//
//  Created by jerome morissard on 31/07/14.
//  Copyright (c) 2014 jerome morissard. All rights reserved.
//

#import "JMCacheKey.h"

@implementation JMCacheKey

+ (instancetype)cacheKeyWithKey:(NSString *)key andClass:(Class)objClass
{
    JMCacheKey *ck = [JMCacheKey new];
    ck.key = key;
    ck.objClass = objClass;
    return ck;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.key forKey:@"self.key"];
    [aCoder encodeObject:NSStringFromClass(self.objClass) forKey:@"self.objClass"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        self.key = [aDecoder decodeObjectForKey:@"self.key"];
        self.objClass = NSClassFromString([aDecoder decodeObjectForKey:@"self.objClass"]);
    }
    
    return self;
}

@end
