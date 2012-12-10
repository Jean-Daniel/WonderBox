/*
 *  NSButton+WonderBox.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/NSButton+WonderBox.h>

@implementation NSButton (WBImageButton)

- (id)initWithFrame:(NSRect)frame image:(NSImage *)anImage alternateImage:(NSImage *)altImage {
  if (self = [super initWithFrame:frame]) {
    [self setBordered:NO];
    [self setImage:anImage];
    [self setAlternateImage:altImage];
    [self setImagePosition:NSImageOnly];
    [self setFocusRingType:NSFocusRingTypeNone];
    [self setButtonType:NSMomentaryChangeButton];
  }
  return self;
}

@end
