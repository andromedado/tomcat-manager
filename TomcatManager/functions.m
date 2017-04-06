//
//  functions.m
//  1stdibs
//
//  Created by Shad Downey on 7/23/14.
//  Copyright (c) 2014 1stdibs. All rights reserved.
//

#import "functions.h"

#pragma mark - Execution Context

void onMain(dispatch_block_t block)
{
    if ([NSThread isMainThread])
    {
        block();
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

void onMainSync(dispatch_block_t block)
{
    if ([NSThread isMainThread])
    {
        block();
    }
    else
    {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

void onMainAsync(dispatch_block_t block)
{
    dispatch_async(dispatch_get_main_queue(), block);
}

void inBackground(dispatch_block_t block)
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}

void onMainAfter(CGFloat delaySeconds, dispatch_block_t block)
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        block();
    });
}

void inBackgroundAfter(CGFloat delaySeconds, dispatch_block_t block)
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySeconds * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        block();
    });
}

