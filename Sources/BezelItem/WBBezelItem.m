/*
 *  WBBezelItem.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBBezelItem.h)

#import WBHEADER(WBCGFunctions.h)
#import WBHEADER(WBBezelItemContent.h)

@interface WBBezelItem ()
- (void)didChangeScreen:(NSNotification *)aNotification;
@end

enum {
  kWBBezelItemRadius = 25,
};
static const NSSize kWBBezelItemDefaultSize = {161, 156};

@interface _WBBezelItemView : NSView {
  id wb_item;
  BOOL wb_adjust;
  NSUInteger wb_radius;
}

- (NSUInteger)radius;
- (void)setRadius:(NSUInteger)newRadius;

- (BOOL)adjustSize;
- (void)setAdjustSize:(BOOL)flag;

@end

#pragma mark -
@implementation WBBezelItem

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)styleMask backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation {
  if (self = [super initWithContentRect:contentRect styleMask:styleMask backing:bufferingType defer:deferCreation]) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeScreen:) name:NSWindowDidChangeScreenNotification object:self];
    id content = [[_WBBezelItemView alloc] init];
    [self setContentView:content];
    [content release];
  }
  return self;
}

- (id)initWithContent:(id)content {
  if (self = [super init]) {
    [self setContent:content];
  }
  return self;
}

- (id)init {
  return [self initWithContent:nil];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

#pragma mark -
- (void)resize {
  [[self contentView] resize];
}

- (id)content {
  return [[self contentView] content];
}
- (void)setContent:(id)content {
  [[self contentView] setContent:content];
}

- (NSUInteger)radius {
  return [[self contentView] radius];
}
- (void)setRadius:(NSUInteger)newRadius {
  [[self contentView] setRadius:newRadius];
  [self resize];
}

- (BOOL)adjustSize {
  return [[self contentView] adjustSize];
}
- (void)setAdjustSize:(BOOL)flag {
  [[self contentView] setAdjustSize:flag];
  [self resize];
}

- (void)didChangeScreen:(NSNotification *)aNotification {
	[self resize];
}

@end

#pragma mark -
@implementation _WBBezelItemView

- (id)initWithFrame:(NSRect)frameRect {
  if (self = [super initWithFrame:frameRect]) {
    [self setRadius:kWBBezelItemRadius];
  }
  return self;
}

- (void)resize {
  NSRect dim = NSZeroRect;

  if (wb_adjust) {
    dim.size = wb_item ? [wb_item size] : NSZeroSize;
    dim.origin.x = wb_radius;
    dim.origin.y = wb_radius;
  } else {
    dim.size = kWBBezelItemDefaultSize;
    NSSize size = wb_item ? [wb_item size] : NSZeroSize;
    dim.origin.x = MAX((NSWidth(dim) - size.width) / 2., 0) + wb_radius;
    dim.origin.y = MAX((NSHeight(dim) - size.height) / 2., 0) + wb_radius;
  }

  [wb_item setFrame:dim];

  /* add radius margin */
  dim.size.width += 2 * wb_radius;
  dim.size.height += 2 * wb_radius;

  /* convert point dim into pixels */
  dim = [[self window] frameRectForContentRect:dim];
  /* Adjust screen position window */
  NSRect screen = [[NSScreen mainScreen] frame];
  dim.origin.x = (NSWidth(screen) - NSWidth(dim)) / 2.;
  /* Set 140 points from bottom => 140 * scale pixels */
  dim.origin.y = 140;
  dim.origin.y *= WBScreenUserSpaceScaleFactor([NSScreen mainScreen]);

  [[self window] setFrame:dim display:NO];
}

- (NSUInteger)radius {
  return wb_radius;
}

- (void)setRadius:(NSUInteger)newRadius {
  if (wb_radius != newRadius) {
    wb_radius = newRadius;
  }
}

- (id)content {
  return [wb_item content];
}
- (void)setContent:(id)content {
  if ([wb_item content] != content) {
    [wb_item removeFromSuperview];
    wb_item = [[WBBezelItemContent alloc] initWithContent:content];
    if (wb_item) {
      [self addSubview:wb_item];
      [wb_item release];
    }
    [self resize];
  } else if (nil == wb_item) {
    [self resize];
  }
}

- (BOOL)adjustSize {
  return wb_adjust;
}
- (void)setAdjustSize:(BOOL)flag {
  if (wb_adjust != flag) {
    wb_adjust = flag;
    [self resize];
  }
}

- (void)drawRect:(NSRect)rect {
  NSRect frame = [self frame];
  CGRect cgFrame = NSRectToCGRect(frame);

  CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
  CGContextSaveGState(context);
  CGContextClearRect(context, cgFrame);
  WBCGContextAddRoundRect(context, cgFrame, wb_radius);

  CGContextSetGrayFillColor(context, 0, .15);
  CGContextFillPath(context);

  CGContextRestoreGState(context);
}

@end
