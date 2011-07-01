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
  return wb_autorelease([[self alloc] init]);
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
  CGFloat offset = floor((NSHeight(frame) - ([font ascender] - [font descender])) / 2);
  return NSInsetRect(frame, 0.0, offset);
}

- (NSRect)contentRectForBounds:(NSRect)bounds {
  return _adjustTextFrame(self, bounds);
}

- (NSRect)titleRectForBounds:(NSRect)theRect {
  return [super titleRectForBounds:[self contentRectForBounds:theRect]];
}

- (NSUInteger)hitTestForEvent:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView {
  return [super hitTestForEvent:event inRect:[self contentRectForBounds:cellFrame] ofView:controlView];
}

//-----------------------------------------------------------------------------
//  editWithFrame:inView:editor:delegate:event:
//-----------------------------------------------------------------------------

- (void)editWithFrame:(NSRect)aRect
               inView:(NSView *)controlView
               editor:(NSText *)editor
             delegate:(id)delegate
                event:(NSEvent *)event {
  [super editWithFrame:[self contentRectForBounds:aRect]
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
  [super selectWithFrame:[self contentRectForBounds:aRect]
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
  [super drawInteriorWithFrame:[self contentRectForBounds:frame] inView:view];
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
