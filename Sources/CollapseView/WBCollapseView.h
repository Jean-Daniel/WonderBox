//
//  WBCollapseView.h
//  Emerald
//
//  Created by Jean-Daniel Dupas on 14/04/09.
//  Copyright 2009 Ninsight. All rights reserved.
//

@class WBCollapseViewItem;
@protocol WBCollapseViewDelegate;
@interface WBCollapseView : NSView <NSCoding> {
@private
  NSMutableArray *wb_views;
  id <WBCollapseViewDelegate> wb_delegate __weak;
}

@property(assign) __weak id <WBCollapseViewDelegate> delegate;

- (void)expandAllItems;
- (void)collapseAllItems;

/* Add/Remove tabs */
- (void)addItem:(WBCollapseViewItem *)anItem;                              // Add item at the end.
- (void)insertItem:(WBCollapseViewItem *)anItem atIndex:(NSUInteger)index; // May raise an NSRangeException

- (void)removeItem:(WBCollapseViewItem *)anItem;                           // Item must be an existing CollapseViewItem
- (void)removeItemWithIdentifier:(id)anIdentifier;

/* Query */
- (NSUInteger)numberOfItems;

- (WBCollapseViewItem *)itemAtIndex:(NSUInteger)index;			// May raise an NSRangeException	
- (WBCollapseViewItem *)itemWithIdentifier:(id)identifier;

- (NSUInteger)indexOfItem:(WBCollapseViewItem *)tabViewItem; // NSNotFound if not found
- (NSUInteger)indexOfItemWithIdentifier:(id)identifier;			 // NSNotFound if not found

/* Hit testing */
- (WBCollapseViewItem *)itemAtPoint:(NSPoint)point;			// point in local coordinates. returns nil if none.

@end

@protocol WBCollapseViewDelegate

@optional
- (void)collapseViewDidChangeNumberOfCollapseViewItems:(WBCollapseView *)aView;

- (BOOL)collapseView:(WBCollapseView *)aView shouldSetExpanded:(BOOL)expanded forItem:(WBCollapseViewItem *)anItem;
- (void)collapseView:(WBCollapseView *)aView willSetExpanded:(BOOL)expanded forItem:(WBCollapseViewItem *)anItem;
- (void)collapseView:(WBCollapseView *)aView didSetExpanded:(BOOL)expanded forItem:(WBCollapseViewItem *)anItem;

@end

