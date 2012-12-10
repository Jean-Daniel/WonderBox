/*
 *  NSTabView+WonderBox.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/NSTabView+WonderBox.h>

@implementation NSTabView (WBExtensions)

- (NSInteger)indexOfSelectedTabViewItem {
  return [self indexOfTabViewItem:[self selectedTabViewItem]];
}

@end
