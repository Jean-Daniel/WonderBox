/*
 *  WBIconView.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBIconView.h)

#include <Carbon/Carbon.h>

@implementation WBIconView

- (void)dealloc {
  if (wb_icon)
    ReleaseIconRef(wb_icon);
  [super dealloc];
}

- (IconRef)iconRef {
  return wb_icon;
}

- (void)setIconRef:(IconRef)anIcon {
  if (anIcon != wb_icon) {
    if (wb_icon)
      ReleaseIconRef(wb_icon);
    wb_icon = anIcon;
    if (wb_icon)
      AcquireIconRef(wb_icon);
    [self setNeedsDisplay:YES];
  }
}

- (void)setSystemIcon:(OSType)icon {
  IconRef ref = NULL;
  if (noErr == GetIconRef(kOnSystemDisk, kSystemIconsCreator, icon, &ref)) {
    [self setIconRef:ref];
    ReleaseIconRef(ref);
  }
}

- (void)drawRect:(NSRect)aRect {
  if (wb_icon) {
    CGRect rect = NSRectToCGRect([self bounds]);
    CGContextRef ctxt = [[NSGraphicsContext currentContext] graphicsPort];
    PlotIconRefInContext(ctxt,
                         &rect,
                         kAlignAbsoluteCenter,
                         kTransformNone,
                         NULL,
                         kPlotIconRefNormalFlags,
                         wb_icon);
  }
}

@end
