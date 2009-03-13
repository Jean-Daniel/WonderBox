/*
 *	WBTableView.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

WB_CLASS_EXPORT
@interface WBTableView : NSTableView {
  @private
  struct _wb_tvFlags {
    unsigned int edit:1;
    unsigned int reserved:31;
  } wb_tvFlags;
  NSHashTable *wb_noPadding;
}

- (IBAction)delete:(id)sender;
- (void)keyDown:(NSEvent *)theEvent;
- (void)editColumn:(NSInteger)column row:(NSInteger)row;

- (void)setPadding:(BOOL)flag forTableColumn:(NSString *)columnIdentifier;

/* Should edit next cell after cell edition */
- (void)setContinueEditing:(BOOL)flag;

@end

@interface NSObject (WBTableViewDelegate)

- (void)deleteSelectionInTableView:(NSTableView *)aTableView;
- (BOOL)canDeleteSelectionInTableView:(NSTableView *)aTableView;
- (NSMenu *)tableView:(NSTableView *)aTableView menuForRow:(NSInteger)row event:(NSEvent *)theEvent;

@end
