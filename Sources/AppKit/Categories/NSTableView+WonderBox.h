/*
 *  NSTableView+WonderBox.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <Cocoa/Cocoa.h>

@interface NSTableView (WBExtensions)

- (NSRange)visibleRows;
- (NSTableColumn *)columnAtIndex:(NSUInteger)idx;

//- (void)handleSelectEvent:(NSEvent *)rightMouseEvent;

@end
