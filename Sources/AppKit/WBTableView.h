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

@protocol WBTableViewDelegate;

WB_OBJC_EXPORT
@interface WBTableView : NSTableView {
@private
  struct _wb_tvFlags {
    unsigned int edit:1;
    unsigned int editOnClick:1;
    unsigned int reserved:30;
  } wb_tvFlags;
  NSHashTable *wb_noPadding;
}

- (id<WBTableViewDelegate>)delegate;
- (void)setDelegate:(id<WBTableViewDelegate>)delegate;

- (IBAction)delete:(id)sender;
- (void)keyDown:(NSEvent *)theEvent;
- (void)editColumn:(NSInteger)column row:(NSInteger)row;

- (void)setPadding:(BOOL)flag forTableColumn:(NSString *)columnIdentifier;

/* Should edit next cell after cell edition */
- (void)setContinueEditing:(BOOL)flag;

@end

@protocol WBTableViewDelegate <NSTableViewDelegate>
@optional

- (void)deleteSelectionInTableView:(NSTableView *)aTableView;
// Used for UI validation
- (BOOL)canDeleteSelectionInTableView:(NSTableView *)aTableView;

@end
