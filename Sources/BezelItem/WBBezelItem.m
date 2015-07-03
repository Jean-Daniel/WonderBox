/*
 *  WBBezelItem.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBBezelItem.h>

#import <WonderBox/WBCGFunctions.h>

#import "WBBezelItemContent.h"

enum {
  kWBBezelItemRadius = 25,
};
static const NSSize kWBBezelItemDefaultSize = {161, 156};

@interface _WBBezelItemView : NSView {
  WBBezelItemContent *wb_item;
}

@property(nonatomic, retain) id content;

@property(nonatomic) NSUInteger radius;

@property(nonatomic) BOOL adjustSize;

- (void)resize;

@end

@interface WBBezelItem ()
- (void)didChangeScreen:(NSNotification *)aNotification;

@property _WBBezelItemView *contentView;

@end

#pragma mark -
@implementation WBBezelItem

- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)styleMask backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation {
  if (self = [super initWithContentRect:contentRect styleMask:styleMask backing:bufferingType defer:deferCreation]) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeScreen:) name:NSWindowDidChangeScreenNotification object:self];
    _WBBezelItemView *content = [[_WBBezelItemView alloc] init];
    self.contentView = content;
    [content release];
  }
  return self;
}

- (instancetype)initWithContent:(id)content {
  if (self = [super init]) {
    [self setContent:content];
  }
  return self;
}

- (instancetype)init {
  return [self initWithContent:nil];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

#pragma mark -
- (void)resize {
  [self.contentView resize];
}

- (_WBBezelItemView *)contentView {
  return [super contentView];
}
- (void)setContentView:(_WBBezelItemView *)contentView {
  [super setContentView:contentView];
}

- (id)content {
  return self.contentView.content;
}
- (void)setContent:(id)content {
  self.contentView.content = content;
}

- (NSUInteger)radius {
  return self.contentView.radius;
}
- (void)setRadius:(NSUInteger)newRadius {
  self.contentView.radius = newRadius;
  [self resize];
}

- (BOOL)adjustSize {
  return self.contentView.adjustSize;
}
- (void)setAdjustSize:(BOOL)flag {
  self.contentView.adjustSize = flag;
  [self resize];
}

- (void)didChangeScreen:(NSNotification *)aNotification {
	[self resize];
}

@end

#pragma mark -
@implementation _WBBezelItemView

- (instancetype)initWithFrame:(NSRect)frameRect {
  if (self = [super initWithFrame:frameRect]) {
    [self setRadius:kWBBezelItemRadius];
  }
  return self;
}

- (void)resize {
  NSRect dim = NSZeroRect;

  if (_adjustSize) {
    dim.size = wb_item ? [wb_item size] : NSZeroSize;
    dim.origin.x = _radius;
    dim.origin.y = _radius;
  } else {
    dim.size = kWBBezelItemDefaultSize;
    NSSize size = wb_item ? [wb_item size] : NSZeroSize;
    dim.origin.x = MAX((NSWidth(dim) - size.width) / 2., 0) + _radius;
    dim.origin.y = MAX((NSHeight(dim) - size.height) / 2., 0) + _radius;
  }

  [wb_item setFrame:dim];

  /* add radius margin */
  dim.size.width += 2 * _radius;
  dim.size.height += 2 * _radius;

  /* convert point dim into pixels */
  dim = [[self window] frameRectForContentRect:dim];
  /* Adjust screen position window */
  NSRect screen = [[NSScreen mainScreen] frame];
  dim.origin.x = (NSWidth(screen) - NSWidth(dim)) / 2.;
  /* Set 140 points from bottom => 140 * scale pixels */
  dim.origin.y = 140;

  [[self window] setFrame:dim display:NO];
}

- (id)content {
  return [wb_item content];
}

- (void)setContent:(id)content {
  if ([wb_item content] != content) {
    [wb_item removeFromSuperview];
    wb_item = [[WBBezelItemContent itemWithContent:content] retain];
    if (wb_item) {
      [self addSubview:wb_item];
      [wb_item release];
    }
    [self resize];
  } else if (nil == wb_item) {
    [self resize];
  }
}

- (void)setAdjustSize:(BOOL)flag {
  if (_adjustSize != flag) {
    _adjustSize = flag;
    [self resize];
  }
}

- (void)drawRect:(NSRect)rect {
  CGRect cgFrame = self.frame;

  CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
  CGContextSaveGState(context);
  CGContextClearRect(context, cgFrame);
  WBCGContextAddRoundRect(context, cgFrame, _radius);

  CGContextSetGrayFillColor(context, 0, .15);
  CGContextFillPath(context);

  CGContextRestoreGState(context);
}

@end
