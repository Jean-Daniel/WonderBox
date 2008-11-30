/*
 *  NSArrayController+WonderBox.h
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

@interface NSArrayController (WBExtensions)

- (NSUInteger)count;

- (NSEnumerator *)objectEnumerator;
- (id)objectAtIndex:(NSUInteger)rowIndex;

- (id)selectedObject;
- (BOOL)setSelectedObject:(id)object;

- (void)deleteSelection;
- (void)removeAllObjects;

@end
