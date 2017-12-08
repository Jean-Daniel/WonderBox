/*
 *  NSArrayController+WonderBox.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/NSArrayController+WonderBox.h>

@implementation NSArrayController (WBExtensions)

//- (NSUInteger)count {
//  return [[self arrangedObjects] count];
//}

//- (NSEnumerator *)objectEnumerator {
//  return [[self content] objectEnumerator];
//}

- (id)objectAtArrangedObjectIndex:(NSUInteger)rowIndex {
  return [[self arrangedObjects] objectAtIndex:rowIndex];
}

- (id)selectedObject {
  return self.selectedObjects.firstObject;
}

- (BOOL)setSelectedObject:(id)object {
  return [self setSelectedObjects:@[object]];
}

- (void)deleteSelection {
  [self removeObjects:self.selectedObjects];
}

- (void)removeAllObjects {
  id content = [self content];
  if (content)
    [self removeObjects:content];
}

@end
