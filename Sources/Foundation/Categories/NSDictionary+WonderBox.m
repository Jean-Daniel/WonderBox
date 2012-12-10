/*
 *  NSDictionary+WonderBox.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/NSDictionary+WonderBox.h>

@implementation NSMutableDictionary (WBExtensions)

- (void)setObject:(id)anObject forKeys:(NSArray *)keys {
  NSUInteger count = [keys count];
  while (count-- > 0) {
    [self setObject:anObject forKey:[keys objectAtIndex:count]];
  }
}

@end
