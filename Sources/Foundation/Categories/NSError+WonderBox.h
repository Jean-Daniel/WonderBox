/*
 *  NSError+WonderBox.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

@interface NSError (WBExtensions)

+ (NSError *)cancel;

+ (id)fileErrorWithCode:(NSInteger)code path:(NSString *)aPath;
+ (id)fileErrorWithCode:(NSInteger)code path:(NSString *)aPath reason:(NSString *)message;

+ (id)fileErrorWithCode:(NSInteger)code url:(NSURL *)anURL;
+ (id)fileErrorWithCode:(NSInteger)code url:(NSURL *)anURL reason:(NSString *)message;

+ (id)errorWithDomain:(NSString *)aDomain code:(NSInteger)code reason:(NSString *)message, ...;

- (BOOL)isCancel;

@end
