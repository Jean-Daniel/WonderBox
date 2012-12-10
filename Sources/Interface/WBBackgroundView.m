/*
 *	WBBackgroundView.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBBackgroundView.h>

@implementation WBBackgroundView

- (void)dealloc {
  [wb_bgcolor release];
  [super dealloc];
}

- (BOOL)isOpaque {
  return wb_bgcolor != nil && [wb_bgcolor alphaComponent] >= 1;
}

- (NSColor *)backgroundColor {
  return wb_bgcolor;
}
- (void)setBackgroundColor:(NSColor *)bgColor {
  SPXSetterRetain(wb_bgcolor, bgColor);
}

- (void)drawRect:(NSRect)aRect {
  if (wb_bgcolor) {
    NSInteger count = 0;
    const NSRect *rects = NULL;
    [self getRectsBeingDrawn:&rects count:&count];
    [wb_bgcolor setFill];
    while (count > 0) {
      count--;
      [NSBezierPath fillRect:rects[count]];
    }
  }
}

@end
