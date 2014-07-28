//
//  JMCache+ReadWrite.m
//  JMCache
//
//  Created by jerome morissard on 27/07/14.
//  Copyright (c) 2014 jerome morissard. All rights reserved.
//

#import "JMCache+ReadWrite.h"

@implementation JMCache (ReadWrite)

- (id)decodeObjectForFilePath:(NSString *)filePath
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSData *content = [[NSFileManager defaultManager] contentsAtPath:filePath];
        if (self.valueTransformer) {
            content = [self.valueTransformer reverseTransformedValue:content];
        }
        
        return [NSKeyedUnarchiver unarchiveObjectWithData:content];
    }
    
    return nil;
}

- (void)decodeObjectForFilePath:(NSString *)filePath withCompletionBlock:(JMCacheCompletionBlockObject)block
{
    dispatch_async(readingQueue, ^{
        if (block) {
            NSData *content = [[NSFileManager defaultManager] contentsAtPath:filePath];
            if (self.valueTransformer) {
                content = [self.valueTransformer reverseTransformedValue:content];
            }
            
            block([NSKeyedUnarchiver unarchiveObjectWithData:content]);
        }
    });
}

- (BOOL)encodeObject:(id)object inFilePath:(NSString *)filePath
{
    NSData *content = [NSKeyedArchiver archivedDataWithRootObject:object];
    if (self.valueTransformer) {
        content = [self.valueTransformer transformedValue:content];
    }
    
    return [content writeToFile:filePath atomically:YES];
}

- (void)encodeObject:(id)object inFilePath:(NSString *)filePath withCompletionBlock:(JMCacheCompletionBlockBool)block
{
    dispatch_async(writingQueue, ^{
        NSData *content = [NSKeyedArchiver archivedDataWithRootObject:object];
        if (self.valueTransformer) {
            content = [self.valueTransformer transformedValue:content];
        }
        
        if (block) {
            block([content writeToFile:filePath atomically:YES]);
        } else {
            [content writeToFile:filePath atomically:YES];
        }
    });
}

@end
