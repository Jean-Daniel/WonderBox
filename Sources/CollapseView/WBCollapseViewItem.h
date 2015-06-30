/*
 *  WBCollapseViewItem.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#include <WonderBox/WBBase.h>

#import <Cocoa/Cocoa.h>

@class WBCollapseView;
WB_OBJC_EXPORT
@interface WBCollapseViewItem : NSObject <NSCoding> {
@private
  id wb_uid;
  NSView *wb_view; // view to be displayed
  NSString *wb_title;
  __unsafe_unretained WBCollapseView *wb_owner; // back pointer to the parent view. Could be nil.
  struct _wb_cviFlags {
    uint8_t animates:1;
    uint8_t expanded:1;
    uint8_t reserved:6;
  } wb_cviFlags;
}

@property(nonatomic, retain) NSView *view;
@property(nonatomic, retain) id identifier;

@property(nonatomic, copy) NSString *title;

@property(nonatomic) BOOL animates;

- (id)init;
- (id)initWithView:(NSView *)aView;
- (id)initWithView:(NSView *)aView identifier:(id)anIdentifier;

- (WBCollapseView *)collapseView;

- (BOOL)isExpanded;
- (void)setExpanded:(BOOL)expanded; // animate:self.animates;
- (void)setExpanded:(BOOL)expanded animate:(BOOL)flag;

// Do not call directly
- (void)setCollapseView:(WBCollapseView *)aView;

@end
