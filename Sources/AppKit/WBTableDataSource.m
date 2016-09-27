/*
 *  WBTableDataSource.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBTableDataSource.h>

@implementation WBTableDataSource

- (void)dealloc {
  spx_release(_searchString);
  [super dealloc];
}

#pragma mark -
#pragma mark Sort Methods
- (void)setComparator:(NSComparator)comparator {
  _comparator = comparator;
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

- (void)setSearchString:(NSString *)aString {
  if (![aString isEqualToString:_searchString]) {
    spx_release(_searchString);
    _searchString = [aString length] > 0 ? [aString copy] : nil;
    [self rearrangeObjects];
  }
}

- (void)setFilterBlock:(WBFilterBlock)filterBlock {
  _filterBlock = filterBlock;
  [self rearrangeObjects];
}

#pragma mark -
#pragma mark Custom Arrange Algorithm
- (NSArray *)arrangeObjects:(NSArray *)objects {
  NSArray *result = nil;
  if (_filterBlock) {
    id item = nil;
    NSUInteger count = [objects count];
    NSMutableArray *filteredObjects = [NSMutableArray arrayWithCapacity:[objects count]];
    while (count-- > 0) {
      item = [objects objectAtIndex:count];
      if (_filterBlock(_searchString, item)) {
        [filteredObjects addObject:item];
      }
    }
    result = filteredObjects;
  } else {
    result = objects;
  }

  if (_comparator) {
    result = [result sortedArrayUsingComparator:_comparator];
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
