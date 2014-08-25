//
//  JMCoding.h
//  JMCache
//
//  Created by jerome morissard on 28/07/14.
//  Copyright (c) 2014 jerome morissard. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  JMCoding encode / decode protocol
 */
@protocol JMCoding <NSObject>

+ (id)objectWithData:(NSData *)data;
+ (NSData *)dataWithRootObject:(id)object;

@end
