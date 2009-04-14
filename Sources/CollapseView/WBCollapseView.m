//
//  WBCollapseView.m
//  Emerald
//
//  Created by Jean-Daniel Dupas on 14/04/09.
//  Copyright 2009 Ninsight. All rights reserved.
//

#import WBHEADER(WBCollapseView.h)

#import "WBCollapseViewInternal.h"

@interface WBCollapseView ()

@end

@implementation WBCollapseView

- (id)initWithCoder:(NSCoder *)aCoder {
  if (self = [super initWithCoder:aCoder]) {
    // TODO: 
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [super encodeWithCoder:aCoder];
  // TODO: 
}

- (id)initWithFrame:(NSRect)aFrame {
  if (self = [super initWithFrame:aFrame]) {
    wb_views = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)dealloc {
  [wb_views release];
  [super dealloc];
}

#pragma mark -
- (void)expandAllItems { [self doesNotRecognizeSelector:_cmd]; }
- (void)collapseAllItems { [self doesNotRecognizeSelector:_cmd]; }

// MARK: Query
- (NSUInteger)numberOfItems {
  return [wb_views count];
}

- (WBCollapseViewItem *)itemAtIndex:(NSUInteger)anIndex {
  return [[wb_views objectAtIndex:anIndex] item];
}

- (WBCollapseViewItem *)itemWithIdentifier:(id)identifier {
  for (_WBCollapseItemView *view in wb_views) {
    if ([[view identifier] isEqual:identifier])
      return [view item];
  }
  return nil;
}

- (NSUInteger)indexOfItem:(WBCollapseViewItem *)anItem {
  for (NSUInteger idx = 0, count = [wb_views count]; idx < count; idx++) {
    if ([[[wb_views objectAtIndex:idx] item] isEqual:anItem])
      return idx;
  }
  return NSNotFound;
}
- (NSUInteger)indexOfItemWithIdentifier:(id)identifier {
  for (NSUInteger idx = 0, count = [wb_views count]; idx < count; idx++) {
    if ([[[wb_views objectAtIndex:idx] identifier] isEqual:identifier])
      return idx;
  }
  return NSNotFound;
}

// MARK: Hit Testing
- (WBCollapseViewItem *)itemAtPoint:(NSPoint)point {
  if (point.y < 0) return nil;
  
  CGFloat height = 0;
  for (_WBCollapseItemView *view in wb_views) {
    height += NSHeight([view frame]);
    if (height > point.y)
      return view.item;
  }
  return nil;
}

// MARK: Item Manipulation
- (void)addItem:(WBCollapseViewItem *)anItem {
  // Insert at end
  [self insertItem:anItem atIndex:[wb_views count]];
}
- (void)insertItem:(WBCollapseViewItem *)anItem atIndex:(NSUInteger)anIndex {
  // TODO: 
}

- (void)removeItem:(WBCollapseViewItem *)anItem {
  // TODO: 
}
- (void)removeItemWithIdentifier:(id)anIdentifier {
  WBCollapseViewItem *item = [self itemWithIdentifier:anIdentifier];
  if (item)
    [self removeItem:item];
}

@end
@implementation WBCollapseView (WBInternal)

- (_WBCollapseItemView *)_viewForItem:(WBCollapseViewItem *)anItem {
  for (_WBCollapseItemView *view in wb_views) {
    if ([view.item isEqual:anItem])
      return view;
  }
  return nil;
}

- (void)_didResizeItemView:(_WBCollapseItemView *)anItem delta:(CGFloat)delta {
  // TODO: 
}

@end
