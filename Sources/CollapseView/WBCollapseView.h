/*
 *  WBCollapseView.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#include <WonderBox/WBBase.h>

#import <Cocoa/Cocoa.h>

@class WBCollapseViewItem;
@protocol WBCollapseViewDelegate;
WB_OBJC_EXPORT
@interface WBCollapseView : NSView <NSCoding,NSFastEnumeration> {
@private
  NSMutableArray *wb_items;
  NSMutableArray *wb_views;
  __unsafe_unretained id <WBCollapseViewDelegate> wb_delegate;
}

@property(nonatomic, assign) IBOutlet id <WBCollapseViewDelegate> delegate;

- (void)expandAllItems;
- (void)collapseAllItems;

/* Add/Remove tabs */
- (void)addItem:(WBCollapseViewItem *)anItem;                              // Add item at the end.
- (void)insertItem:(WBCollapseViewItem *)anItem atIndex:(NSUInteger)index; // May raise an NSRangeException

- (void)removeAllItems;
- (void)removeItem:(WBCollapseViewItem *)anItem;                           // Item must be an existing CollapseViewItem
- (void)removeItemAtIndex:(NSUInteger)anIndex;
- (void)removeItemWithIdentifier:(id)anIdentifier;

/* Query */
- (NSArray *)items; // safe to mutate items while iteratign the returned collection
- (NSUInteger)numberOfItems;

- (WBCollapseViewItem *)itemAtIndex:(NSUInteger)index;      // May raise an NSRangeException
- (WBCollapseViewItem *)itemWithIdentifier:(id)identifier;

- (NSUInteger)indexOfItem:(WBCollapseViewItem *)tabViewItem; // NSNotFound if not found
- (NSUInteger)indexOfItemWithIdentifier:(id)identifier;      // NSNotFound if not found

- (void)sortItemsUsingFunction:(NSComparisonResult (*)(id, id, void *))compare context:(void *)context;

/* Hit testing */
- (WBCollapseViewItem *)itemAtPoint:(NSPoint)point;      // point in local coordinates. returns nil if none.

@end

@protocol WBCollapseViewDelegate <NSObject>

@optional
- (void)collapseViewDidChangeNumberOfCollapseViewItems:(WBCollapseView *)aView;

- (BOOL)collapseView:(WBCollapseView *)aView shouldSetExpanded:(BOOL)expanded forItem:(WBCollapseViewItem *)anItem;
- (void)collapseView:(WBCollapseView *)aView willSetExpanded:(BOOL)expanded forItem:(WBCollapseViewItem *)anItem;
- (void)collapseView:(WBCollapseView *)aView didSetExpanded:(BOOL)expanded forItem:(WBCollapseViewItem *)anItem;

@end

