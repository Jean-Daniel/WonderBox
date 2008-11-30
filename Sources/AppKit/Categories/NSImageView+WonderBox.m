/*
 *  WBAppKitExtensions.m
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

#import WBHEADER(NSImageView+WonderBox.h)

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
