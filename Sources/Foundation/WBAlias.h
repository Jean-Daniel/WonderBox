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

WB_OBJC_EXPORT
@interface WBAlias : NSObject <NSCoding, NSCopying> {
  @private
  NSString *wb_path;
  AliasHandle wb_alias;
}

+ (id)aliasWithURL:(NSURL *)anURL;
+ (id)aliasWithPath:(NSString *)aPath;

- (id)initWithURL:(NSURL *)anURL;
- (id)initWithPath:(NSString *)aPath;

+ (id)aliasFromData:(NSData *)data;
+ (id)aliasFromAliasHandle:(AliasHandle)handle;

- (id)initFromData:(NSData *)data;
- (id)initFromAliasHandle:(AliasHandle)handle;

/*!
    @method     path
    @abstract   Return the Alias path and resolve it if needed.
*/
- (NSString *)path;
// does not accept null path
- (void)setPath:(NSString *)path;

- (NSURL *)URL;
// does not accept null path
- (void)setURL:(NSURL *)anURL;

// returns true if the alias has been updated.
- (BOOL)update;
- (NSData *)data;

/*!
    @method     aliasHandle
    @abstract   Returns the Carbon AliasHandle associated with the receiver.
    @result     The native Alias Handle
*/
- (AliasHandle)aliasHandle;
- (OSStatus)getTarget:(FSRef *)target wasChanged:(BOOL *)outChanged;
// TODO:
//- (OSStatus)setTarget:(FSRef *)target wasChanged:(BOOL *)outChanged;

@end
