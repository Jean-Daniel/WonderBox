/*
 *  WBApplicationView.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBApplicationView.h>

#import <WonderBox/WBGeometry.h>
#import <WonderBox/WBApplication.h>

/*
 Recommanded height: 31 pixels.
 */
@implementation WBApplicationView

- (void)dealloc {
  [wb_app release];
  [super dealloc];
}

#pragma mark -
- (WBApplication *)application {
  return wb_app;
}
- (void)setApplication:(WBApplication *)anApp {
  if (wb_app != anApp) {
    [wb_app release];
    wb_app = [anApp retain];

    /* Cache icon */
    NSImage *icon = nil;
    if (wb_app) {
      if ([wb_app path]) {
        icon = [[NSWorkspace sharedWorkspace] iconForFile:[wb_app path]];
        CGFloat scale = WBWindowUserSpaceScaleFactor([self window]);
        if (scale > 1) {
          NSSize size = [icon size];
          size.width = MIN(256, size.width * scale);
          size.height = MIN(256, size.height * scale);
          [icon setSize:size];
        }
      } else if ([wb_app icon]) {
        icon = [wb_app icon];
      } else {
        icon = [self defaultIcon];
      }
    }
    [self setIcon:icon];
    [self setTitle:wb_app ? [wb_app name] : nil];
  }
}

- (void)setApplication:(WBApplication *)anApplication title:(NSString *)aTitle icon:(NSImage *)anIcon {
  SPXSetterRetain(wb_app, anApplication);
  [self setIcon:anIcon];
  /* Should be last => refresh */
  [self setTitle:aTitle];
}

- (NSImage *)defaultIcon {
  return [[NSWorkspace sharedWorkspace] iconForFileType:@"'APPL'"];
}

@end
