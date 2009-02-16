/*
 *  WBExtensions.h
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

@interface NSError (WBExtensions)

+ (NSError *)cancel;

+ (id)fileErrorWithCode:(NSInteger)code path:(NSString *)aPath;
+ (id)fileErrorWithCode:(NSInteger)code path:(NSString *)aPath description:(NSString *)message;

+ (id)fileErrorWithCode:(NSInteger)code url:(NSURL *)anURL;
+ (id)fileErrorWithCode:(NSInteger)code url:(NSURL *)anURL description:(NSString *)message;

- (BOOL)isCancel;

@end
