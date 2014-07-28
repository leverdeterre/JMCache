//
//  JMCacheReverseDataValueTransformer.m
//  JMCache
//
//  Created by jerome morissard on 27/07/14.
//  Copyright (c) 2014 jerome morissard. All rights reserved.
//

#import "JMCacheReverseDataValueTransformer.h"

@implementation JMCacheReverseDataValueTransformer

+ (Class)transformedValueClass
{
    return [NSData class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (id)transformedValue:(id)value
{
    const char *bytes = [value bytes];
    int idx = [value length] - 1;
    char *reversedBytes = calloc(sizeof(char),[value length]);
    for (int i = 0; i < [value length]; i++) {
        reversedBytes[idx--] = bytes[i];
    }
    NSData *reversedData = [NSData dataWithBytes:reversedBytes length:[value length]];
    free(reversedBytes);
    return reversedData;
}

- (id)reverseTransformedValue:(id)value
{
    return [self transformedValue:value];
}

@end
