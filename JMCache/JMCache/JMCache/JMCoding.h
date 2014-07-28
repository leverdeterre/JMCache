//
//  JMCoding.h
//  JMCache
//
//  Created by jerome morissard on 28/07/14.
//  Copyright (c) 2014 jerome morissard. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol JMCoding <NSObject>

+ (id)objectFromData:(NSData *)data;
- (NSData *)dataFromObject:(id)object;

@end
