/*
 *  WBTableView.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBTableView.h>

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

WB_OBJC_EXPORT
@interface WBTableViewLegacy : WBTableView

- (void)editColumn:(NSInteger)column row:(NSInteger)row;

- (void)setPadding:(BOOL)flag forTableColumn:(NSString *)columnIdentifier;

/* Should edit next cell after cell edition */
- (void)setContinueEditing:(BOOL)flag;

@end

// MARK: -
@protocol WBOutlineViewLegacyDelegate <NSOutlineViewDelegate>
@optional
// returns NO to prevent outline cell drawing. Used in Source List.
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldDrawOutlineCellAtRow:(NSInteger)row;
@end

WB_OBJC_EXPORT
@interface WBOutlineViewLegacy : WBOutlineView

@property (nullable, weak) id <WBOutlineViewLegacyDelegate> delegate;

- (void)editColumn:(NSInteger)column item:(id)anItem;

- (void)setPadding:(BOOL)flag forTableColumn:(NSString *)columnIdentifier;

/* Should edit next cell after cell edition */
- (void)setContinueEditing:(BOOL)flag;

@end

NS_ASSUME_NONNULL_END
