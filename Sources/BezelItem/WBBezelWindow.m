/*
 *  WBBezelWindow.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2015 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import "WBBezelWindow.h"

#import "WBBezelLegacy.h"
#import "WBBezelVisualEffect.h"

@implementation WBBezelWindow

+ (instancetype)windowWithImageView:(NSImageView *)aView {
  Class cls = [WBVisualEffectBezelWindow available] ? [WBVisualEffectBezelWindow class] : [WBLegacyBezelWindow class];
  return [[cls alloc] initWithImageView:aView];
}

- (instancetype)initWithImageView:(NSImageView *)aView {
  NSAssert([self class] != [WBBezelWindow class], @"Use +windowWithContentView: to create instance");
  if (self = [self initWithContentRect:CGRectMake(0, 0, 200, 200)
                             styleMask:NSBorderlessWindowMask
                               backing:NSBackingStoreBuffered defer:YES]) {
    _imageView = aView;
  }
  return self;
}

@end
