/*
 *  NSTableView+WonderBox.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#pragma mark -
@interface NSTableView (WBExtensions)

- (NSTableColumn *)columnAtIndex:(NSUInteger)idx;

@end

#pragma mark -
#pragma mark Internal
@interface NSTableView (WBContextualMenuExtension)

- (BOOL)wb_handleMenuForEvent:(NSEvent *)theEvent row:(NSInteger)row;

@end
