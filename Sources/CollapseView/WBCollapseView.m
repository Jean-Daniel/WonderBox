//
//  WBCollapseView.m
//  Emerald
//
//  Created by Jean-Daniel Dupas on 14/04/09.
//  Copyright 2009 Ninsight. All rights reserved.
//

#import WBHEADER(WBCollapseView.h)
#import WBHEADER(WBCollapseViewItem.h)

#import "WBCollapseViewInternal.h"

@interface WBCollapseView ()

- (void)_setResizingMask:(NSUInteger)mask range:(NSRange)aRange;
- (void)_incrementHeightBy:(CGFloat)delta animate:(BOOL)animate;

- (void)_moveItemsInRange:(NSRange)aRange delta:(CGFloat)height;
- (void)_insertItem:(WBCollapseViewItem *)anItem atIndex:(NSUInteger)anIndex resize:(BOOL)flag;

@end

@implementation WBCollapseView

@synthesize delegate = wb_delegate;

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:wb_views forKey:@"view.items"];
}

- (id)initWithCoder:(NSCoder *)aCoder {
  if (self = [super initWithCoder:aCoder]) {
    wb_views = [[aCoder decodeObjectForKey:@"view.items"] retain];
  }
  return self;
}

- (id)initWithFrame:(NSRect)aFrame {
  aFrame.size.height = 0;
  if (self = [super initWithFrame:aFrame]) {
    wb_views = [[NSMutableArray alloc] init];
    
    // required
    [self setAutoresizesSubviews:YES];
  }
  return self;
}

- (void)dealloc {
  [wb_views release];
  [super dealloc];
}

#pragma mark -
// simplify view management.
- (BOOL)isOpaque { return NO; }
- (BOOL)isFlipped { return YES; }

- (void)viewWillMoveToSuperview:(NSView *)newSuperview {
  NSUInteger mask = [self autoresizingMask];
  mask &= ~(NSViewMaxYMargin | NSViewMinYMargin | NSViewHeightSizable);
  mask |= [newSuperview isFlipped] ? NSViewMaxYMargin : NSViewMinYMargin;
  [self setAutoresizingMask:mask];
  
  // adjust height
  
}

- (void)expandAllItems { [self doesNotRecognizeSelector:_cmd]; }
- (void)collapseAllItems { [self doesNotRecognizeSelector:_cmd]; }

// MARK: Query
- (NSArray *)items {
  NSMutableArray *items = [NSMutableArray array];
  for (_WBCollapseItemView *view in wb_views)
    [items addObject:view.item];
  return items;
}

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
  if (!anItem)
    WBThrowException(NSInvalidArgumentException, @"try to insert nil in collapse view");
  if ([anItem collapseView])
    WBThrowException(NSInvalidArgumentException, @"try to insert an item that is already in a collapse view");
  [self _insertItem:anItem atIndex:anIndex resize:YES];
}

- (void)_insertItem:(WBCollapseViewItem *)anItem atIndex:(NSUInteger)anIndex resize:(BOOL)resize {
  WBAssert(![anItem collapseView] || [anItem collapseView] == self, @"%@ already part of an other collapse view", anItem);
  
  // Search position for this new item
  CGFloat height = 0;
  for (NSUInteger idx = 0; idx < anIndex; idx++)
    height += NSHeight([[wb_views objectAtIndex:idx] frame]);
  
  // MUST set collapse view before creating item's view.
  [anItem setCollapseView:self];
  // create item's view
  _WBCollapseItemView *view = [[_WBCollapseItemView alloc] initWithItem:anItem];
  [view setAutoresizingMask:NSViewWidthSizable | NSViewMaxYMargin];
  // adjust size and position
  NSRect frame = [view frame];
  frame.origin = NSMakePoint(0, height);
  frame.size.width = NSWidth([self frame]); // useless but cost nothing
  [view setFrame:frame];
  
  // compute delta
  CGFloat delta = NSHeight(frame);
  // update self height
  if (resize)
    [self _incrementHeightBy:delta animate:NO];
  
  // Move view that are after the new one.
  if (anIndex < [wb_views count])
    [self _moveItemsInRange:NSMakeRange(anIndex, [wb_views count] - anIndex) delta:delta];
  
  // add new view
  [wb_views insertObject:view atIndex:anIndex];
  [self addSubview:view];
  [view release];
  
  if (WBDelegateHandle(wb_delegate, collapseViewDidChangeNumberOfCollapseViewItems:))
    [wb_delegate collapseViewDidChangeNumberOfCollapseViewItems:self];
}

- (void)removeItem:(WBCollapseViewItem *)anItem {
  NSUInteger idx = [self indexOfItem:anItem];
  if (NSNotFound == idx)
    WBThrowException(NSInvalidArgumentException, @"%@ is not an item of this view", anItem);
  
  [self removeItemAtIndex:idx];
}
- (void)removeItemAtIndex:(NSUInteger)anIndex {
  _WBCollapseItemView *view = [wb_views objectAtIndex:anIndex];
  
  // remove view
  [view removeFromSuperview];
  [view.item setCollapseView:nil];
  
  CGFloat delta = NSHeight([view frame]);
  // Move view that are after the one we remove.
  
  if (anIndex < [wb_views count] - 1) // if not last item
    [self _moveItemsInRange:NSMakeRange(anIndex + 1, [wb_views count] - (anIndex + 1)) delta:delta];
  
  // update self height
  [self _incrementHeightBy:-delta animate:NO];
  
  // update collection
  [wb_views removeObjectAtIndex:anIndex];
  
  if (WBDelegateHandle(wb_delegate, collapseViewDidChangeNumberOfCollapseViewItems:))
    [wb_delegate collapseViewDidChangeNumberOfCollapseViewItems:self];
}

