/*
 *  WBSplitview.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBSplitview.h>
#import <WonderBox/NSImage+WonderBox.h>

@implementation WBSplitView

- (void)wb_init {
  wb_thickness = 5;
}

- (NSImage *)wb_centerDividerImage {
  static NSImage *WBCenterDividerImage = nil;
  if (!WBCenterDividerImage) {
    WBCenterDividerImage = [NSImage imageNamed:@"WBSplitDot" inBundle:SPXBundleForClass([WBSplitView class])];
  }
  return WBCenterDividerImage;
}

- (NSImage *)wb_verticalDividerImage {
  static NSImage *WBVerticalDividerImage = nil;
  if (!WBVerticalDividerImage) {
    WBVerticalDividerImage = [NSImage imageNamed:@"WBVSplitBar" inBundle:SPXBundleForClass([WBSplitView class])];
  }
  return WBVerticalDividerImage;
}

- (NSImage *)wb_horizontalDividerImage {
  static NSImage *WBHorizontalDividerImage = nil;
  if (!WBHorizontalDividerImage) {
    WBHorizontalDividerImage = [NSImage imageNamed:@"WBHSplitBar" inBundle:SPXBundleForClass([WBSplitView class])];
  }
  return WBHorizontalDividerImage;
}


- (id)initWithCoder:(NSCoder *)aCoder {
  if (self = [super initWithCoder:aCoder]) {
    [self wb_init];
  }
  return self;
}

- (id)initWithFrame:(NSRect)frame {
  if (self = [super initWithFrame:frame]) {
    [self wb_init];
  }
  return self;
}

- (CGFloat)defaultDividerThickness {
  return [super dividerThickness];
}

- (CGFloat)dividerThickness {
  return wb_thickness > 0 ? wb_thickness : [self defaultDividerThickness];
}

- (void)setDividerThickness:(CGFloat)thickness {
  wb_thickness = thickness;
}

- (void)setBorders:(NSUInteger)mask {
  wb_svFlags.border = (unsigned int)mask;
}

#pragma mark -
#pragma mark Custom Drawing
- (BOOL)isGray {
  return wb_svFlags.gray;
}
- (void)setGray:(BOOL)flag {
  SPXFlagSet(wb_svFlags.gray, flag);
}

- (void)drawDividerInRect:(NSRect)aRect {
  if ([self isGray]) {
    NSPoint center;
    NSRect backrect = aRect;
    NSImage *background = nil;
    NSImage *dot = [self wb_centerDividerImage];
    if ([self isVertical]) {
      background = [self wb_verticalDividerImage];
      center.x = NSMinX(backrect);
      center.y = (NSHeight(backrect) + [dot size].height) / 2;
      if (wb_svFlags.border & kWBBorderLeft) {
        // FIXME: userspace scale factor
        center.x += 0.5;
        backrect.origin.x += 1;
        backrect.size.width -= 1;
      }
      if (wb_svFlags.border & kWBBorderRight) {
        center.x -= 0.5;
        backrect.size.width -= 1;
      }
    } else {
      background = [self wb_horizontalDividerImage];
      center.x = (NSWidth(backrect) + [dot size].width) / 2;
      center.y = NSMaxY(backrect);
      if (wb_svFlags.border & kWBBorderBottom) {
        center.y += 0.5;
        backrect.origin.y += 1;
        backrect.size.height -= 1;
      }
      if (wb_svFlags.border & kWBBorderTop) {
        center.y -= 0.5;
        backrect.size.height -= 1;
      }
    }
    /* Draw background */
    if (background) {
      NSRect src = NSZeroRect;
      src.size = [background size];
      [background drawInRect:backrect fromRect:src operation:NSCompositingOperationSourceOver fraction:1];
    } else {
      CGContextSetGrayFillColor([[NSGraphicsContext currentContext] graphicsPort], .933, 1);
      [NSBezierPath fillRect:aRect];
    }
    /* Draw the center image */
    center.x = round(center.x);
    center.y = round(center.y);
    NSRect from = { NSZeroPoint, [dot size] };
    NSRect dest = { center, from.size };
    [dot drawInRect:dest fromRect:from
          operation:NSCompositingOperationSourceOver
           fraction:1 respectFlipped:YES hints:nil];
  } else {
    [super drawDividerInRect:aRect];
  }
  if (wb_svFlags.border) {
    [[NSColor lightGrayColor] setStroke];
    if (wb_svFlags.border & kWBBorderLeft) {
      [NSBezierPath strokeLineFromPoint:NSMakePoint(0.5, 0) toPoint:NSMakePoint(0.5, NSMaxY(aRect))];
    }
    if (wb_svFlags.border & kWBBorderTop) {
      [NSBezierPath strokeLineFromPoint:NSMakePoint(0, NSMaxY(aRect)) toPoint:NSMakePoint(NSMaxX(aRect), NSMaxY(aRect))];
    }
    if (wb_svFlags.border & kWBBorderRight) {
      [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMaxX(aRect) - 0.5, 0) toPoint:NSMakePoint(NSMaxX(aRect) - 0.5, NSMaxY(aRect))];
    }
    if (wb_svFlags.border & kWBBorderBottom) {
      [NSBezierPath strokeLineFromPoint:NSZeroPoint toPoint:NSMakePoint(NSMaxX(aRect), 0)];
    }
  }
}

@end
