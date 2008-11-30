/*
 *  NSArrayController+WonderBox.m
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

#import WBHEADER(NSArrayController+WonderBox.h)

@implementation NSArrayController (WBExtensions)

- (NSUInteger)count {
  return [[self arrangedObjects] count];
}

- (NSEnumerator *)objectEnumerator {
  return [[self content] objectEnumerator];
}

- (id)objectAtIndex:(NSUInteger)rowIndex {
  return [[self arrangedObjects] objectAtIndex:rowIndex];
}

- (id)selectedObject {
  id selection = [self selectedObjects];
  if ([selection count]) {
    return [selection objectAtIndex:0];
  }
  return nil;
}

- (BOOL)setSelectedObject:(id)object {
  return [self setSelectedObjects:[NSArray arrayWithObject:object]];
}

- (void)deleteSelection {
  [self removeObjects:[self selectedObjects]];
}

- (void)removeAllObjects {
  [self removeObjects:[self content]];
}

@end
