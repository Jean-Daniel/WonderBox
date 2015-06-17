/*
 *  WBAliasedApplication.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBApplication.h>

@class WBAlias;
WB_OBJC_EXPORT
@interface WBAliasedApplication : WBApplication <NSCoding, NSCopying> {
@private
  WBAlias *wb_alias;
}

- (id)initWithAlias:(WBAlias *)anAlias;

- (WBAlias *)alias;
- (void)setAlias:(WBAlias *)anAlias;

- (NSString *)path;
- (BOOL)setPath:(NSString *)aPath;

@end
