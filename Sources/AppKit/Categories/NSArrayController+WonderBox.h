/*
 *  NSArrayController+WonderBox.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
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
