/*
 *  WBIndexIteratorTests.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <XCTest/XCTest.h>

#import "WBIndexSetIterator.h"

@interface WBIndexIteratorTests : XCTestCase {

}

@end


@implementation WBIndexIteratorTests

- (void)test_1_EmptySet {
  NSIndexSet *indexes = [NSIndexSet indexSet];
  WBIndexIterator iter;
  WBIndexIteratorInitialize(indexes, &iter);
  XCTAssertTrue(NSNotFound == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext return an index for empty set");

  NSRange range;
  WBRangeIterator riter;
  WBRangeIteratorInitialize(indexes, &riter);
  XCTAssertFalse(WBRangeIteratorGetNext(&riter, &range), @"WBRangeIteratorGetNext return an index for empty set");
}

- (void)test_2_SingleValueSet {
  NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:0];
  WBIndexIterator iter;
  WBIndexIteratorInitialize(indexes, &iter);
  XCTAssertTrue(0 == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext(): invalid index");
  XCTAssertTrue(NSNotFound == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext return an index for an empty set");

  NSRange range;
  WBRangeIterator riter;
  WBRangeIteratorInitialize(indexes, &riter);
  XCTAssertTrue(WBRangeIteratorGetNext(&riter, &range), @"WBRangeIteratorGetNext return an index for empty set");
  XCTAssertTrue(range.location == 0 && range.length == 1, @"WBRangeIteratorGetNext(): invalid range");
  XCTAssertFalse(WBRangeIteratorGetNext(&riter, &range), @"WBRangeIteratorGetNext return true for an empty set");

  indexes = [NSIndexSet indexSetWithIndex:10];
  WBIndexIteratorInitialize(indexes, &iter);
  XCTAssertTrue(10 == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext(): invalid index");
  XCTAssertTrue(NSNotFound == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext return an index for an empty set");

  WBRangeIteratorInitialize(indexes, &riter);
  XCTAssertTrue(WBRangeIteratorGetNext(&riter, &range), @"WBRangeIteratorGetNext return an index for empty set");
  XCTAssertTrue(range.location == 10 && range.length == 1, @"WBRangeIteratorGetNext(): invalid range");
  XCTAssertFalse(WBRangeIteratorGetNext(&riter, &range), @"WBRangeIteratorGetNext return true for an empty set");
}

- (void)test_3_SingleRangeSet {
  NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(12, 64)];
  WBIndexIterator iter;
  WBIndexIteratorInitialize(indexes, &iter);
  for (NSUInteger idx = 12; idx < 12 + 64; idx++) {
    XCTAssertTrue(idx == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext(): invalid index");
  }
  XCTAssertTrue(NSNotFound == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext return an index for an empty set");

  NSRange range;
  WBRangeIterator riter;
  WBRangeIteratorInitialize(indexes, &riter);
  XCTAssertTrue(WBRangeIteratorGetNext(&riter, &range), @"WBRangeIteratorGetNext return an index for empty set");
  XCTAssertTrue(range.location == 12 && range.length == 64, @"WBRangeIteratorGetNext(): invalid range");
  XCTAssertFalse(WBRangeIteratorGetNext(&riter, &range), @"WBRangeIteratorGetNext return true for an empty set");

  indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 20)];
  WBIndexIteratorInitialize(indexes, &iter);
  for (NSUInteger idx = 0; idx < 20; idx++) {
    XCTAssertTrue(idx == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext(): invalid index");
  }
  XCTAssertTrue(NSNotFound == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext return an index for an empty set");

  WBRangeIteratorInitialize(indexes, &riter);
  XCTAssertTrue(WBRangeIteratorGetNext(&riter, &range), @"WBRangeIteratorGetNext return an index for empty set");
  XCTAssertTrue(range.location == 0 && range.length == 20, @"WBRangeIteratorGetNext(): invalid range");
  XCTAssertFalse(WBRangeIteratorGetNext(&riter, &range), @"WBRangeIteratorGetNext return true for an empty set");
}

- (void)test_4_MultipleRanges {
  NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
  [indexes addIndexesInRange:NSMakeRange(0, 12)];
  [indexes addIndex:20];
  [indexes addIndexesInRange:NSMakeRange(23, 54)];
  [indexes addIndex:97];

  NSRange range;
  WBRangeIterator riter;
  WBRangeIteratorInitialize(indexes, &riter);
  /* [0; 12] */
  XCTAssertTrue(WBRangeIteratorGetNext(&riter, &range), @"WBRangeIteratorGetNext return an index for empty set");
  XCTAssertTrue(range.location == 0 && range.length == 12, @"WBRangeIteratorGetNext(): invalid range");
  /* 20 */
  XCTAssertTrue(WBRangeIteratorGetNext(&riter, &range), @"WBRangeIteratorGetNext return an index for empty set");
  XCTAssertTrue(range.location == 20 && range.length == 1, @"WBRangeIteratorGetNext(): invalid range");
  /* [23; 77] */
  XCTAssertTrue(WBRangeIteratorGetNext(&riter, &range), @"WBRangeIteratorGetNext return an index for empty set");
  XCTAssertTrue(range.location == 23 && range.length == 54, @"WBRangeIteratorGetNext(): invalid range");
  /* 97 */
  XCTAssertTrue(WBRangeIteratorGetNext(&riter, &range), @"WBRangeIteratorGetNext return an index for empty set");
  XCTAssertTrue(range.location == 97 && range.length == 1, @"WBRangeIteratorGetNext(): invalid range");

  XCTAssertFalse(WBRangeIteratorGetNext(&riter, &range), @"WBRangeIteratorGetNext return true for an empty set");
}

