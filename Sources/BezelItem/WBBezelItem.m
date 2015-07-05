/*
 *  WBBezelItem.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2015 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBBezelItem.h>

enum {
  kWBBezelItemRadius = 25,
};

@interface WBBezelItem ()
@property(nonatomic, readonly, strong) WBNotificationWindow *window;
@property(nonatomic, readonly, assign) NSView *contentView;
@end

@interface _WBSimpleBezelWindow : WBNotificationWindow

@end

@interface _WBVisualEffectBezelWindow : WBNotificationWindow
- (NSImage *)_cornerMask;
- (float)_backdropBleedAmount;
@end

#pragma mark -
@implementation WBBezelItem {
  BOOL _customView;
}

+ (NSImageView *)imageView:(NSImage *)anImage {
  NSImageView *view = [[[NSImageView alloc] initWithFrame:NSMakeRect(36, 36, 128, 128)] autorelease];
  view.editable = NO;
  view.enabled = YES;
  view.imageAlignment = NSImageAlignCenter;
  view.imageFrameStyle = NSImageFrameNone;
  view.imageScaling = NSImageScaleProportionallyUpOrDown;
  if (anImage)
    view.image = anImage;
  return view;
}

- (instancetype)initWithView:(NSView *)aView {
  if (self = [super init]) {
    NSOperatingSystemVersion vers = [NSProcessInfo processInfo].operatingSystemVersion;

    // _WBVisualEffectBezelWindow relies on private API, so enable it only on tested system.
    Class wclass = vers.minorVersion == 10 ? [_WBVisualEffectBezelWindow class] : [_WBSimpleBezelWindow class];
    _window = [[wclass alloc] initWithContentRect:NSMakeRect(0, 0, 200, 200)
                                        styleMask:NSBorderlessWindowMask | NSNonactivatingPanelMask
                                          backing:NSBackingStoreBuffered defer:YES];
    _window.duration = .5;

    // Position window
    NSRect wrect = _window.frame;
    NSRect screen = [_window.screen frame];
    /* Adjust screen position window */
    wrect.origin.x = (NSWidth(screen) - NSWidth(wrect)) / 2;
    /* Set 140 points from bottom => 140 */
    wrect.origin.y = 140;
    wrect = [_window.screen backingAlignedRect:wrect options:NSAlignAllEdgesOutward];

    [_window setFrame:wrect display:NO];

    [aView setFrame:NSMakeRect(36, 36, 128, 128)];
    [_window.contentView addSubview:aView];
    _contentView = aView;
    _customView = YES;
  }
  return self;
}

- (instancetype)initWithImage:(NSImage *)anImage {
  if (self = [self initWithView:[[self class] imageView:anImage]]) {
    _customView = NO;
  }
  return self;
}

- (instancetype)init {
  return [self initWithImage:nil];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

#pragma mark -
- (NSView *)view {
  return _customView ? _contentView : nil;
}

- (void)setView:(NSView *)view {
  [_contentView removeFromSuperview];
  [view setFrame:NSMakeRect(36, 36, 128, 128)];
  [_window.contentView addSubview:view];
  _contentView = view;
  _customView = YES;
}

- (NSImage *)image {
  if (_customView)
    return nil;
  return ((NSImageView *)_contentView).image;
}

- (void)setImage:(NSImage *)image {
  if (!_customView) {
    ((NSImageView *)_contentView).image = image;
  } else {
    [_contentView removeFromSuperview];
    _contentView = [[self class] imageView:image];
    [_window.contentView addSubview:_contentView];
    _customView = NO;
  }
}

- (NSTimeInterval)delay {
  return _window.delay;
}

- (void)setDelay:(NSTimeInterval)delay {
  _window.delay = delay;
}

- (IBAction)display:(id)sender {
  [_window display:sender];
}

@end

// MARK: -

@interface _WBSimpleBezelView : NSView


@end

@implementation _WBSimpleBezelView

- (void)drawRect:(NSRect)rect {
  NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:self.frame xRadius:kWBBezelItemRadius yRadius:kWBBezelItemRadius];
  [[NSColor colorWithCalibratedWhite:0 alpha:.15] setFill];
  [path fill];
}

@end

@implementation _WBSimpleBezelWindow

- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
  if (self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag]) {
    self.contentView = [[[_WBSimpleBezelView alloc] initWithFrame:NSMakeRect(0, 0, 200, 200)] autorelease];
  }
  return self;
}

@end

// MARK: -

@interface NSVisualEffectView (WBPrivate)
- (void)_setInternalMaterialType:(long long)arg1;
@end

static
NSImage *_bezelWindowMask() {
  NSImage *img = [NSImage imageWithSize:NSMakeSize(37, 37) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
    [[NSColor blackColor] setFill];
    [[NSBezierPath bezierPathWithOvalInRect:dstRect] fill];
    return YES;
  }];
  img.capInsets = NSEdgeInsetsMake(18, 18, 18, 18);
  img.resizingMode = NSImageResizingModeTile;
  return img;
}

@implementation _WBVisualEffectBezelWindow {
  NSImage *_corners;
}

- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
  if (self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag]) {
    NSVisualEffectView *v = [[NSVisualEffectView alloc] initWithFrame:contentRect];
    v.state = NSVisualEffectStateActive;
    v.maskImage = _bezelWindowMask();
    // Internal Material Type for Bezel item is 0
    [v _setInternalMaterialType:0];
    self.contentView = v;

    _corners = [_bezelWindowMask() retain];
    // NSWindow requires stretching mode
    _corners.resizingMode = NSImageResizingModeStretch;
  }
  return self;
}

- (NSImage *)_cornerMask {
  return _corners;
}

// I don't have any idea what it is about, but this is how BezelUI Server works.
- (float)_backdropBleedAmount { return 0; }


@end

