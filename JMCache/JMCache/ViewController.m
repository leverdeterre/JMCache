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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
