/*
 *  WBHeaderView.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBHeaderView.h)

#import WBHEADER(WBGeometry.h)

#import WBHEADER(NSColor+WonderBox.h)
#import WBHEADER(NSImage+WonderBox.h)
#import WBHEADER(NSButton+WonderBox.h)

static NSColor *kWBHeaderTopLineColor = nil;
static NSImage *kWBHeaderViewBackground = nil;
static NSImage *kWBHeaderViewGrayBackground = nil;

@interface WBHeaderMenu : NSPopUpButton {
}

- (id)initWithFrame:(NSRect)frameRect pullsDown:(BOOL)flag position:(WBHeaderPosition)position;

@end

@interface WBHeaderMenuCell : NSPopUpButtonCell {
  WBHeaderPosition wb_position;
}

- (id)initTextCell:(NSString *)text pullsDown:(BOOL)flag position:(WBHeaderPosition)position;

@end

// MARK: -
@implementation WBHeaderView

+ (void)initialize {
  if ([WBHeaderView class] == self) {
    kWBHeaderTopLineColor = [[NSColor colorWithCalibratedWhite:.549 alpha:1] retain];
    kWBHeaderViewBackground = [[NSImage imageNamed:@"WBHeader" inBundle:WBCurrentBundle()] retain];
    kWBHeaderViewGrayBackground = [[NSImage imageNamed:@"WBHeader-down" inBundle:WBCurrentBundle()] retain];
  }
}

- (id)initWithFrame:(NSRect)aFrame {
  if (self = [super initWithFrame:aFrame]) {
    wb_left = [[NSMutableArray alloc] init];
    wb_right = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)dealloc {
  [wb_left release];
  [wb_right release];
  [super dealloc];
}

- (NSRect)bounds {
  NSRect rect = [super bounds];
  rect.origin.y += 1;
  rect.size.height -= 2;
  return rect;
}

- (void)drawRect:(NSRect)rect {
  NSRect imgRect = NSZeroRect;
  imgRect.size = [kWBHeaderViewBackground size];
  [kWBHeaderViewBackground drawInRect:[self bounds] fromRect:imgRect operation:NSCompositeSourceOver fraction:1];
  /* Draws Borders */
  [NSBezierPath setDefaultLineWidth:1];

  /* Draws Top And bottom */
  CGFloat y = NSHeight([self frame]);
  CGFloat width = NSWidth([self frame]);
  [kWBHeaderTopLineColor setStroke];
  // FIXME: userspace scale factor
  [NSBezierPath strokeLineFromPoint:NSMakePoint(0, y - 0.5) toPoint:NSMakePoint(width, y - 0.5)];
  [[NSColor wbLightBorderColor] setStroke];
  [NSBezierPath strokeLineFromPoint:NSMakePoint(0, 0.5) toPoint:NSMakePoint(width, 0.5)];

  /* Draws Left and Right */
  if (wb_xhFlags.left) {
    [NSBezierPath strokeLineFromPoint:NSMakePoint(0.5, 0) toPoint:NSMakePoint(0.5, NSHeight([self frame]))];
  }
  if (wb_xhFlags.right) {
    CGFloat x = NSWidth([self frame]) - 0.5;
    [NSBezierPath strokeLineFromPoint:NSMakePoint(x, 0) toPoint:NSMakePoint(x, NSHeight([self frame]))];
  }
}

// MARK: -
- (NSUInteger)drawsBorder {
  return wb_xhFlags.left | (wb_xhFlags.right << 1);
}

- (void)setDrawsBorder:(NSUInteger)border {
  wb_xhFlags.left = border & 1;
  wb_xhFlags.right =  border & (1 << 1);
}

- (CGFloat)paddingForPosition:(WBHeaderPosition)aPosition {
  return aPosition == kWBHeaderLeft ? wb_leftPadding : wb_rightPadding;
}

- (void)setPadding:(CGFloat)padding forPosition:(WBHeaderPosition)aPosition {
  CGFloat delta;
  NSArray *buttons;
  if (kWBHeaderLeft == aPosition) {
    buttons = wb_left;
    /* If draws left border */
    if (wb_xhFlags.left) {
      /* padding must be a least one */
      padding = MAX(1.0, padding);
    }
    delta = padding - wb_leftPadding;
    wb_leftPadding = padding;
  } else {
    buttons = wb_right;
    /* If draws right border */
    if (wb_xhFlags.right) {
      /* padding must be a least one */
      padding = MAX(1.0, padding);
    }
    delta = wb_rightPadding - padding;
    wb_rightPadding = padding;
  }
  if (fnonzero(delta)) {
    for (NSUInteger idx = 0; idx < [buttons count]; idx++) {
      NSButton *button = [buttons objectAtIndex:idx];
      NSRect frame = [button frame];
      frame.origin.x += delta;
      [button setFrame:frame];
    }
    [self setNeedsDisplay:YES];
  }
}

