/*
 *  WBOutlineView.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBBase.h>

#import <Cocoa/Cocoa.h>

@protocol WBOutlineViewDelegate;

WB_OBJC_EXPORT
@interface WBOutlineView : NSOutlineView {
@private
  struct _wb_ovFlags {
    unsigned int edit:1;
    unsigned int editOnClick:1;
    unsigned int drawOutline:1;
    unsigned int reserved:29;
  } wb_ovFlags;
  NSHashTable *wb_noPadding;
}

- (id<WBOutlineViewDelegate>)delegate;
- (void)setDelegate:(id<WBOutlineViewDelegate>)aDelegate;

- (IBAction)delete:(id)sender;
/*!
 @method    keyDown:
 @abstract  informe the delegate if delete backward or forward is pressed
 and send target doubleAction message if Enter is pressed.
 */
- (void)keyDown:(NSEvent *)theEvent;
- (void)editColumn:(NSInteger)column item:(id)anItem;

- (void)setPadding:(BOOL)flag forTableColumn:(NSString *)columnIdentifier;

/* Should edit next cell after cell edition */
- (void)setContinueEditing:(BOOL)flag;

@end

@protocol WBOutlineViewDelegate <NSOutlineViewDelegate>
@optional

- (void)deleteSelectionInOutlineView:(NSOutlineView *)aView;
// Used for UI validation
- (BOOL)canDeleteSelectionInOutlineView:(NSOutlineView *)aView;

// returns NO to prevent outline cell drawing. Used in Source List.
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldDrawOutlineCellAtRow:(NSInteger)row;

@end

