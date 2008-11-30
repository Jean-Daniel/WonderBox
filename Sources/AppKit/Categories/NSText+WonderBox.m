/*
 *  NSText+WonderBox.m
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

#import WBHEADER(NSText+WonderBox.h)

@implementation NSText (WBExtensions)

- (void)setEnabled:(BOOL)enabled {
  [self setEditable:enabled];
  [self setSelectable:enabled];
  [self setTextColor: enabled ? [NSColor textColor] : [NSColor disabledControlTextColor]];
}

@end
