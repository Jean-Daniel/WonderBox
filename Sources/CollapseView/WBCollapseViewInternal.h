/*
 *  WBCollapseViewInternal.h
 *  Emerald
 *
 *  Created by Jean-Daniel Dupas on 14/04/09.
 *  Copyright 2009 Ninsight. All rights reserved.
 *
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

@interface _WBCollapseItemView : NSView {
@private
  WBCollapseViewItem *wb_item;
  
  /* Header Components */
  NSTextField *wb_title;
  NSButton *wb_disclose;
  
  struct _wb_civFlags {
    unsigned int resizing:1;
    unsigned int highlight:1;
    unsigned int resizeMask:6;
  } wb_civFlags;
}

@property(readonly) id identifier;
@property(readonly) WBCollapseViewItem *item;
@property(readonly) WBCollapseView *collapseView;

- (id)initWithItem:(WBCollapseViewItem *)anItem;

- (NSRect)headerBounds;

- (CGFloat)expandHeight;

- (void)drawHeaderInRect:(NSRect)aRect;

- (void)willSetExpanded:(BOOL)expanded;
- (void)didSetExpanded:(BOOL)expanded;

@end

