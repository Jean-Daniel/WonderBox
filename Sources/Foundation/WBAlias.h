/*
 *  WBAlias.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#include <WonderBox/WBBase.h>

#import <Foundation/Foundation.h>

WB_OBJC_EXPORT
@interface WBAlias : NSObject <NSCoding, NSCopying>

+ (instancetype)aliasWithURL:(NSURL *)anURL;
+ (instancetype)aliasFromBookmarkData:(NSData *)data;

- (instancetype)initWithURL:(NSURL *)anURL;
- (instancetype)initFromBookmarkData:(NSData *)data;

/*!
    @abstract   Return the Alias path and resolve it if needed.
*/
@property(nonatomic, readonly) NSURL *URL;

@property(nonatomic, readonly) NSData *data;

@end

@interface WBAlias (WBAliasHandle)

+ (instancetype)aliasWithPath:(NSString *)aPath WB_DEPRECATED("aliasWithURL:");
+ (instancetype)aliasFromData:(NSData *)data WB_DEPRECATED("aliasFromBookmarkData:");

- (instancetype)initWithPath:(NSString *)aPath WB_DEPRECATED("initWithURL:");
- (instancetype)initFromData:(NSData *)data WB_DEPRECATED("initFromBookmarkData:");

// does not accept null path
@property(nonatomic, readonly) NSString *path WB_DEPRECATED("URL");

@end
