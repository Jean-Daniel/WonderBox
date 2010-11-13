/*
 *  WBTextFieldCell.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBTextFieldCell.h)

@implementation WBTextFieldCell

+ (id)cell {
  return [[[self alloc] init] autorelease];
}

- (id)copyWithZone:(NSZone *)zone {
  WBTextFieldCell *copy = (WBTextFieldCell *)[super copyWithZone:zone];
  copy->wb_tfFlags = wb_tfFlags;
  return copy;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [super encodeWithCoder:aCoder];
  // TODO:
}
- (id)initWithCoder:(NSCoder *)aDecoder {
  if (self = [super initWithCoder:aDecoder]) {
    if ([aDecoder allowsKeyedCoding]) {
      //wb_tfFlags.middle = [aDecoder decodeBoolForKey:@"middle"];
    } else {

    }
  }
  return self;
}

- (BOOL)drawsLineOver {
  return wb_tfFlags.line;
}
- (void)setDrawsLineOver:(BOOL)flag {
  WBFlagSet(wb_tfFlags.line, flag);
}

- (BOOL)centersVertically {
  return wb_tfFlags.middle;
}
- (void)setCentersVertically:(BOOL)flag {
  WBFlagSet(wb_tfFlags.middle, flag);
}

- (BOOL)isHighlightingEnabled {
  return !wb_tfFlags.noHighlight;
}
- (void)setHighlightingEnabled:(BOOL)flag {
  WBFlagSet(wb_tfFlags.noHighlight, !flag);
}

#pragma mark -
WB_INLINE
NSRect _adjustTextFrame(WBTextFieldCell *self, NSRect frame) {
  // super would normally draw text at the top of the cell
  if (!self->wb_tfFlags.middle) return frame;

  NSFont *font = [self font];
  NSInteger offset = (NSInteger)floor((NSHeight(frame) - ([font ascender] - [font descender])) / 2);
  return NSInsetRect(frame, 0.0, offset);
}

- (NSRect)titleRectForBounds:(NSRect)theRect {
  return [super titleRectForBounds:_adjustTextFrame(self, theRect)];
}

- (NSUInteger)hitTestForEvent:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView {
  return [super hitTestForEvent:event inRect:_adjustTextFrame(self, cellFrame) ofView:controlView];
}

//-----------------------------------------------------------------------------
//  editWithFrame:inView:editor:delegate:event:
//-----------------------------------------------------------------------------

- (void)editWithFrame:(NSRect)aRect
               inView:(NSView *)controlView
               editor:(NSText *)editor
             delegate:(id)delegate
                event:(NSEvent *)event {
  [super editWithFrame:_adjustTextFrame(self, aRect)
                inView:controlView
                editor:editor
              delegate:delegate
                 event:event];
}


//-----------------------------------------------------------------------------
//  selectWithFrame:inView:editor:delegate:start:length:
//-----------------------------------------------------------------------------

- (void)selectWithFrame:(NSRect)aRect
                 inView:(NSView *)controlView
                 editor:(NSText *)editor
               delegate:(id)delegate
                  start:(NSInteger)start
                 length:(NSInteger)length {
  [super selectWithFrame:_adjustTextFrame(self, aRect)
                  inView:controlView
                  editor:editor
                 delegate:delegate
                   start:start
                  length:length];
}


//-----------------------------------------------------------------------------
//  drawInteriorWithFrame:inView:
//-----------------------------------------------------------------------------

- (void)drawInteriorWithFrame:(NSRect)frame inView:(NSView *)view {
  [super drawInteriorWithFrame:_adjustTextFrame(self, frame) inView:view];
  if ([self drawsLineOver]) {
    NSRect title = [self titleRectForBounds:frame];
    // FIXME: userspace scale factor
    CGFloat y = NSMidY(title);
    CGFloat twidth = MIN(NSWidth(frame) - NSMinX(title) - 2, NSWidth(title));
    [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(title), y) toPoint:NSMakePoint(NSMinX(title) + twidth, y)];
  }
}

- (NSColor *)highlightColorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  if (wb_tfFlags.noHighlight) return nil;
  return [super highlightColorWithFrame:cellFrame inView:controlView];
}

@end
