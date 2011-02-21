/*
 *  WBNotificationWindow.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBNotificationWindow.h)

#define kWBNotificationWindowDefaultDelay 1

@interface WBNotificationWindow ()
- (void)fadeOut:(NSTimer *)timer;
@end

@implementation WBNotificationWindow

- (id)init {
  return [self initWithContentRect:NSZeroRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
}

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)styleMask backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation {
  if (self = [super initWithContentRect:contentRect styleMask:styleMask | NSNonactivatingPanelMask backing:bufferingType defer:deferCreation]) {
		if ([self respondsToSelector:@selector(setCollectionBehavior:)]) {
			[self setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
		}
    [self setLevel:CGWindowLevelForKey(kCGOverlayWindowLevelKey)];
    [self setBackgroundColor:[NSColor clearColor]];
    [self setExcludedFromWindowsMenu:YES];
    [self setIgnoresMouseEvents:YES];
    [self setReleasedWhenClosed:NO];
    [self setHidesOnDeactivate:NO];
    [self setFloatingPanel:YES];
    [self setHasShadow:NO];
    [self setOneShot:NO];
    [self setCanHide:NO];
    [self setOpaque:NO];
    wb_delay = kWBNotificationWindowDefaultDelay;
  }
  return self;
}

- (void)stopTimer {
  /* Invalidate Timer */
  if (wb_timer) {
    /* wb_timer retain 'self', so it can dealloc it on invalidate */
    [[self retain] autorelease];
    [wb_timer invalidate];
    [wb_timer release];
    wb_timer = nil;
  }
}

- (void)dealloc {
  [self stopTimer];
  [super dealloc];
}

#pragma mark -

- (void)startTimer {
  if (!wb_timer) {
    wb_timer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:wb_delay]
                                        interval:0.05
                                          target:self
                                        selector:@selector(fadeOut:)
                                        userInfo:nil
                                         repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:wb_timer forMode:NSDefaultRunLoopMode];
  }
}

- (void)orderFront:(id)sender {
  [self setAlphaValue:1];
  [super orderFront:sender];
}
- (void)orderFrontRegardless {
  [self setAlphaValue:1];
  [super orderFrontRegardless];
}
- (void)makeKeyAndOrderFront:(id)sender {
  [self setAlphaValue:1];
  /* Invalidate Timer */
  [self stopTimer];
  [super makeKeyAndOrderFront:sender];
}
- (void)orderOut:(id)sender {
  [self stopTimer];
  [super orderOut:sender];
}
- (void)close {
  [self stopTimer];
  [super close];
}

- (IBAction)display:(id)sender {
  if (![self isVisible]) {
    wb_nwFlags.inhibit = 0;
    [self orderFrontRegardless];
    [self startTimer];
  } else {
    if (wb_timer) {
      /* Inhibit else we can have a timer call just after this event */
      wb_nwFlags.inhibit = 1;
      [wb_timer setFireDate:[NSDate dateWithTimeIntervalSinceNow:wb_delay]];
    } else {
      [self startTimer];
    }
    [self orderFrontRegardless];
  }
}

- (void)fadeOut:(NSTimer *)timer {
  if ([self alphaValue] <= 0 || ![self isVisible]) {
    [self close];
  } else if (!wb_nwFlags.inhibit) {
    [self setAlphaValue:[self alphaValue] - 0.05f];
  } else {
    wb_nwFlags.inhibit = 0;
  }
}

- (NSTimeInterval)delay {
  return wb_delay;
}
- (void)setDelay:(NSTimeInterval)newDelay {
  wb_delay = newDelay >= 0 ? newDelay : kWBNotificationWindowDefaultDelay;
}

@end
