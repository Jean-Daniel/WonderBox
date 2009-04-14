/*
 *  WBCollapseViewInternal.h
 *  Emerald
 *
 *  Created by Jean-Daniel Dupas on 14/04/09.
 *  Copyright 2009 Ninsight. All rights reserved.
 *
 */

#import "WBCollapseView.h"

@class _WBCollapseItemView;
@interface WBCollapseView (WBInternal)

- (_WBCollapseItemView *)_viewForItem:(WBCollapseViewItem *)anItem;

// change item height notification
- (void)_didResizeItemView:(_WBCollapseItemView *)anItem delta:(CGFloat)delta;

@end

@interface _WBCollapseItemView : NSView {
@private
  WBCollapseViewItem *wb_item;
  
  /* Header Components */
  NSTextField *wb_title;
  NSButton *wb_disclose;
  
  struct _wb_civFlags {
    unsigned int highlight:1;
    unsigned int reserved:7;
  } wb_civFlags;
}

@property(readonly) id identifier;
@property(readonly) WBCollapseViewItem *item;
@property(readonly) WBCollapseView *collapseView;

- (id)initWithItem:(WBCollapseViewItem *)anItem;

- (NSRect)headerFrame;
- (NSRect)contentFrame;

- (void)drawHeaderInRect:(NSRect)aRect;

// never call directly. Use WBCollapseItem methods instead.
- (void)setExpanded:(BOOL)expanded animate:(BOOL)flag;

@end

