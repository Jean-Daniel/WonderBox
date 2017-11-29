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

#import "WBBezelWindow.h"

#pragma mark -
@implementation WBBezelItem {
  WBBezelWindow *_window;
}

+ (NSImageView *)imageView:(NSImage *)anImage {
  NSImageView *view = [[NSImageView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
  view.editable = NO;
  view.enabled = YES;
  view.imageAlignment = NSImageAlignCenter;
  view.imageFrameStyle = NSImageFrameNone;
  view.imageScaling = NSImageScaleProportionallyDown;
  view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  if (anImage)
    view.image = anImage;
  return view;
}

- (instancetype)init {
  return [self initWithImage:nil];
}

- (instancetype)initWithImage:(NSImage *)anImage {
  if (self = [super init]) {
    _window = [WBBezelWindow windowWithImageView:[[self class] imageView:anImage]];
    _window.levelBarVisible = NO;
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

    //    [aView setFrame:CGRectMake(36, 36, 128, 128)];
    //    [_window.contentView addSubview:aView];
  }
  return self;
}

- (instancetype)initWithImage:(NSImage *)anImage level:(CGFloat)aLevel {
  if (self = [self initWithImage:anImage]) {
    _window.levelBarVisible = YES;
    _window.levelValue = aLevel;
  }
  return self;
}

- (IBAction)display:(id)sender {
  [_window display:sender];
}

#pragma mark -
- (NSImage *)image { return _window.imageView.image; }
- (void)setImage:(NSImage *)image { _window.imageView.image = image; }

- (NSTimeInterval)duration { return _window.delay; }
- (void)setDuration:(NSTimeInterval)duration { _window.delay = duration; }

- (BOOL)isLevelBarVisible { return _window.levelBarVisible; }
- (void)setLevelBarVisible:(BOOL)levelBarVisible { _window.levelBarVisible = levelBarVisible; }

- (CGFloat)levelValue { return _window.levelValue; }
- (void)setLevelValue:(CGFloat)levelValue {  _window.levelValue = levelValue; }

@end
