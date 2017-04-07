//
//  functions.h
//  1stdibs
//
//  Created by Shad Downey on 7/23/14.
//  Copyright (c) 2014 1stdibs. All rights reserved.
//

#import <Foundation/Foundation.h>


void onMain(dispatch_block_t _Nonnull block);
void onMainSync(dispatch_block_t _Nonnull block);
void onMainAsync(dispatch_block_t _Nonnull block);
void inBackground(dispatch_block_t _Nonnull block);
void onMainAfter(CGFloat delaySeconds, dispatch_block_t _Nonnull block);
void inBackgroundAfter(CGFloat delaySeconds, dispatch_block_t _Nonnull block);

extern const NSString* _Nonnull foo;
