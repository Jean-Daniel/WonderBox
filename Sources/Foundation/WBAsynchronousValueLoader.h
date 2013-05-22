/*
 *  WBAsynchronousValueLoader.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2013 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBAsynchronousKeyValueLoading.h>

WB_OBJC_EXPORT
@interface WBAsynchronousValueLoader : NSObject

- (id)initWithOwner:(id)owner;

- (WBKeyValueStatus)statusOfValueForKey:(NSString *)key error:(NSError **)outError;
- (void)loadValuesAsynchronouslyForKeys:(NSArray *)keys completionHandler:(void (^)(void))handler;

- (void)invalidateProperty:(NSString *)key;
- (void)invalidateAllProperties;

- (void)cancelLoading;

- (id)propertyforKey:(NSString *)name;
// loading callback
- (void)setProperty:(id)value forKey:(NSString *)name;
- (void)setPropertyError:(NSError *)value forKey:(NSString *)name;

@end
