/*
 *  NSTableView+WonderBox.h
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
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
