/*
 *  WBApplicationView.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBImageAndTextView.h)

@class WBApplication;
WB_OBJC_EXPORT
@interface WBApplicationView : WBImageAndTextView {
  @private
  WBApplication *wb_app;
}

- (WBApplication *)application;
- (void)setApplication:(WBApplication *)anApp;

- (void)setApplication:(WBApplication *)anApplication title:(NSString *)aTitle icon:(NSImage *)anIcon;

/* Protected */
- (NSImage *)defaultIcon;

@end
