/*
 *  NSArray+WonderBox.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/NSArray+WonderBox.h>

@implementation NSArray (WBExtensions)

- (BOOL)containsObjectIdenticalTo:(id)anObject {
  return [self indexOfObjectIdenticalTo:anObject] != NSNotFound;
}

@end
