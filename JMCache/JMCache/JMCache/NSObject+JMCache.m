//
//  NSObject+JMCache.m
//  JMCache
//
//  Created by jerome morissard on 30/07/14.
//  Copyright (c) 2014 jerome morissard. All rights reserved.
//

#import "NSObject+JMCache.h"
#import "JMCoding.h"

@implementation NSObject (JMCache)

+ (BOOL)canBeCoded
{
    if ([self conformsToProtocol:@protocol(NSCoding)]) {
        return YES;
    }
    
    //support nicklockwood/FastCoding
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([self instancesRespondToSelector:@selector(dataWithRootObject:)]) {
#pragma clang diagnostic pop

        return YES;
    }
    
    return NO;
}

+ (BOOL)canBeDecoded
{
    if ([self conformsToProtocol:@protocol(NSCoding)]) {
        return YES;
    }
    
    //support nicklockwood/FastCoding for exemple 
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([self instancesRespondToSelector:@selector(objectWithData:)]) {
#pragma clang diagnostic pop

        return YES;
    }
    
    return NO;
}

#pragma  mark - Encode / decode

+ (NSData *)jmo_dataWithRootObject:(id)object
{
    if ([object conformsToProtocol:@protocol(NSCoding)]) {
        return [NSKeyedArchiver archivedDataWithRootObject:object];
    }

    if ([object conformsToProtocol:@protocol(JMCoding)]) {
        return [self.class dataWithRootObject:object];
    }
    
    return nil;
}

+ (id)jmo_objectWithData:(NSData *)data
{
    if ([self.class conformsToProtocol:@protocol(NSCoding)]) {
        return [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    
    if ([self.class conformsToProtocol:@protocol(JMCoding)]) {
        return [self.class objectWithData:data];
    }

    return nil;
}

@end
