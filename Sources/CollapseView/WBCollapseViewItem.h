/*
 *  WBCollapseViewItem.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

@class WBCollapseView;
@interface WBCollapseViewItem : NSObject <NSCoding> {
@private
  id wb_uid;
  NSView *wb_view; // view to be displayed
  NSString *wb_title;
  WBCollapseView *wb_owner __weak; // back pointer to the parent view. Could be nil.
  struct _wb_cviFlags {
    unsigned int animates:1;
    unsigned int expanded:1;
    unsigned int reserved:6;
  } wb_cviFlags;
}

@property(retain) NSView *view;
@property(retain) id identifier;

@property(copy) NSString *title;

@property BOOL animates;

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
