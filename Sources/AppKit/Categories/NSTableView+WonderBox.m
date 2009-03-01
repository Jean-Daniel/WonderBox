/*
 *  NSTableView+WonderBox.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(NSTableView+WonderBox.h)

@implementation NSTableView (WBExtensions)

- (NSTableColumn *)columnAtIndex:(NSUInteger)idx {
  return [[self tableColumns] objectAtIndex:idx];
}

@end

#pragma mark -
@implementation NSTableView (WBContextualMenuExtension)

- (BOOL)wb_handleMenuForEvent:(NSEvent *)theEvent row:(NSInteger)row {
  if (row != -1) {
    if ([theEvent modifierFlags] & NSCommandKeyMask) {
      //      if ([self isRowSelected:row]) {
      //        [self deselectRow:row];
      //        // Deselect do not trigger contextual menu
      //        return NO;
      //      } else
      if ([self numberOfSelectedRows] == 0 || [self allowsMultipleSelection]) {
        [self selectRow:row byExtendingSelection:YES];
      } else {
        return NO;
      }
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
              range = NSMakeRange(last, row - last + 1);
            } else {
              range = NSMakeRange(row, last - row);
            }
            [self selectRowIndexes:[NSIndexSet indexSetWithIndexesInRange:range] byExtendingSelection:YES];
          }
        }
      }
    } else {
      if (![self isRowSelected:row]) {
        [self selectRow:row byExtendingSelection:NO];
      }
    }
  }
  [self displayIfNeeded];
  return YES;
}

@end
