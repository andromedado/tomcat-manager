//
//  functions.h
//  1stdibs
//
//  Created by Shad Downey on 7/23/14.
//  Copyright (c) 2014 1stdibs. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Always returns an array. An empty array will be returned if the argument is:
 1. not an NSArray
 2. nil
 3. an empty NSArray
 
 The returned array may be the same array that was passed in.
 */
NSArray* _Nonnull guaranteedArray(id _Nullable array);
NSString* _Nonnull guaranteedString(id _Nullable str);
NSString* _Nonnull guaranteedIndexStr(NSString * _Nullable str);

NSSet* _Nonnull determineCurrencies (id _Nonnull obj);

void onMain(dispatch_block_t _Nonnull block);
void onMainSync(dispatch_block_t _Nonnull block);
void onMainAsync(dispatch_block_t _Nonnull block);
void inBackground(dispatch_block_t _Nonnull block);
void onMainAfter(CGFloat delaySeconds, dispatch_block_t _Nonnull block);
void inBackgroundAfter(CGFloat delaySeconds, dispatch_block_t _Nonnull block);

