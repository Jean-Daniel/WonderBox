/*
 *  WBStringLayer.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBBase.h)
#import WBHEADER(WBBoxLayer.h)

WB_CLASS_EXPORT
@interface WBStringLayer : WBBoxLayer {
@private
  NSTextStorage *wb_storage;

  /* convenient */
  NSLayoutManager *wb_manager;
  NSTextContainer *wb_container;

  struct {
    unsigned int clip:1;
    unsigned int reserved:7;
  } wb_slFlags;
}

- (id)initWithSize:(NSSize)aSize attributedString:(NSAttributedString *)aString;
- (id)initWithSize:(NSSize)aSize string:(NSString *)aString attributes:(NSDictionary *)attributes;

- (NSTextStorage *)storage;

- (void)setAttributedString:(NSAttributedString *)attributedString; // set string after initial creation
- (void)setString:(NSString *)aString attributes:(NSDictionary *)attribs; // set string after initial creation

- (BOOL)wraps;
- (void)setWraps:(BOOL)wrap;
#pragma mark Internal
/* protected, should not be call */
- (void)setTextStorage:(NSTextStorage *)aStorage;

- (BOOL)isMultipleThreadsEnabled;
- (void)setMultipleThreadsEnabled:(BOOL)threadSafe;

@end


