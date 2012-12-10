/*
 *  WBCollapseView.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBCollapseView.h>
#import <WonderBox/WBCollapseViewItem.h>

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
  [aCoder encodeObject:wb_views forKey:@"collapse.views"];
  [aCoder encodeObject:wb_items forKey:@"collapse.items"];
}

- (id)initWithCoder:(NSCoder *)aCoder {
  if (self = [super initWithCoder:aCoder]) {
    wb_views = spx_retain([aCoder decodeObjectForKey:@"collapse.views"]);
    wb_items = spx_retain([aCoder decodeObjectForKey:@"collapse.items"]);
  }
  return self;
}

- (id)initWithFrame:(NSRect)aFrame {
  aFrame.size.height = 0;
  if (self = [super initWithFrame:aFrame]) {
    wb_views = [[NSMutableArray alloc] init];
    wb_items = [[NSMutableArray alloc] init];
    // required
    [self setAutoresizesSubviews:YES];
  }
  return self;
}

- (void)dealloc {
  spx_release(wb_views);
  spx_release(wb_items);
  spx_dealloc();
}

#pragma mark -
// simplify view management.
- (BOOL)isOpaque { return NO; }
- (BOOL)isFlipped { return YES; }

- (void)viewWillMoveToSuperview:(NSView *)newSuperview {
  NSUInteger mask = [self autoresizingMask];
  mask = mask & (NSUInteger)(~(NSViewMaxYMargin | NSViewMinYMargin | NSViewHeightSizable));
  mask |= [newSuperview isFlipped] ? NSViewMaxYMargin : NSViewMinYMargin;
  [self setAutoresizingMask:mask];

  // adjust height

}

- (void)expandAllItems { [self doesNotRecognizeSelector:_cmd]; }
- (void)collapseAllItems { [self doesNotRecognizeSelector:_cmd]; }

// MARK: Query
- (NSArray *)items {
  return spx_autorelease([wb_items copy]);
}

- (NSUInteger)numberOfItems {
  return [wb_items count];
}

- (WBCollapseViewItem *)itemAtIndex:(NSUInteger)anIndex {
  return [wb_items objectAtIndex:anIndex];
}

- (WBCollapseViewItem *)itemWithIdentifier:(id)identifier {
  for (WBCollapseViewItem *item in wb_items) {
    if ([[item identifier] isEqual:identifier])
      return item;
  }
  return nil;
}

- (NSUInteger)indexOfItem:(WBCollapseViewItem *)anItem {
  for (NSUInteger idx = 0, count = [wb_items count]; idx < count; idx++) {
    if ([[wb_items objectAtIndex:idx] isEqual:anItem])
      return idx;
  }
  return NSNotFound;
}
- (NSUInteger)indexOfItemWithIdentifier:(id)identifier {
  for (NSUInteger idx = 0, count = [wb_items count]; idx < count; idx++) {
    if ([[[wb_items objectAtIndex:idx] identifier] isEqual:identifier])
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
    SPXThrowException(NSInvalidArgumentException, @"try to insert nil in collapse view");
  if ([anItem collapseView])
    SPXThrowException(NSInvalidArgumentException, @"try to insert an item that is already in a collapse view");
  [self _insertItem:anItem atIndex:anIndex resize:YES];
}

- (void)_insertItem:(WBCollapseViewItem *)anItem atIndex:(NSUInteger)anIndex resize:(BOOL)resize {
  NSAssert(![anItem collapseView] || [anItem collapseView] == self, @"%@ already part of an other collapse view", anItem);

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
  [wb_items insertObject:anItem atIndex:anIndex];
  [self addSubview:view];
  spx_release(view);

  if (SPXDelegateHandle(wb_delegate, collapseViewDidChangeNumberOfCollapseViewItems:))
    [wb_delegate collapseViewDidChangeNumberOfCollapseViewItems:self];
}

- (void)removeAllItems {
  if (0 == [wb_views count]) return;

  for (_WBCollapseItemView *view in wb_views) {
    // remove view
    [view removeFromSuperview];
    [view.item setCollapseView:nil];
    [view invalidate];
  }
  // Set height to 0
  [self _incrementHeightBy:- [self frame].size.height animate:NO];

  // update collection
  [wb_views removeAllObjects];
  [wb_items removeAllObjects];
  // Notify
  if (SPXDelegateHandle(wb_delegate, collapseViewDidChangeNumberOfCollapseViewItems:))
    [wb_delegate collapseViewDidChangeNumberOfCollapseViewItems:self];
}

- (void)removeItem:(WBCollapseViewItem *)anItem {
  NSUInteger idx = [self indexOfItem:anItem];
  if (NSNotFound == idx)
    SPXThrowException(NSInvalidArgumentException, @"%@ is not an item of this view", anItem);

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
  [view invalidate];
  [wb_views removeObjectAtIndex:anIndex];
  [wb_items removeObjectAtIndex:anIndex];
  if (SPXDelegateHandle(wb_delegate, collapseViewDidChangeNumberOfCollapseViewItems:))
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
    [(NSView *)[wb_views objectAtIndex:idx] setAutoresizingMask:mask];
}

- (void)_moveItemsInRange:(NSRange)aRange delta:(CGFloat)delta {
  for (NSUInteger idx = aRange.location, count = NSMaxRange(aRange); idx < count; idx++) {
    NSView *view = [wb_views objectAtIndex:idx];
    NSPoint origin = [view frame].origin;
    origin.y += delta;
    [view setFrameOrigin:origin];
  }
}

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
    //[animation setAnimationCurve:NSAnimationLinear];
    [animation setFrameRate:30];
    // for debugging and for fun
    NSTimeInterval duration;
    if (([[NSApp currentEvent] modifierFlags] & NSDeviceIndependentModifierFlagsMask) == NSShiftKeyMask)
      duration = MIN(1.8, ABS(delta / 100));
    else
      duration = MIN(.50, ABS(delta / 350)); //  350px per seconds, but 0.60s maxi.

    [animation setDuration:duration];

    NSDictionary *props = [NSDictionary dictionaryWithObjectsAndKeys:
                           self, NSViewAnimationTargetKey,
                           [NSValue valueWithRect:frame], NSViewAnimationEndFrameKey,
                           //[NSValue valueWithRect:collapsed], NSViewAnimationStartFrameKey,
                           nil];
    [animation setViewAnimations:[NSArray arrayWithObject:props]];
    [animation startAnimation];
    spx_release(animation);
  } else {
    [self setFrame:frame];
  }
}

struct _WBCollapseViewCompare {
  void *ctxt;
  NSComparisonResult (*compare)(id, id, void *);
};

static
NSComparisonResult _WBCollapseViewCompare(id v1, id v2, void *ctxt) {
  struct _WBCollapseViewCompare *fct = (struct _WBCollapseViewCompare *)ctxt;
  return fct->compare([v1 item], [v2 item], fct->ctxt);
}

- (void)sortItemsUsingFunction:(NSComparisonResult (*)(id, id, void *))compare context:(void *)context {
  struct _WBCollapseViewCompare ctxt = { context, compare };
  [wb_views sortUsingFunction:_WBCollapseViewCompare context:&ctxt];

  // rearrange view and resync wb_items
  CGFloat height = 0;
  [wb_items removeAllObjects];
  for (_WBCollapseItemView *view in wb_views) {
    [view setFrameOrigin:NSMakePoint(0, height)];
    height += NSHeight([view frame]);
    [wb_items addObject:[view item]];
  }
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)len {
  return [wb_items countByEnumeratingWithState:state objects:buffer count:len];
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

- (void)_resizeItemView:(_WBCollapseItemView *)view delta:(CGFloat)delta animate:(BOOL)animate {
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
}

- (void)_setExpanded:(BOOL)expands forItem:(WBCollapseViewItem *)anItem animate:(BOOL)animate {
  _WBCollapseItemView *view = [self _viewForItem:anItem];
  NSAssert(view, @"%@ is not an item of this view", anItem);

  NSAssert((expands && ![anItem isExpanded]) || (!expands && [anItem isExpanded]),
           @"invalid operation for this item state");

  // Let the delegate cancel the action
  if (SPXDelegateHandle(wb_delegate, collapseView:shouldSetExpanded:forItem:))
    if (![wb_delegate collapseView:self shouldSetExpanded:expands forItem:anItem])
      return;

  // tell the delegate…
  if (SPXDelegateHandle(wb_delegate, collapseView:willSetExpanded:forItem:))
    [wb_delegate collapseView:self willSetExpanded:expands forItem:anItem];

  // Then compute delta. It let a chance to the delegate to adjust item size before display
  CGFloat delta = [view expandHeight];
  if (delta <= 0) return;

  // if collapse: delta should be negative
  if (!expands) delta = -delta;

  [view willSetExpanded:expands];

  [self _resizeItemView:view delta:delta animate:animate];

  [view didSetExpanded:expands];

  if (SPXDelegateHandle(wb_delegate, collapseView:didSetExpanded:forItem:))
    [wb_delegate collapseView:self didSetExpanded:expands forItem:anItem];
}

@end
