/*
 *  NSTableView+WonderBox.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/NSTableView+WonderBox.h>

@implementation NSTableView (WBExtensions)

- (NSRange)visibleRows {
  NSScrollView *scroll = [self enclosingScrollView];
  if (!scroll) return NSMakeRange(0, 0);
  return [self rowsInRect:[scroll documentVisibleRect]];
}

- (NSTableColumn *)columnAtIndex:(NSUInteger)idx {
  return [[self tableColumns] objectAtIndex:idx];
}

- (void)wb_selectRows:(NSIndexSet *)rows byExtendingSelection:(BOOL)extends {
  // if this line is not the only one selected
  if ([[self selectedRowIndexes] isEqualToIndexSet:rows])
    return;

  SEL shouldSelect, selectionIndexes;
  bool outlineView = [self isKindOfClass:[NSOutlineView class]];
  if (outlineView) {
    shouldSelect = @selector(outlineView:shouldSelectItem:);
    selectionIndexes = @selector(outlineView:selectionIndexesForProposedSelection:);
  } else {
    shouldSelect = @selector(tableView:shouldSelectRow:);
    selectionIndexes = @selector(tableView:selectionIndexesForProposedSelection:);
  }

  if ([[self delegate] respondsToSelector:selectionIndexes]) {
    rows = [[self delegate] performSelector:selectionIndexes
                                 withObject:self
                                 withObject:rows];
    if (rows)
      [self selectRowIndexes:rows byExtendingSelection:extends];
  } else if ([[self delegate] respondsToSelector:shouldSelect]) {
    for (NSUInteger row = [rows firstIndex]; row != NSNotFound;
         row = [rows indexGreaterThanIndex:row]) {

      BOOL add;
      if (outlineView)
        add = [[(NSOutlineView *)self delegate] outlineView:(NSOutlineView *)self
                                           shouldSelectItem:[(NSOutlineView *)self itemAtRow:(NSInteger)row]];
      else
        add = [[self delegate] tableView:self shouldSelectRow:(NSInteger)row];

      if (add) {
        [self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:extends];
        extends = true; // should append now
      }
    }
  } else {
    // no delegate filter, select the row
    [self selectRowIndexes:rows byExtendingSelection:extends];
  }
}

- (void)wb_selectSingleRow:(NSInteger)aRow {
  if (aRow >= 0)
    [self wb_selectRows:[NSIndexSet indexSetWithIndex:(NSUInteger)aRow] byExtendingSelection:NO];
}

- (void)wb_addRowToSelection:(NSInteger)aRow {
  if (aRow >= 0)
    [self wb_selectRows:[NSIndexSet indexSetWithIndex:(NSUInteger)aRow] byExtendingSelection:YES];
}

- (void)handleSelectEvent:(NSEvent *)theEvent {
  // support only mouse down
  if ([theEvent type] != NSRightMouseDown &&
      [theEvent type] != NSLeftMouseDown) return;

  NSInteger row = [self rowAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
  if (row < 0) return;

  if ([theEvent modifierFlags] & NSCommandKeyMask) {
    // 1. cmd + click
    // add row to selection if multi selection allowed,
    // or change selection if not.
    if (![self allowsMultipleSelection] || 0 == [self numberOfSelectedRows]) {
      [self wb_selectSingleRow:row];
    } else if ([self isRowSelected:row]) {
      // should be deselect it, but it make contextual menu
      // on multiple items harder
      // [self deselectRow:row];
    } else {
      // Add row to the current selection
      [self wb_addRowToSelection:row];
    }
  } else if ([theEvent modifierFlags] & NSShiftKeyMask) {
    // 2. shift + click
    if (![self allowsMultipleSelection] || 0 == [self numberOfSelectedRows]) {
      [self wb_selectSingleRow:row];
    } else {
      // Should be 'select all rows between nearest selected and row'
      NSInteger last = [self selectedRow];
      if (last >= 0 && last != row) {
        NSRange range;
        if (last < row) {
          range = NSMakeRange((NSUInteger)last, (NSUInteger)(row - last) + 1);
        } else {
          range = NSMakeRange((NSUInteger)row, (NSUInteger)(last - row) + 1);
        }
        [self wb_selectRows:[NSIndexSet indexSetWithIndexesInRange:range] byExtendingSelection:NO];
      }
    }
  } else {
    // neither cmd nor shift
    [self wb_selectSingleRow:row];
  }
  // refresh display
  [self displayIfNeeded];
}

- (BOOL)wb_handleMenuForEvent:(NSEvent *)theEvent row:(NSInteger)row {
  if (row >= 0) {
    if ([theEvent modifierFlags] & NSCommandKeyMask) {
      //      if ([self isRowSelected:row]) {
      //        [self deselectRow:row];
      //        // Deselect do not trigger contextual menu
      //        return NO;
      //      } else
      if ([self numberOfSelectedRows] == 0 || [self allowsMultipleSelection]) {
        //if (WBDelegateHandle([self delegate],
        [self selectRowIndexes:[NSIndexSet indexSetWithIndex:(NSUInteger)row] byExtendingSelection:YES];
      }
      return NO;
    } else if ([theEvent modifierFlags] & NSShiftKeyMask) {
      if (![self isRowSelected:row]) {
        if ([self numberOfSelectedRows] == 0) {
          // nothing
        } else if (![self allowsMultipleSelection]) {
          // Deselect do not trigger contextual menu
          return NO;
        } else {
          // Should be 'select all rows between nearest selected and row'
          NSInteger last = [self selectedRow];
          if (last != -1) {
            NSRange range;
            if (last < row) {
              range = NSMakeRange((NSUInteger)last, (NSUInteger)(row - last) + 1);
            } else {
              range = NSMakeRange((NSUInteger)row, (NSUInteger)(last - row));
            }
            [self selectRowIndexes:[NSIndexSet indexSetWithIndexesInRange:range] byExtendingSelection:YES];
          }
        }
      }
    } else {
      if (![self isRowSelected:row])
        [self selectRowIndexes:[NSIndexSet indexSetWithIndex:(NSUInteger)row] byExtendingSelection:NO];
    }
  }
  [self displayIfNeeded];
  return YES;
}

@end

