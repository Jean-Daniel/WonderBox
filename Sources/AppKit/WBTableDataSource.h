/*
 *  WBTableDataSource.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBBase.h)

typedef NSComparisonResult (*WBCompareFunction)(id, id, void *);
typedef BOOL (*WBFilterFunction)(NSString *, id, void *);

WB_OBJC_EXPORT
@interface WBTableDataSource : NSArrayController {
  @private
  NSString *wb_searchString;
  WBFilterFunction wb_filter;
  void *wb_filterCtxt;
  WBCompareFunction wb_compare;
}

#pragma mark -
- (WBCompareFunction)compareFunction;
- (void)setCompareFunction:(WBCompareFunction)function;

#pragma mark -
- (IBAction)search:(id)sender;

- (NSString *)searchString;
- (void)setSearchString:(NSString *)aString;

- (WBFilterFunction)filterFunction;
- (void)setFilterFunction:(WBFilterFunction)function context:(void *)ctxt;

@end
