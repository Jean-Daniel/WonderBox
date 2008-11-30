/*
 *  NSTabView+WonderBox.m
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

#import WBHEADER(NSTabView+WonderBox.h)

@implementation NSTabView (WBExtensions)

- (NSInteger)indexOfSelectedTabViewItem {
  return [self indexOfTabViewItem:[self selectedTabViewItem]]; 
}

@end
