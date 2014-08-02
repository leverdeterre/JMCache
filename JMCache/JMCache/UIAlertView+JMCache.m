//
//  UIAlertView+JMCache.m
//  JMCache
//
//  Created by jerome morissard on 02/08/14.
//  Copyright (c) 2014 jerome morissard. All rights reserved.
//

#import "UIAlertView+JMCache.h"

@implementation UIAlertView (JMCache)

+ (void)showAlertMessage:(NSString *)message
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
    });
}

@end
