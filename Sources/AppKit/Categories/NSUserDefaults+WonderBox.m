/*
 *  NSUserDefaults+WonderBox.m
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

#import WBHEADER(NSUserDefaults+WonderBox.h)

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
