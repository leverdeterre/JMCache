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
#import "JMCacheActionTableViewCell.h"
#import "UIAlertView+JMCache.h"

#include <sys/time.h>

long getMillis()
{
    struct timeval time;
    gettimeofday(&time, NULL);
    long millis = (time.tv_sec * 1000) + (time.tv_usec / 1000);
    return millis;
}

@interface ViewController ()
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.title = @"JMCache status";
    
    [[JMCache sharedCache] setCachePathType:JMCachePathPrivate];
    [[JMCache sharedCache] setValueTransformer:[JMCacheReverseDataValueTransformer new]];
    [[JMCache sharedCache] setCacheType:JMCacheTypeInMemory];
    //[[JMCache sharedCache] setPreferredCompletionQueue:dispatch_get_main_queue()];
        
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (JMCacheActionTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JMCacheActionTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"JMCacheActionTableViewCell"];
    [self configureCell:cell forRowAtIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(JMCacheActionTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self cleanButtonsTargets:cell.actionButton];

    switch (indexPath.row) {
        case 0:{
            cell.titleLabel.text = [NSString stringWithFormat:@"%ld elements in cache", (long)[[JMCache sharedCache] numberOfObjectInJMCache]];
            [cell.actionButton addTarget:self action:@selector(addOneElementInCache) forControlEvents:UIControlEventTouchUpInside];
            [cell.actionButton setTitle:@"add one" forState:UIControlStateNormal];
            break;
        }
            
        case 1:{
            cell.titleLabel.text = [NSString stringWithFormat:@"add 100 objects in cache"];
            [cell.actionButton addTarget:self action:@selector(addCentElementsInCache) forControlEvents:UIControlEventTouchUpInside];
            [cell.actionButton setTitle:@"do it" forState:UIControlStateNormal];
            break;
        }
            
        case 2:{
            cell.titleLabel.text = [NSString stringWithFormat:@"clear cache"];
            [cell.actionButton addTarget:self action:@selector(clearAllCache) forControlEvents:UIControlEventTouchUpInside];
            [cell.actionButton setTitle:@"do it" forState:UIControlStateNormal];
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - Actions

- (void)addOneElementInCache
{
    NSDate *date = [NSDate date];
    long timeStart = getMillis();
    NSString *key = [NSString stringWithFormat:@"%f", [date timeIntervalSinceNow]];
    
    [[JMCache sharedCache] cacheObject:date forKey:key withCompletionBlock:^(BOOL resul, NSError *error) {
       dispatch_async(dispatch_get_main_queue(), ^{
           long timeEnd = getMillis();
           [UIAlertView showAlertMessage:[NSString stringWithFormat:@"Fait en %ld ms",timeEnd-timeStart]];
           [self.tableView reloadData];
       });
    }];
}

- (void)addCentElementsInCache
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSDate *date = [NSDate date];
        long timeStart = getMillis();
        
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        for (int i = 0; i < 100 ; i++) {
            NSString *key = [NSString stringWithFormat:@"%f_%d", [date timeIntervalSinceNow],i];
            
            [[JMCache sharedCache] cacheObject:date forKey:key withCompletionBlock:^(BOOL resul, NSError *error) {
                dispatch_semaphore_signal(semaphore);
            }];
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            long timeEnd = getMillis();
            [UIAlertView showAlertMessage:[NSString stringWithFormat:@"Fait en %ld ms",timeEnd-timeStart]];
            [self.tableView reloadData];
        });
    });
}

- (void)clearAllCache
{
    long timeStart = getMillis();
    
    [[JMCache sharedCache] clearCacheWithCompletionBlock:^(BOOL resul) {
        dispatch_async(dispatch_get_main_queue(), ^{
            long timeEnd = getMillis();
            [UIAlertView showAlertMessage:[NSString stringWithFormat:@"Fait en %ld ms",timeEnd-timeStart]];
            [self.tableView reloadData];
        });
    }];
}

- (void)cleanButtonsTargets:(UIButton *)button
{
    [button removeTarget:nil
                       action:NULL
             forControlEvents:UIControlEventAllEvents];
}

@end
