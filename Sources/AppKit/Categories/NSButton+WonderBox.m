/*
 *  WBAppKitExtensions.m
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

#import WBHEADER(NSButton+WonderBox.h)

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
