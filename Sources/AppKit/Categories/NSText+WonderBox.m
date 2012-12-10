/*
 *  NSText+WonderBox.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/NSText+WonderBox.h>

@implementation NSText (WBExtensions)

- (void)setEnabled:(BOOL)enabled {
  [self setEditable:enabled];
  [self setSelectable:enabled];
  [self setTextColor: enabled ? [NSColor textColor] : [NSColor disabledControlTextColor]];
}

@end
