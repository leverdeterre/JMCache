//
//  JMCacheQueueTests.m
//  JMCache
//
//  Created by jerome morissard on 02/08/14.
//  Copyright (c) 2014 jerome morissard. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "JMcache.h"

@interface JMCacheQueueTests : XCTestCase

@end

@implementation JMCacheQueueTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample
{
    __block BOOL isMainThread = NO;
    
    for(int i = 0; i < 100; i ++) {
        NSString *obj = [NSString stringWithFormat:@"%dobj",i];
        [[JMCache sharedCache] cacheObject:obj forKey:obj];
        NSLog(@"cacheObject %@ done", obj);
    }
    
    NSLog(@"add all obj Cache done");
    NSLog(@"%@",[JMCache sharedCache]);
}

@end
