//
//  JMCache+filePath.m
//  JMCache
//
//  Created by jerome morissard on 27/07/14.
//  Copyright (c) 2014 jerome morissard. All rights reserved.
//

#import "JMCache+filePath.h"

NSString * const JMDiskCachedKeys = @"com.jmcache.allKeys";

@implementation JMCache (filePath)

- (NSString *)filePathForKey:(NSString *)key
{
    NSString *fullPath = [NSString stringWithFormat:@"%@/%@",[self rootDirectoryForCache],key];
    return fullPath;
}

- (NSString *)filePathForAllKeys
{
    NSString *fullPath = [NSString stringWithFormat:@"%@/%@",[self rootDirectoryForCache],JMDiskCachedKeys];
    return fullPath;
}

#pragma mark - Private

- (NSString *)rootDirectoryForCache
{
    if (self.cachePathType == JMCachePathPublic) {
        return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        
    } else if (self.cachePathType == JMCachePathPrivate) {
        return [self privateDataPath];
        
    } else if (self.cachePathType == JMCachePathOffline) {
        return [self offlineDataPath];
    }
    
    return nil;
}

- (NSString *)privateDataPath
{
    //application support folder
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
    
    //create the folder if it doesn't exist
    if (![[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:path
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:NULL];
    }
    
    return path;
}

- (NSString *)offlineDataPath
{
    //offline data folder path
    NSString *path = [[self privateDataPath] stringByAppendingPathComponent:@"Offline Data"];
    
    //create the folder if it doesn't exist
    if (![[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:path
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:NULL];
    }
    
    NSURL *URL = [NSURL fileURLWithPath:path isDirectory:YES];
    [URL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:NULL];
    
    return path;
}

@end
