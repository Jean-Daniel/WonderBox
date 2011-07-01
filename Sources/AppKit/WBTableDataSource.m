/*
 *  WBTableDataSource.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBTableDataSource.h)

@implementation WBTableDataSource

- (void)dealloc {
  wb_release(wb_searchString);
  wb_dealloc();
}

#pragma mark -
#pragma mark Sort Methods
- (WBCompareFunction)compareFunction {
  return wb_compare;
}
- (void)setCompareFunction:(WBCompareFunction)function {
  wb_compare = function;
  [self rearrangeObjects];
}

#pragma mark -
#pragma mark Search Methods
- (IBAction)search:(id)sender {
  // set the search string by getting the stringValue
  // from the sender
  NSString *str = [sender stringValue];
  [self setSearchString:[str length] ? str : nil];
}

- (NSString *)searchString {
  return wb_searchString;
}

- (void)setSearchString:(NSString *)aString {
  if (![aString isEqualToString:wb_searchString]) {
    wb_release(wb_searchString);
    wb_searchString = [aString length] > 0 ? wb_retain(aString) : nil;
    [self rearrangeObjects];
  }
}

- (WBFilterFunction)filterFunction {
  return wb_filter;
}
- (void)setFilterFunction:(WBFilterFunction)function context:(void *)ctxt {
  wb_filter = function;
  wb_filterCtxt = ctxt;
  [self rearrangeObjects];
}

#pragma mark -
#pragma mark Custom Arrange Algorithm
- (NSArray *)arrangeObjects:(NSArray *)objects {
  NSArray *result = nil;
  if (wb_filter) {
    id item = nil;
    NSUInteger count = [objects count];
    NSMutableArray *filteredObjects = [NSMutableArray arrayWithCapacity:[objects count]];
    while (count-- > 0) {
      item = [objects objectAtIndex:count];
      if (wb_filter(wb_searchString, item, wb_filterCtxt)) {
        [filteredObjects addObject:item];
      }
    }
    result = filteredObjects;
  } else {
    result = objects;
  }

  if (wb_compare) {
    @try { /* If Mutable Array sort it */
      [(NSMutableArray *)result sortUsingFunction:wb_compare context:(__bridge void *)self];
    } @catch (id) { /* else return a sorted copy */
      result = [result sortedArrayUsingFunction:wb_compare context:(__bridge void *)self];
    }
  } else {
    result = [super arrangeObjects:result];
  }
  return result;
}

#pragma mark -
#pragma mark TableView DataSource Protocol
/* Use to be DataSource compliante, but all values in tables are obtains by KVB */
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
  return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
  return nil;
}

//- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
//}

//#pragma mark Sorting Support
//- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
//}

#pragma mark Drag & Drop Support
- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard {
  id delegate = [aTableView delegate];
  if (delegate && delegate != self && [delegate respondsToSelector:_cmd])
    return [delegate tableView:aTableView writeRowsWithIndexes:rowIndexes toPasteboard:pboard];
  return NO;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation {
  id delegate = [tableView delegate];
  if (delegate && delegate != self && [delegate respondsToSelector:_cmd]) {
    return [delegate tableView:tableView validateDrop:info proposedRow:row proposedDropOperation:operation];
  }
  return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation {
  id delegate = [aTableView delegate];
  if (delegate && delegate != self && [delegate respondsToSelector:_cmd]) {
    return [delegate tableView:aTableView acceptDrop:info row:row dropOperation:operation];
  }
  return NO;
}

- (NSArray *)tableView:(NSTableView *)aTableView namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedRowsWithIndexes:(NSIndexSet *)indexSet {
  id delegate = [aTableView delegate];
  if (delegate && delegate != self && [delegate respondsToSelector:_cmd]) {
    return [delegate tableView:aTableView namesOfPromisedFilesDroppedAtDestination:dropDestination forDraggedRowsWithIndexes:indexSet];
  }
  return nil;
}

@end
