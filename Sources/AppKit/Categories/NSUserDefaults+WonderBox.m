/*
 *  NSUserDefaults+WonderBox.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/NSUserDefaults+WonderBox.h>

@implementation NSUserDefaults(WBUserDefaultsColor)

- (void)setColor:(NSColor *)aColor forKey:(NSString *)aKey {
  NSData *theData = [NSKeyedArchiver archivedDataWithRootObject:aColor];
  [self setObject:theData forKey:aKey];
}

- (NSColor *)colorForKey:(NSString *)aKey {
  NSColor *theColor = nil;
  NSData *theData = [self dataForKey:aKey];
  if (theData != nil)
    theColor = (NSColor *)[NSKeyedUnarchiver unarchiveObjectWithData:theData];
  return theColor;
}

@end