- (NSImage *)imageForButton:(NSImage *)anImage width:(CGFloat)width background:(NSImage *)background position:(WBHeaderPosition)position {
  NSRect srcRect = NSZeroRect;
  NSRect destRect = NSZeroRect;
  srcRect.size = [background size];

  NSImage *img = [[NSImage alloc] initWithSize:NSMakeSize(width, NSHeight(srcRect))];

  [img lockFocus];
  destRect.size = [img size];
  [background drawInRect:destRect fromRect:srcRect operation:NSCompositeSourceOver fraction:1];

  NSPoint origin = NSMakePoint(0, 0);
  origin.x = (NSWidth(destRect) - [anImage size].width) / 2;
  origin.y = (NSHeight(destRect) - [anImage size].height) / 2;
  [anImage compositeToPoint:origin operation:NSCompositeSourceOver];
  [[NSColor wbBorderColor] setStroke];
  /* Draw border line */
  [NSBezierPath setDefaultLineWidth:1];
  CGFloat x = (position == kWBHeaderRight) ? 0 : NSWidth(destRect);
  [NSBezierPath strokeLineFromPoint:NSMakePoint(x, 0) toPoint:NSMakePoint(x, NSHeight(destRect))];
  [img unlockFocus];
  return [img autorelease];
}

- (void)wb_addButton:(NSButton *)aButton position:(WBHeaderPosition)position {
  NSUInteger x = 0;
  NSUInteger mask = 0;
  if (position == kWBHeaderLeft) {
    mask = NSViewMaxXMargin;
    NSButton *last = [wb_left lastObject];
    x = last ? NSMaxX([last frame]) : wb_leftPadding;
    [wb_left addObject:aButton];
  } else if (position == kWBHeaderRight) {
    mask = NSViewMinXMargin;
    NSButton *first = [wb_right count] > 0 ? [wb_right objectAtIndex:0] : nil;
    x = first ? NSMinX([first frame]) : (NSMaxX([self bounds]) - wb_rightPadding);
    x -= NSWidth([aButton frame]);
    [wb_right addObject:aButton];
  }
  [aButton setFrameOrigin:NSMakePoint(x, 1)];
  [aButton setAutoresizingMask:mask];
  [self addSubview:aButton];
}

- (NSButton *)addButton:(NSImage *)anImage position:(WBHeaderPosition)position {
  NSParameterAssert(anImage != nil);
  CGFloat width = MAX(25, [anImage size].width);
  NSButton *button = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, width, NSHeight([self bounds]))
                                               image:[self imageForButton:anImage width:width background:kWBHeaderViewBackground position:position]
                                      alternateImage:[self imageForButton:anImage width:width background:kWBHeaderViewGrayBackground position:position]];
  [self wb_addButton:button position:position];
  return [button autorelease];
}

- (NSPopUpButton *)addMenu:(NSMenu *)aMenu position:(WBHeaderPosition)position {
  NSPopUpButton *button = [[WBHeaderMenu alloc] initWithFrame:NSMakeRect(0, 0, 80, NSHeight([self bounds]))
                                                    pullsDown:NO
                                                     position:position];
  [button setFocusRingType:NSFocusRingTypeNone];
  [button setBordered:NO];
  [button setMenu:aMenu];
  [button sizeToFit];

  [self wb_addButton:button position:position];

  [button release];
  return button;
}

/* When a button size change, should update all others button origin */
- (void)didChangedButtonSize:(NSButton *)aButton {
  /* If resized button is a left button */
  NSUInteger idx = [wb_left indexOfObject:aButton];
  if (idx != NSNotFound) {
    idx++;
    CGFloat origin = NSMaxX([aButton frame]);
    while (idx < [wb_left count]) {
      NSButton *button = [wb_left objectAtIndex:idx];
      NSRect frame = [button frame];
      frame.origin.x = origin;
      [button setFrame:frame];
      origin = NSMaxX(frame);
      idx++;
    }
  } else {
    /* If button is a right button */
    idx = [wb_right indexOfObject:aButton];
    if (idx != NSNotFound) {
      idx += 1; // to be able to use the while(idx--) pattern.
      /* if last object, use padding, else use next button position */
      CGFloat origin = (idx == [wb_right count]) ? (NSWidth([self bounds]) - wb_rightPadding) : NSMinX([[wb_right objectAtIndex:idx] frame]);
      while (idx-- > 0) {
        NSButton *button = [wb_right objectAtIndex:idx];
        NSRect frame = [button frame];
        frame.origin.x = origin - NSWidth(frame);
        [button setFrame:frame];
        origin = NSMinX(frame);
      }
    }
  }
  [self setNeedsDisplay:YES];
}

@end
// MARK: -
@implementation WBHeaderMenu

