/*
 *  WBNotificationWindow.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBNotificationWindow.h>

#define kWBNotificationWindowDefaultDelay 1

@interface WBNotificationWindow () <NSAnimationDelegate>

@end

@implementation WBNotificationWindow {
@private
  dispatch_source_t _timer;
  NSViewAnimation *_animation;
}

- (id)init {
  return [self initWithContentRect:NSZeroRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
}

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)styleMask backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation {
  if (self = [super initWithContentRect:contentRect styleMask:styleMask | NSNonactivatingPanelMask backing:bufferingType defer:deferCreation]) {
    self.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces;
    self.level = CGWindowLevelForKey(kCGOverlayWindowLevelKey);
    self.backgroundColor = [NSColor clearColor];
    self.excludedFromWindowsMenu = YES;
    self.ignoresMouseEvents = YES;
    self.releasedWhenClosed = NO;
    self.hidesOnDeactivate = NO;
    self.floatingPanel = YES;
    self.hasShadow = NO;
    self.oneShot = NO;
    self.canHide = NO;
    self.opaque = NO;
    _delay = kWBNotificationWindowDefaultDelay;
  }
  return self;
}

- (void)startAnimation {
  if (_timer || _animation)
    [self stopAnimation];

  // Start Timer
  _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
  dispatch_source_set_timer(_timer, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_delay * NSEC_PER_SEC)), 0 * NSEC_PER_SEC, 1 * NSEC_PER_SEC);
  dispatch_source_set_event_handler(_timer, ^{
    // Start the fadeout animation
    [self fadeOut];
  });
  dispatch_resume(_timer);
}

- (void)stopAnimation {
  /* Invalidate Timer */
  [self cancelTimer];
  if (_animation) {
    [_animation stopAnimation];
    [_animation release];
    _animation = nil;
  }
  // Reset alpha value
  self.alphaValue = 1;
}

- (void)cancelTimer {
  if (_timer) {
    dispatch_cancel(_timer);
    dispatch_release(_timer);
    _timer = nil;
  }
}

- (void)fadeOut {
  [self cancelTimer];
  // Setup the animation
  _animation = [[NSViewAnimation alloc] initWithViewAnimations:@[@{
                                                                   NSViewAnimationTargetKey: self,
                                                                   NSViewAnimationEffectKey: NSViewAnimationFadeOutEffect
                                                                   }]];
  _animation.duration = 1;
  _animation.delegate = self;
  _animation.animationCurve = NSAnimationEaseIn;
  [_animation startAnimation];
}

- (void)animationDidEnd:(NSAnimation *)animation {
  [_animation release];
  _animation = nil;
  [self close];
}

#pragma mark -
- (void)orderFront:(id)sender {
  [self stopAnimation];
  [super orderFront:sender];
}

- (void)orderFrontRegardless {
  [self setAlphaValue:1];
  [super orderFrontRegardless];
}

- (void)orderOut:(id)sender {
  [self stopAnimation];
  [super orderOut:sender];
}

- (void)close {
  [self stopAnimation];
  [super close];
}

- (IBAction)display:(id)sender {
  [self orderFrontRegardless];
  [self startAnimation];
}

- (void)setDelay:(NSTimeInterval)newDelay {
  _delay = _delay >= 0 ? _delay : kWBNotificationWindowDefaultDelay;
}

@end
