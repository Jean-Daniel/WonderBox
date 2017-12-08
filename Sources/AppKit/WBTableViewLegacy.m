//
//  WBTableViewLegacy.m
//  WonderBox
//
//  Created by Jean-Daniel on 07/12/2017.
//

#import "WBTableViewLegacy.h"

@implementation WBTableViewLegacy {
@private
  struct _wb_tvFlags {
    unsigned int edit:1;
    unsigned int editOnClick:1;
    unsigned int reserved:30;
  } wb_tvFlags;
  NSHashTable *wb_noPadding;
}

- (void)dealloc {
  if (wb_noPadding)
    NSFreeHashTable(wb_noPadding);
}

- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context {
  return context == NSDraggingContextWithinApplication ? NSDragOperationEvery : NSDragOperationNone;
}

- (void)editColumn:(NSInteger)column row:(NSInteger)row {
  if (row != -1)
    [self editColumn:column row:row withEvent:nil select:YES];
}

- (BOOL)shouldEditCellForEvent:(NSEvent *)theEvent {
  return ([theEvent modifierFlags] & NSAlternateKeyMask) != 0;
}

- (void)mouseDown:(NSEvent *)theEvent {
  id delegate = [self delegate];
  if (wb_tvFlags.editOnClick && [theEvent clickCount] == 1) {
    /* If is maybe editable */
    if (SPXDelegateHandle(delegate, tableView:shouldEditTableColumn:row:)
        && [[self dataSource] respondsToSelector:@selector(tableView:setObjectValue:forTableColumn:row:)]) {
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

            // does it click in an editable text zone (10.5 only)
            if ([self respondsToSelector:@selector(preparedCellAtColumn:row:)]) {
              NSCell *cell = [self preparedCellAtColumn:column row:row];
              NSUInteger test = [cell hitTestForEvent:theEvent
                                               inRect:[self frameOfCellAtColumn:column row:row]
                                               ofView:self];
              if ((test & NSCellHitEditableTextArea) == 0) {
                [super mouseDown:theEvent];
                return;
              }
            }

            // Check if editing allowed
            if ([delegate tableView:self shouldEditTableColumn:col row:row]) {
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
  SPXFlagSet(wb_tvFlags.edit, !flag);
}

- (void)textDidEndEditing:(NSNotification *)notification {
  [super textDidEndEditing:notification];
  if (wb_tvFlags.edit) {
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
  if (wb_noPadding && columnIndex >= 0) {
    NSTableColumn *column = [[self tableColumns] objectAtIndex:(NSUInteger)columnIndex];
    if (column && NSHashGet(wb_noPadding, (__bridge void *)column)) {
      return NSIntersectionRect([self rectOfRow:rowIndex], [self rectOfColumn:columnIndex]);
    }
  }
  return [super frameOfCellAtColumn:columnIndex row:rowIndex];
}

@end

// MARK: -
@implementation WBOutlineViewLegacy {
@private
  struct _wb_ovFlags {
    unsigned int edit:1;
    unsigned int editOnClick:1;
    unsigned int drawOutline:1;
    unsigned int reserved:29;
  } wb_ovFlags;
  NSHashTable *wb_noPadding;
}

- (void)dealloc {
  if (wb_noPadding)
    NSFreeHashTable(wb_noPadding);
}

#pragma mark -
- (id<WBOutlineViewLegacyDelegate>)delegate {
  return (id<WBOutlineViewLegacyDelegate>)[super delegate];
}
- (void)setDelegate:(id<WBOutlineViewLegacyDelegate>)aDelegate {
  [super setDelegate:aDelegate];
  wb_ovFlags.drawOutline = SPXDelegateHandle(aDelegate, outlineView:shouldDrawOutlineCellAtRow:);
}

- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context {
  return context == NSDraggingContextWithinApplication ? NSDragOperationEvery : NSDragOperationNone;
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

