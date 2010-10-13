/*
 *  WBTableView.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBBase.h)

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
@protocol WBTableViewDelegate;
#endif

WB_CLASS_EXPORT
@interface WBTableView : NSTableView {
@private
  struct _wb_tvFlags {
    unsigned int edit:1;
    unsigned int editOnClick:1;
    unsigned int reserved:29;
  } wb_tvFlags;
  NSHashTable *wb_noPadding;
}

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
- (id<WBTableViewDelegate>)delegate;
- (void)setDelegate:(id<WBTableViewDelegate>)delegate;
#endif

- (IBAction)delete:(id)sender;
- (void)keyDown:(NSEvent *)theEvent;
- (void)editColumn:(NSInteger)column row:(NSInteger)row;

- (void)setPadding:(BOOL)flag forTableColumn:(NSString *)columnIdentifier;

/* Should edit next cell after cell edition */
- (void)setContinueEditing:(BOOL)flag;

@end

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
@protocol WBTableViewDelegate <NSTableViewDelegate>
@optional
#else
@interface NSObject (WBTableViewDelegate)
#endif

- (void)deleteSelectionInTableView:(NSTableView *)aTableView;
// Used for UI validation
- (BOOL)canDeleteSelectionInTableView:(NSTableView *)aTableView;

@end
