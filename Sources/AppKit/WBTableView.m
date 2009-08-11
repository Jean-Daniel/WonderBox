/*
 *	WBTableView.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBTableView.h)
#import WBHEADER(NSTableView+WonderBox.h)

@implementation WBTableView

- (void)dealloc {
  if (wb_noPadding)
    NSFreeHashTable(wb_noPadding);
  [super dealloc];
}

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)flag {
  return flag ? NSDragOperationEvery : NSDragOperationNone;
}

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem {
  if ([anItem action] == @selector(delete:)) {
    if (WBDelegateHandle([self delegate], canDeleteSelectionInTableView:))
      return [[self delegate] canDeleteSelectionInTableView:self];
    return [self numberOfSelectedRows] > 0 && WBDelegateHandle([self delegate], deleteSelectionInTableView:);
  } else if ([anItem action] == @selector(selectAll:)) {
    return [self allowsMultipleSelection] || ([self numberOfSelectedRows] == 0 && [self numberOfRows] > 0);
  }
  return YES;
}

- (void)wb_deleteSelection {
  if (WBDelegateHandle([self delegate], deleteSelectionInTableView:)) {
    [[self delegate] deleteSelectionInTableView:self];
  } else {
    NSBeep();
  }
}

- (IBAction)delete:(id)sender {
  [self wb_deleteSelection];
}

- (void)keyDown:(NSEvent *)theEvent {
  switch ([theEvent keyCode]) {
    case 0x033: //kVirtualDeleteKey:
    case 0x075: //kVirtualForwardDeleteKey:
      [self wb_deleteSelection];
      break;
    case 0x04C: //kVirtualEnterKey:
    case 0x024: //kVirtualReturnKey:
    {
      id target = [self target];
      SEL doubleAction = [self doubleAction];
      if ([self sendAction:doubleAction to:target]) {
        break;
      }
    }
    default:
      [super keyDown:theEvent];
  }
}

- (void)editColumn:(NSInteger)column row:(NSInteger)row {
  if (row != -1) {
    [self editColumn:column row:row withEvent:nil select:YES];
  }
}

- (BOOL)shouldEditCellForEvent:(NSEvent *)theEvent {
  return ([theEvent modifierFlags] & NSAlternateKeyMask) != 0;
}

- (void)mouseDown:(NSEvent *)theEvent {
  id delegate = [self delegate];
  if ([theEvent clickCount] == 1) {
    /* If is maybe editable */
    if (WBDelegateHandle(delegate, tableView:shouldEditTableColumn:row:)
        && [[self dataSource] respondsToSelector:@selector(tableView:setObjectValue:forTableColumn:row:)]) {
      // If option key down when click => edit clicked cell
      if ([self shouldEditCellForEvent:theEvent]) {
        NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        NSInteger row = [self rowAtPoint:point];
        NSInteger column = [self columnAtPoint:point];
        
        if (column != -1 && row != -1) {
          // Check if already editing
          if ([self editedRow] == row && [self editedColumn] == column) return;
          
          // Check if editing allows
          if ([delegate tableView:self shouldEditTableColumn:[self columnAtIndex:column] row:row]) {
            // Select row if needed
            if (row != [self selectedRow] || [self numberOfSelectedRows] > 1) {
              // [self selectRow:row byExtendingSelection:NO];
              [self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
            }
            // Edit row
            [self editColumn:column row:row withEvent:theEvent select:YES];
            return;
          }
        }
      }
    }
  }
  /* All other cases */
  [super mouseDown:theEvent];
}

- (void)setContinueEditing:(BOOL)flag {
  WBFlagSet(wb_tvFlags.edit, !flag);
}

- (void)textDidEndEditing:(NSNotification *)notification {
  [super textDidEndEditing:notification];
  if (wb_tvFlags.edit) {
    /* deselect next edited row */
    NSInteger row = [self selectedRow];
    if (row >= 0) {
      [self deselectRow:row];
      [self selectRow:row byExtendingSelection:NO];
    }
  }
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
  NSInteger row = [self rowAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
  if (WBDelegateHandle([self delegate], tableView:menuForRow:event:)) {
    return [[self delegate] tableView:self menuForRow:row event:theEvent];
  }
  return [super menuForEvent:theEvent];
}

#pragma mark -
#pragma mark Padding
- (void)setPadding:(BOOL)flag forTableColumn:(NSString *)columnIdentifier {
  if (!flag && !wb_noPadding) {
    wb_noPadding = NSCreateHashTable(NSNonRetainedObjectHashCallBacks, 0);
  }
  NSTableColumn *column = [self tableColumnWithIdentifier:columnIdentifier];
  if (column) {
    if (!flag) {
      NSHashInsertIfAbsent(wb_noPadding, column);
    } else if (wb_noPadding) {
      NSHashRemove(wb_noPadding, column);
    }
  } else {
		WBThrowException(NSInvalidArgumentException, @"Table column %@ does not exist", columnIdentifier);
  }
}

- (NSRect)frameOfCellAtColumn:(NSInteger)columnIndex row:(NSInteger)rowIndex {
  if (wb_noPadding) {
    NSTableColumn *column = [[self tableColumns] objectAtIndex:columnIndex];
    if (column && NSHashGet(wb_noPadding, column)) {
      return NSIntersectionRect([self rectOfRow:rowIndex], [self rectOfColumn:columnIndex]);
    }
  }
  return [super frameOfCellAtColumn:columnIndex row:rowIndex];
}

@end
