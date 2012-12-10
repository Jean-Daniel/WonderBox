/*
 *  WBOutlineView.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBOutlineView.h>

@implementation WBOutlineView

- (void)dealloc {
  if (wb_noPadding)
    NSFreeHashTable(wb_noPadding);
  spx_dealloc();
}

#pragma mark -
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
- (id<WBOutlineViewDelegate>)delegate {
  return (id<WBOutlineViewDelegate>)[super delegate];
}
- (void)setDelegate:(id<WBOutlineViewDelegate>)aDelegate {
  [super setDelegate:aDelegate];
  wb_ovFlags.drawOutline = SPXDelegateHandle(aDelegate, outlineView:shouldDrawOutlineCellAtRow:);
}
#else
- (void)setDelegate:(id)aDelegate {
  [super setDelegate:aDelegate];
  wb_ovFlags.drawOutline = WBDelegateHandle(aDelegate, outlineView:shouldDrawOutlineCellAtRow:);
}
#endif

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)flag {
  return flag ? NSDragOperationEvery : NSDragOperationNone;
}

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem {
  if ([anItem action] == @selector(delete:)) {
    if (SPXDelegateHandle([self delegate], canDeleteSelectionInOutlineView:))
      return [[self delegate] canDeleteSelectionInOutlineView:self];
    return [self numberOfSelectedRows] != 0 && SPXDelegateHandle([self delegate], deleteSelectionInOutlineView:);
  } else if ([anItem action] == @selector(selectAll:)) {
    // Disable selectAll: when multi-selection is not allowed
    return [self allowsMultipleSelection] || ([self numberOfSelectedRows] == 0 && [self numberOfRows] > 0);
  }

  return [super validateUserInterfaceItem:anItem];
}

- (void)wb_deleteSelection {
  if (SPXDelegateHandle([self delegate], deleteSelectionInOutlineView:)) {
    [[self delegate] deleteSelectionInOutlineView:self];
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
      return [self wb_deleteSelection];
    case 0x04C: //kVirtualEnterKey:
    case 0x024: //kVirtualReturnKey:
    {
      id target = [self target];
      SEL doubleAction = [self doubleAction];
      if (doubleAction && [self sendAction:doubleAction to:target])
        return;
    }
      break;
    default: break;
  }
  [super keyDown:theEvent];
}

- (void)editColumn:(NSInteger)column item:(id)anItem {
  NSInteger row = [self rowForItem:anItem];
  if (row >= 0)
    [self editColumn:column row:row withEvent:nil select:YES];
}

- (BOOL)shouldEditCellForEvent:(NSEvent *)theEvent {
  return ([theEvent modifierFlags] & NSAlternateKeyMask) != 0;
}

- (void)mouseDown:(NSEvent *)theEvent {
  id delegate = [self delegate];
  if (wb_ovFlags.editOnClick && [theEvent clickCount] == 1) {
    /* If is maybe editable */
    if (SPXDelegateHandle(delegate, outlineView:shouldEditTableColumn:item:) &&
        [[self dataSource] respondsToSelector:@selector(outlineView:setObjectValue:forTableColumn:byItem:)]) {
      // If option key down when click => edit clicked cell
      if ([self shouldEditCellForEvent:theEvent]) {
        NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        NSInteger row = [self rowAtPoint:point];
        NSInteger column = [self columnAtPoint:point];

        if (column >= 0 && row >= 0) {
          NSTableColumn *col = [[self tableColumns] objectAtIndex:(NSUInteger)column];
          if ([col isEditable]) {
            // Check if already editing
            if ([self editedRow] == row && [self editedColumn] == column) return;

            // Check if we click on editable text
            if ([self respondsToSelector:@selector(preparedCellAtColumn:row:)]) {
              NSCell *cell = [self preparedCellAtColumn:column row:row];
              NSUInteger test = [cell hitTestForEvent:theEvent
                                               inRect:[self frameOfCellAtColumn:column row:row]
                                               ofView:self];
              if ((test & NSCellHitEditableTextArea) == 0) {
                [super mouseDown:theEvent];
                return;
              }
            } else if (col == [self outlineTableColumn]) {
              // On pre 10.5 system, we perform a basic test to make sure we don't click on outline button
              CGFloat bias = 12;
              CGFloat x = point.x - [self rectOfColumn:column].origin.x;
              if ([self indentationMarkerFollowsCell]) {
                bias = ([self levelForRow:row] + 1) * [self indentationPerLevel];
              }
              bias += 4; // left padding
              if (x < (bias - 2) && x > (bias - 15)) {
                [super mouseDown:theEvent];
                return;
              }
            }

            // Check if editing allows
            id item = [self itemAtRow:row];

            if (item && [delegate outlineView:self shouldEditTableColumn:col item:item]) {
              // Select row if needed
              if (row != [self selectedRow] || [self numberOfSelectedRows] > 1) {
                // [self selectRow:row byExtendingSelection:NO];
                [self selectRowIndexes:[NSIndexSet indexSetWithIndex:(NSUInteger)row] byExtendingSelection:NO];
              }
              // Edit row
              [self editColumn:column row:row withEvent:theEvent select:YES];
              return;
            }
          }
        }
      }
    }
  }
  /* All other cases */
  [super mouseDown:theEvent];
}

- (void)setContinueEditing:(BOOL)flag {
  SPXFlagSet(wb_ovFlags.edit, !flag);
}

- (void)textDidEndEditing:(NSNotification *)notification {
  [super textDidEndEditing:notification];
  if (wb_ovFlags.edit) {
    /* deselect next edited row */
    NSInteger row = [self selectedRow];
    if (row >= 0) {
      [self deselectRow:row];
      [self selectRowIndexes:[NSIndexSet indexSetWithIndex:(NSUInteger)row] byExtendingSelection:NO];
    }
  }
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
      NSHashInsertIfAbsent(wb_noPadding, (__bridge void *)column);
    } else if (wb_noPadding) {
      NSHashRemove(wb_noPadding, (__bridge void *)column);
    }
  } else {
    SPXThrowException(NSInvalidArgumentException, @"Table column %@ does not exist", columnIdentifier);
  }
}

- (NSRect)frameOfCellAtColumn:(NSInteger)columnIndex row:(NSInteger)rowIndex {
  if (wb_noPadding && rowIndex >= 0) {
    NSTableColumn *column = [[self tableColumns] objectAtIndex:(NSUInteger)columnIndex];
    if (column && NSHashGet(wb_noPadding, (__bridge void *)column)) {
      return NSIntersectionRect([self rectOfRow:rowIndex], [self rectOfColumn:columnIndex]);
    }
  }
  return [super frameOfCellAtColumn:columnIndex row:rowIndex];
}

#pragma mark Disclosure
- (NSRect)frameOfOutlineCellAtRow:(NSInteger)row {
  if (!wb_ovFlags.drawOutline || [[self delegate] outlineView:self shouldDrawOutlineCellAtRow:row])
    return [super frameOfOutlineCellAtRow:row];

  return NSZeroRect;
}

@end