- (void)test_5_IterateSubRange {
  NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(12, 64)];

  // Test ranges with no intersection
  WBIndexIterator iter;
  WBIndexIteratorInitializeWithRange(indexes, NSMakeRange(0, 12), &iter);
  XCTAssertTrue(NSNotFound == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext return an index for an empty set");

  WBIndexIteratorInitializeWithRange(indexes, NSMakeRange(0, 12), &iter);
  XCTAssertTrue(NSNotFound == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext return an index for an empty set");

  // Range with exact end
  WBIndexIteratorInitializeWithRange(indexes, NSMakeRange(0, 76), &iter);
  for (NSUInteger idx = 12; idx < 12 + 64; idx++) {
    XCTAssertTrue(idx == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext(): invalid index");
  }
  XCTAssertTrue(NSNotFound == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext return an index for an empty set");

  // Range with exact start + end
  WBIndexIteratorInitializeWithRange(indexes, NSMakeRange(12, 64), &iter);
  for (NSUInteger idx = 12; idx < 12 + 64; idx++) {
    XCTAssertTrue(idx == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext(): invalid index");
  }
  XCTAssertTrue(NSNotFound == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext return an index for an empty set");

  // Range with end > last index
  WBIndexIteratorInitializeWithRange(indexes, NSMakeRange(60, 128), &iter);
  for (NSUInteger idx = 60; idx < 12 + 64; idx++) {
    XCTAssertTrue(idx == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext(): invalid index");
  }
  XCTAssertTrue(NSNotFound == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext return an index for an empty set");

  // Range with start < first index
  WBIndexIteratorInitializeWithRange(indexes, NSMakeRange(0, 50), &iter);
  for (NSUInteger idx = 12; idx < 50; idx++) {
    XCTAssertTrue(idx == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext(): invalid index");
  }
  XCTAssertTrue(NSNotFound == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext return an index for an empty set");

  // Test invalid ranges
  WBIndexIteratorInitializeWithRange(indexes, NSMakeRange(NSNotFound, 10), &iter);
  XCTAssertTrue(NSNotFound == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext return an index for an empty set");

  WBIndexIteratorInitializeWithRange(indexes, NSMakeRange(15, NSNotFound), &iter);
  XCTAssertTrue(NSNotFound == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext return an index for an empty set");
}

static
int __compareInteger(const void *arg1, const void *arg2) {
  const NSUInteger *i1 = (const NSUInteger *)arg1;
  const NSUInteger *i2 = (const NSUInteger *)arg2;
  return *i1 - *i2;
}
- (void)test_6_RandomSet {
  NSUInteger values[32];
  NSMutableIndexSet *indexes = [[NSMutableIndexSet alloc] init];
  for (NSUInteger idx = 0; idx < 32; idx++) {
    values[idx] = random() & 0x7ffffffe;
    [indexes addIndex:values[idx]];
  }
  qsort(values, 32, sizeof(*values), __compareInteger);
  WBIndexIterator iter;
  WBIndexIteratorInitialize(indexes, &iter);
  for (NSUInteger idx = 0; idx < 32; idx++) {
    NSUInteger value = WBIndexIteratorNext(&iter);
    XCTAssertTrue(values[idx] == value, @"WBIndexIteratorNext(): invalid index");
  }
  XCTAssertTrue(NSNotFound == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext return an index for an empty set");
}

- (void)test_7_IteratorMacros {
  NSUInteger expected = 12;
  WBIndexesIterator(idx, [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(12, 64)]) {
    XCTAssertTrue(idx == expected, @"WBIndexIteratorNext(): invalid index");
    expected++;
  }
  XCTAssertTrue(76 == expected, @"WBIndexIteratorNext(): end prematurely");

  expected = 0;
  WBIndexesIterator(idx, [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 127)]) {
    XCTAssertTrue(idx == expected, @"WBIndexIteratorNext(): invalid index");
    expected++;
  }
  XCTAssertTrue(127 == expected, @"WBIndexIteratorNext(): end prematurely");
}

@end
