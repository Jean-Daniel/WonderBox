/*
 *  NSImageView+WonderBox.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/NSImageView+WonderBox.h>

@implementation NSImageView (WBSimpleImageView)

- (id)initWithImage:(NSImage *)image {
  if (self = [super init]) {
    [self setImage:image];
    if (image)
      [self setFrameSize:[image size]];
    [self setImageScaling:NSScaleNone];
    [self setImageFrameStyle:NSImageFrameNone];
    [self setImageAlignment:NSImageAlignCenter];
  }
  return self;
}

@end
