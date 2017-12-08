/*
 *  WBTableView.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBBase.h>

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WBTableViewDelegate <NSTableViewDelegate>
@optional

- (void)deleteSelectionInTableView:(NSTableView *)aTableView;
// Used for UI validation
- (BOOL)canDeleteSelectionInTableView:(NSTableView *)aTableView;

@end

WB_OBJC_EXPORT
@interface WBTableView : NSTableView

@property (nullable, weak) id <WBTableViewDelegate> delegate;

- (IBAction)delete:(nullable id)sender;

- (void)keyDown:(NSEvent *)theEvent;

@end

// MARK: -

@protocol WBOutlineViewDelegate <NSOutlineViewDelegate>
@optional

- (void)deleteSelectionInOutlineView:(NSOutlineView *)aView;
// Used for UI validation
- (BOOL)canDeleteSelectionInOutlineView:(NSOutlineView *)aView;

@end

WB_OBJC_EXPORT
@interface WBOutlineView : NSOutlineView

@property (nullable, weak) id <WBOutlineViewDelegate> delegate;

- (IBAction)delete:(nullable id)sender;
/*!
 @method    keyDown:
 @abstract  informe the delegate if delete backward or forward is pressed
 and send target doubleAction message if Enter is pressed.
 */
- (void)keyDown:(NSEvent *)theEvent;

@end

NS_ASSUME_NONNULL_END
