/*
 *  WBCollapseViewInternal.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBCollapseView.h)
#import WBHEADER(WBCollapseViewItem.h)

@class _WBCollapseItemView;
@interface WBCollapseView (WBInternal)

- (_WBCollapseItemView *)_viewForItem:(WBCollapseViewItem *)anItem;

// change item height notification
- (void)_didResizeItemView:(_WBCollapseItemView *)anItem delta:(CGFloat)delta;

- (void)_setExpanded:(BOOL)expands forItem:(WBCollapseViewItem *)anItem animate:(BOOL)animate;

@end

@interface WBCollapseViewItem (WBInternal)

- (void)willSetExpanded:(BOOL)expanded;
- (void)didSetExpanded:(BOOL)expanded;

@end

@class _WBCollapseItemHeaderView;
@interface _WBCollapseItemView : NSView {
@private
  WBCollapseViewItem *wb_item;
  
  /* Components */
  NSView *wb_body;
  _WBCollapseItemHeaderView *wb_header;
  
  struct _wb_civFlags {
    unsigned int resizing:1;
    unsigned int resizeMask:7;
  } wb_civFlags;
}

@property(readonly) id identifier;
@property(readonly) WBCollapseViewItem *item;
@property(readonly) WBCollapseView *collapseView;

- (id)initWithItem:(WBCollapseViewItem *)anItem;

- (NSRect)headerFrame;

- (CGFloat)expandHeight;

- (void)willSetExpanded:(BOOL)expanded;
- (void)didSetExpanded:(BOOL)expanded;

@end
