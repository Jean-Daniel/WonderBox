/*
 *  WBTableDataSource.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBBase.h>

#import <Cocoa/Cocoa.h>

typedef BOOL (^WBFilterBlock)(NSString *, id);

WB_OBJC_EXPORT
@interface WBTableDataSource : NSArrayController

#pragma mark -
@property(nonatomic, copy) NSComparator comparator;

#pragma mark -
- (IBAction)search:(id)sender;

@property(nonatomic, copy) NSString *searchString;

@property(nonatomic, copy) WBFilterBlock filterBlock;

@end
