/*
 *  WBProgressPanel.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBProgressPanel.h)

@implementation WBProgressPanel

//- (id)initWithWindow:(NSWindow *)window {
//  if (self = [super initWithWindow:window]) {
//
//  }
//  return self;
//}

#pragma mark -
- (void)wb_updateMessage:(double )value {
  NSString *timeStr = nil;
//  if (wb_PPFlags.showtime && wb_last > 0) {
    /* time estimation */
//    CFAbsoluteTime elapsed = CFAbsoluteTimeGetCurrent() - wb_start;
//    double progress = value / [uiProgress maxValue];
//    CFAbsoluteTime remaining = (elapsed / progress) - elapsed;
    /* timeStr = 'format time:remaining' */
//  }

  NSString *msg = nil;
  if (WBDelegateHandle(wb_delegate, progressPanel:messageForValue:))
    msg = [wb_delegate progressPanel:self messageForValue:value];

  if (!msg) msg = timeStr;
  else if (timeStr) msg = [NSString stringWithFormat:@"%@ - %@", msg, timeStr];

  [self setMessage:msg ? : @""];
}

- (IBAction)ok:(id)sender {
  [super setModalResultCode:NSOKButton];
  [super close:nil];
}

- (IBAction)cancel:(id)sender {
  [super setModalResultCode:NSCancelButton];
  if (!WBDelegateHandle(wb_delegate, progressPanelShouldCancel:) || [wb_delegate progressPanelShouldCancel:self])
    [super close:nil];
}

- (void)start {
  [uiCancel setTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"WBProgess", WBCurrentBundle(), @"Cancel")];
  [uiCancel setAction:@selector(cancel:)];
  [uiMessage setStringValue:@""];
  /* start time */
  wb_last = 0;
  wb_start = CFAbsoluteTimeGetCurrent();
  [uiProgress startAnimation:nil];
}
- (void)stop {
  [uiProgress stopAnimation:nil];
  [uiCancel setTitle:NSLocalizedStringFromTableInBundle(@"Close", @"WBProgess", WBCurrentBundle(), @"Close")];
  [uiCancel setAction:@selector(ok:)];
  [self wb_updateMessage:[self value]];
}

#pragma mark UI
- (NSImage *)icon { return [uiIcon image]; }
- (void)setIcon:(NSImage *)anIcon { [uiIcon setImage:anIcon]; }

- (NSString *)title { return [uiTitle stringValue]; }
- (void)setTitle:(NSString *)aTitle { [uiTitle setStringValue:aTitle ? : @""]; }

- (NSString *)message { return [uiMessage stringValue]; }
- (void)setMessage:(NSString *)aMessage { [uiMessage setStringValue:aMessage ? : @""]; }

- (NSString *)windowTitle { return [[self window] title]; }
- (void)setWindowTitle:(NSString *)aTitle { [[self window] setTitle:aTitle]; }

#pragma mark Progress
- (double)minValue { return [uiProgress minValue]; }
- (void)setMinValue:(double)minimum { [uiProgress setMinValue:minimum]; }

- (double)maxValue { return [uiProgress maxValue]; }
- (void)setMaxValue:(double)maximum { [uiProgress setMaxValue:maximum]; }

- (BOOL)isIndeterminate { return [uiProgress isIndeterminate]; }
- (void)setIndeterminate:(BOOL)flag { [uiProgress setIndeterminate:flag]; }

- (double)value { return [uiProgress doubleValue]; }
- (void)setValue:(double)aValue {
  [uiProgress setDoubleValue:aValue];
  /* limit string refresh rate: 100 ms */
  if (CFAbsoluteTimeGetCurrent() >= wb_last + wb_rate) {
    [self wb_updateMessage:aValue];
    wb_last = CFAbsoluteTimeGetCurrent();
  }
}
- (void)incrementBy:(double)delta {
  [self setValue:[self value] + delta];
}

@synthesize delegate = wb_delegate;
@synthesize refreshInterval = wb_rate;

//- (BOOL)evaluatesRemainingTime {
//  return wb_PPFlags.showtime;
//}
//- (void)setEvaluatesRemainingTime:(BOOL)flag {
//  WBFlagSet(wb_PPFlags.showtime, flag);
//}

@end