- (void)removeItemWithIdentifier:(id)anIdentifier {
  WBCollapseViewItem *item = [self itemWithIdentifier:anIdentifier];
  if (item)
    [self removeItem:item];
}

// MARK: Internal
- (void)_setResizingMask:(NSUInteger)mask range:(NSRange)aRange {
  if (0 == aRange.length) return;
  for (NSUInteger idx = aRange.location, count = NSMaxRange(aRange); idx < count; idx++) 
    [[wb_views objectAtIndex:idx] setAutoresizingMask:mask];
}

- (void)_moveItemsInRange:(NSRange)aRange delta:(CGFloat)delta {
  for (NSUInteger idx = aRange.location, count = NSMaxRange(aRange); idx < count; idx++) {
    NSView *view = [wb_views objectAtIndex:idx];
    NSPoint origin = [view frame].origin;
    origin.y += delta;
    [view setFrameOrigin:origin];    
  }
}
@class CATransaction;
- (void)_incrementHeightBy:(CGFloat)delta animate:(BOOL)animate {
  NSRect frame = [self frame];
  // update origin if superview is not flipped
  if (![[self superview] isFlipped])
    frame.origin.y -= delta;
  
  frame.size.height += delta;
  
  if (animate) {
    // Prepare animation
    NSViewAnimation *animation = [[NSViewAnimation alloc] init];
    [animation setAnimationBlockingMode:NSAnimationBlocking];
    [animation setAnimationCurve:NSAnimationEaseInOut];
    [animation setFrameRate:30];
    // for debugging and for fun
    if (([[NSApp currentEvent] modifierFlags] & NSDeviceIndependentModifierFlagsMask) == NSShiftKeyMask)
      [animation setDuration:2];
    else
      [animation setDuration:.25];
    
    NSDictionary *props = [NSDictionary dictionaryWithObjectsAndKeys:
                           self, NSViewAnimationTargetKey,
                           [NSValue valueWithRect:frame], NSViewAnimationEndFrameKey,
                           //[NSValue valueWithRect:collapsed], NSViewAnimationStartFrameKey,
                           nil];
    [animation setViewAnimations:[NSArray arrayWithObject:props]];
    [animation startAnimation];
    [animation release];
  } else {
    [self setFrame:frame];
  }
}

@end

#pragma mark -
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

- (void)_setExpanded:(BOOL)expands forItem:(WBCollapseViewItem *)anItem animate:(BOOL)animate {
  _WBCollapseItemView *view = [self _viewForItem:anItem];
  WBAssert(view, @"%@ is not an item of this view", anItem);
  
  WBAssert((expands && ![anItem isExpanded]) || (!expands && [anItem isExpanded]), 
           @"invalid operation for this item state");
  
  // Let the delegate cancel the action
  if (WBDelegateHandle(wb_delegate, collapseView:shouldSetExpanded:forItem:))
    if (![wb_delegate collapseView:self shouldSetExpanded:expands forItem:anItem])
      return;
  
  CGFloat delta = [view expandHeight];
  if (delta <= 0) return;
  
  // if collapse: delta should be negative
  if (!expands) delta = -delta;
  
  if (WBDelegateHandle(wb_delegate, collapseView:willSetExpanded:forItem:))
    [wb_delegate collapseView:self willSetExpanded:expands forItem:anItem];
  
  [view willSetExpanded:expands];
  
  NSUInteger count = [wb_views count];
  NSUInteger idx = [wb_views indexOfObjectIdenticalTo:view];
  // all view before this one should have mask: NSViewWidthSizable | NSViewMaxYMargin
  if (idx > 0)
    [self _setResizingMask:NSViewWidthSizable | NSViewMaxYMargin range:NSMakeRange(0, idx)];
  // this view should have mask: NSViewWidthSizable | NSViewHeightSizable
  [view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
  // all view after this one should have mask: NSViewWidthSizable | NSViewMinYMargin
  if (idx < count - 1)
    [self _setResizingMask:NSViewWidthSizable | NSViewMinYMargin range:NSMakeRange(idx + 1, count - (idx + 1))];
  // now we are ready to resize self.
  [self _incrementHeightBy:delta animate:animate];
  
  // reset sizing mask to a good default (not required)
  [self _setResizingMask:NSViewWidthSizable | NSViewMaxYMargin range:NSMakeRange(0, count)];

  [view didSetExpanded:expands];
  
  if (WBDelegateHandle(wb_delegate, collapseView:didSetExpanded:forItem:))
    [wb_delegate collapseView:self didSetExpanded:expands forItem:anItem];
}

@end
