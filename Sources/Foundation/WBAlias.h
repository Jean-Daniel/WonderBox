/*
 *  WBAlias.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */
/*!
    @header WBAlias
    @abstract   (description)
    @discussion (description)
*/

/*!
    @class WBAlias
    @abstract WBAlias class is a wrapper on Carbon AliasHandle.
*/
WB_CLASS_EXPORT
@interface WBAlias : NSObject <NSCoding, NSCopying> {
  @private
  NSString *wb_path;
  AliasHandle wb_alias;
}

- (id)initWithPath:(NSString *)path;
- (id)initWithData:(NSData *)data;
- (id)initWithAliasHandle:(AliasHandle)handle;

+ (id)aliasWithPath:(NSString *)path;
+ (id)aliasWithData:(NSData *)data;
+ (id)aliasWithAliasHandle:(AliasHandle)handle;

/*!
    @method     path
    @abstract   Return the Alias path and resolve it if needed.
*/
- (NSString *)path;
- (void)setPath:(NSString *)path;

- (NSData *)data;

- (NSString *)resolve;

/*!
    @method     aliasHandle
    @abstract   Returns the Carbon AliasHandle associated with the receiver.
    @result     The native Alias Handle
*/
- (AliasHandle)aliasHandle;

@end
