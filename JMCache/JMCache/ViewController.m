//
//  ViewController.m
//  JMCache
//
//  Created by jerome morissard on 28/07/14.
//  Copyright (c) 2014 jerome morissard. All rights reserved.
//

#import "ViewController.h"

#import "JMCache.h"
#import "JMCacheReverseDataValueTransformer.h"

@interface ViewController ()
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [[JMCache sharedCache] setCachePathType:JMCachePathPrivate];
    [[JMCache sharedCache] setValueTransformer:[JMCacheReverseDataValueTransformer new]];
    [[JMCache sharedCache] setPreferredCompletionQueue:dispatch_get_main_queue()];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        dispatch_group_t group = dispatch_group_create();
        for(int i = 0; i < 100; i ++) {
            NSString *obj = [NSString stringWithFormat:@"%dobj",i];
            
            dispatch_group_enter(group);
            [[JMCache sharedCache] cacheObject:obj forKey:obj withCompletionBlock:^(BOOL boole) {
                dispatch_group_leave(group);
                NSLog(@"%@ addCache done",obj);
            }];
        }
        
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        NSLog(@"add all obj Cache done");
        [[JMCache sharedCache] clearCacheWithCompletionBlock:^(BOOL boole) {
            NSLog(@"DONE");
        }];
    });
}

@end
