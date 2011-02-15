/*
 *  WBImageView.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBImageView.h)

@implementation WBImageView

- (id)initWithCoder:(NSCoder *)decoder {
  if (self = [super initWithCoder:decoder]) {
    wb_quality = NSImageInterpolationHigh;
  }
  return self;
}

- (id)initWithFrame:(NSRect)frame {
  if (self = [super initWithFrame:frame]) {
    wb_quality = NSImageInterpolationHigh;
  }
  return self;
}

- (NSImageInterpolation)imageInterpolation {
  return wb_quality;
}
- (void)setImageInterpolation:(NSImageInterpolation)quality {
  wb_quality = quality;
}

- (void)drawRect:(NSRect)aRect {
  NSImageInterpolation quality = [[NSGraphicsContext currentContext] imageInterpolation];
  if (quality != wb_quality)
    [[NSGraphicsContext currentContext] setImageInterpolation:wb_quality];

  [super drawRect:aRect];

  if (quality != wb_quality)
    [[NSGraphicsContext currentContext] setImageInterpolation:quality];
}

@end