- (id)initWithFrame:(NSRect)frameRect pullsDown:(BOOL)flag position:(WBHeaderPosition)position {
  if (self = [super initWithFrame:frameRect pullsDown:flag]) {
    WBHeaderMenuCell *cell = [[WBHeaderMenuCell alloc] initTextCell:@"<empty>" pullsDown:flag position:position];
    [cell setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
    [self setCell:cell];
    [cell release];
  }
  return self;
}

- (WBHeaderView *)headerView {
  id parent = [self superview];
  return [parent isKindOfClass:[WBHeaderView class]] ? parent : nil;
}

- (void)sizeToFit {
  [super sizeToFit];
  [[self headerView] didChangedButtonSize:self];
}

@end

@implementation WBHeaderMenuCell

static NSImage *kWBHeaderMenuImage = nil;

+ (void)initialize {
  if ([WBHeaderMenuCell class] == self) {
    kWBHeaderMenuImage = [[NSImage imageNamed:@"WBHeaderMenu" inBundle:WBCurrentBundle()] retain];
  }
}

- (id)initTextCell:(NSString *)text pullsDown:(BOOL)flag position:(WBHeaderPosition)position {
  if (self = [super initTextCell:text pullsDown:flag]) {
    wb_position = position;
  }
  return self;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
#if 0
  /* Draw background */
  NSRect imgRect = NSZeroRect;
  imgRect.size = [kWBHeaderViewBackground size];
  [kWBHeaderViewBackground drawInRect:cellFrame fromRect:imgRect operation:NSCompositeSourceOver fraction:1];
#endif

  /* Draw arrows image */
  CGFloat x = NSWidth(cellFrame) - [kWBHeaderMenuImage size].width - 5;
  [kWBHeaderMenuImage compositeToPoint:NSMakePoint(x, NSHeight(cellFrame)) operation:NSCompositeSourceOver];

  /* Draw border line */
  [[NSColor wbBorderColor] setStroke];
  x = (wb_position == kWBHeaderRight) ? 0 : NSMaxX(cellFrame);
  [NSBezierPath strokeLineFromPoint:NSMakePoint(x, 0) toPoint:NSMakePoint(x, NSHeight(cellFrame))];

  /* Draw interior */
  /* we want to draw the image as a 12x12 pixels icon, so clip to allows super to
    draw text but not image */
  [[NSGraphicsContext currentContext] saveGraphicsState];
  [NSBezierPath clipRect:[self titleRectForBounds:cellFrame]];
  [self drawInteriorWithFrame:cellFrame inView:controlView];
  [[NSGraphicsContext currentContext] restoreGraphicsState];

  /* Then draw the image in a 12x12 rect */
  NSImage *img = [self image];
  if (img) {
    NSRect dest = [self imageRectForBounds:cellFrame];
    CGContextRef ctxt = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(ctxt);
    /* Flip if needed */
    if ([controlView isFlipped]) {
      CGContextTranslateCTM(ctxt, 0., NSHeight([controlView frame]));
      CGContextScaleCTM(ctxt, 1., -1.);
      /* Adjust origin */
      dest.origin.y = NSHeight([controlView frame]) - dest.origin.y - dest.size.height;
    }

    NSRect source = NSZeroRect;
    source.size = [img size];
    CGContextSetShouldAntialias(ctxt, true);
    CGContextSetInterpolationQuality(ctxt, kCGInterpolationHigh);
    [img drawInRect:dest fromRect:source operation:NSCompositeSourceOver fraction:1];
    CGContextRestoreGState(ctxt);
  }
}

- (NSRect)imageRectForBounds:(NSRect)theRect {
  NSRect rect = [super imageRectForBounds:theRect];
	if (NSFoundationVersionNumber < 677)
		rect.origin.y += 2; // Tiger
	else
		rect.origin.y += 4.5;

  rect.origin.x = 4;

  CGFloat deltaY = NSHeight(rect) - 12;
  if (deltaY > 0)
    rect.origin.y += deltaY/2;

  rect.size = NSSizeFromCGSize(
                               WBSizeScaleToSize(NSSizeToCGSize(rect.size), CGSizeMake(12, 12), kWBScalingModeProportionallyFit)
                               );
  return rect;
}

- (NSRect)titleRectForBounds:(NSRect)theRect {
  NSRect rect = [super titleRectForBounds:theRect];
	if (NSFoundationVersionNumber < 677)
		rect.origin.y += 1; // Tiger
	else
		rect.origin.y += 5;

  NSImage *img = [self image];
  rect.origin.x = img ? MIN([img size].width, 12) + 8 : 3;
  return rect;
}

- (void)selectItemAtIndex:(NSInteger)anIndex {
  [super selectItemAtIndex:anIndex];
  [(NSControl *)[self controlView] sizeToFit];
}

@end
