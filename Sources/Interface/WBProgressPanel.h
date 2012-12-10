/*
 *  WBProgressPanel.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBWindowController.h>

@protocol WBProgressPanelDelegate;

WB_OBJC_EXPORT
@interface WBProgressPanel : WBWindowController {
@private
  IBOutlet NSButton *uiCancel;
  IBOutlet NSImageView *uiIcon;
  IBOutlet NSTextField *uiTitle;
  IBOutlet NSTextField *uiMessage;
  IBOutlet NSProgressIndicator *uiProgress;

  NSTimeInterval wb_rate;
  CFAbsoluteTime wb_last;
  CFAbsoluteTime wb_start;
  __unsafe_unretained id<WBProgressPanelDelegate> wb_delegate;

//  struct _wb_PPFlags {
//    unsigned int showtime:1;
//    unsigned int reserved:31;
//  } wb_PPFlags;
}

@property(nonatomic, assign) id<WBProgressPanelDelegate> delegate;

/* configuration */
@property(nonatomic, retain) NSImage *icon;

@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *message;

@property(nonatomic, copy) NSString *windowTitle;

@property(nonatomic, getter=isIndeterminate) BOOL indeterminate;

//- (BOOL)evaluatesRemainingTime;
//- (void)setEvaluatesRemainingTime:(BOOL)flag;

/* progress */
@property(nonatomic) double minValue;
@property(nonatomic) double maxValue;

@property(nonatomic) double value;
- (void)incrementBy:(double)delta;

- (IBAction)ok:(id)sender;
- (IBAction)cancel:(id)sender;

- (void)start;
- (void)stop;

/* limits message refresh interval */
@property(nonatomic) NSTimeInterval refreshInterval;

@end

@protocol WBProgressPanelDelegate <NSObject>

@optional
- (BOOL)progressPanelShouldCancel:(WBProgressPanel *)aPanel;
- (NSString *)progressPanel:(WBProgressPanel *)aPanel messageForValue:(double)value;

@end
