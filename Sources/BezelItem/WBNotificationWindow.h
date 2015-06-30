/*
 *  WBNotificationWindow.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBBase.h>

#import <Cocoa/Cocoa.h>

WB_OBJC_EXPORT
@interface WBNotificationWindow : NSPanel {
  @private
  NSTimer *wb_timer;
  NSTimeInterval wb_delay;

  struct _wb_nwFlags {
    unsigned int inhibit:1;
    unsigned int reserved:31;
  } wb_nwFlags;
}

- (IBAction)display:(id)sender;

- (NSTimeInterval)delay;
- (void)setDelay:(NSTimeInterval)newDelay;

@end
