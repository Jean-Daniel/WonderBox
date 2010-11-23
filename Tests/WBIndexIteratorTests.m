/*
 *  WBIndexIteratorTests.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <GHUnit/GHUnit.h>

#import "WBIndexSetIterator.h"

@interface WBIndexIteratorTests : GHTestCase {

}

@end


@implementation WBIndexIteratorTests

- (void)test_1_EmptySet {
  NSIndexSet *indexes = [NSIndexSet indexSet];
  WBIndexIterator iter = WBIndexIteratorCreate(indexes);
  GHAssertTrue(NSNotFound == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext return an index for empty set");

  NSRange range;
  WBRangeIterator riter = WBRangeIteratorCreate(indexes);
  GHAssertFalse(WBRangeIteratorGetNext(&riter, &range), @"WBRangeIteratorGetNext return an index for empty set");
}

- (void)test_2_SingleValueSet {
  NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:0];
  WBIndexIterator iter = WBIndexIteratorCreate(indexes);
  GHAssertTrue(0 == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext(): invalid index");
  GHAssertTrue(NSNotFound == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext return an index for an empty set");

  NSRange range;
  WBRangeIterator riter = WBRangeIteratorCreate(indexes);
  GHAssertTrue(WBRangeIteratorGetNext(&riter, &range), @"WBRangeIteratorGetNext return an index for empty set");
  GHAssertTrue(range.location == 0 && range.length == 1, @"WBRangeIteratorGetNext(): invalid range");
  GHAssertFalse(WBRangeIteratorGetNext(&riter, &range), @"WBRangeIteratorGetNext return true for an empty set");

  indexes = [NSIndexSet indexSetWithIndex:10];
  iter = WBIndexIteratorCreate(indexes);
  GHAssertTrue(10 == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext(): invalid index");
  GHAssertTrue(NSNotFound == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext return an index for an empty set");

  riter = WBRangeIteratorCreate(indexes);
  GHAssertTrue(WBRangeIteratorGetNext(&riter, &range), @"WBRangeIteratorGetNext return an index for empty set");
  GHAssertTrue(range.location == 10 && range.length == 1, @"WBRangeIteratorGetNext(): invalid range");
  GHAssertFalse(WBRangeIteratorGetNext(&riter, &range), @"WBRangeIteratorGetNext return true for an empty set");
}

- (void)test_3_SingleRangeSet {
  NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(12, 64)];
  WBIndexIterator iter = WBIndexIteratorCreate(indexes);
  for (NSUInteger idx = 12; idx < 12 + 64; idx++) {
    GHAssertTrue(idx == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext(): invalid index");
  }
  GHAssertTrue(NSNotFound == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext return an index for an empty set");

  NSRange range;
  WBRangeIterator riter = WBRangeIteratorCreate(indexes);
  GHAssertTrue(WBRangeIteratorGetNext(&riter, &range), @"WBRangeIteratorGetNext return an index for empty set");
  GHAssertTrue(range.location == 12 && range.length == 64, @"WBRangeIteratorGetNext(): invalid range");
  GHAssertFalse(WBRangeIteratorGetNext(&riter, &range), @"WBRangeIteratorGetNext return true for an empty set");

  indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 20)];
  iter = WBIndexIteratorCreate(indexes);
  for (NSUInteger idx = 0; idx < 20; idx++) {
    GHAssertTrue(idx == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext(): invalid index");
  }
  GHAssertTrue(NSNotFound == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext return an index for an empty set");

  riter = WBRangeIteratorCreate(indexes);
  GHAssertTrue(WBRangeIteratorGetNext(&riter, &range), @"WBRangeIteratorGetNext return an index for empty set");
  GHAssertTrue(range.location == 0 && range.length == 20, @"WBRangeIteratorGetNext(): invalid range");
  GHAssertFalse(WBRangeIteratorGetNext(&riter, &range), @"WBRangeIteratorGetNext return true for an empty set");
}

- (void)test_4_MultipleRanges {
  NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
  [indexes addIndexesInRange:NSMakeRange(0, 12)];
  [indexes addIndex:20];
  [indexes addIndexesInRange:NSMakeRange(23, 54)];
  [indexes addIndex:97];

  NSRange range;
  WBRangeIterator riter = WBRangeIteratorCreate(indexes);
  /* [0; 12] */
  GHAssertTrue(WBRangeIteratorGetNext(&riter, &range), @"WBRangeIteratorGetNext return an index for empty set");
  GHAssertTrue(range.location == 0 && range.length == 12, @"WBRangeIteratorGetNext(): invalid range");
  /* 20 */
  GHAssertTrue(WBRangeIteratorGetNext(&riter, &range), @"WBRangeIteratorGetNext return an index for empty set");
  GHAssertTrue(range.location == 20 && range.length == 1, @"WBRangeIteratorGetNext(): invalid range");
  /* [23; 77] */
  GHAssertTrue(WBRangeIteratorGetNext(&riter, &range), @"WBRangeIteratorGetNext return an index for empty set");
  GHAssertTrue(range.location == 23 && range.length == 54, @"WBRangeIteratorGetNext(): invalid range");
  /* 97 */
  GHAssertTrue(WBRangeIteratorGetNext(&riter, &range), @"WBRangeIteratorGetNext return an index for empty set");
  GHAssertTrue(range.location == 97 && range.length == 1, @"WBRangeIteratorGetNext(): invalid range");

  GHAssertFalse(WBRangeIteratorGetNext(&riter, &range), @"WBRangeIteratorGetNext return true for an empty set");
}

- (void)test_5_IterateSubRange {
  NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(12, 64)];

  // Test ranges with no intersection
  WBIndexIterator iter = WBIndexIteratorCreateWithRange(indexes, NSMakeRange(0, 12));
  GHAssertTrue(NSNotFound == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext return an index for an empty set");

  iter = WBIndexIteratorCreateWithRange(indexes, NSMakeRange(12, 0));
  GHAssertTrue(NSNotFound == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext return an index for an empty set");

  // Range with exact end
  iter = WBIndexIteratorCreateWithRange(indexes, NSMakeRange(0, 76));
  for (NSUInteger idx = 12; idx < 12 + 64; idx++) {
    GHAssertTrue(idx == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext(): invalid index");
  }
  GHAssertTrue(NSNotFound == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext return an index for an empty set");

  // Range with exact start + end
  iter = WBIndexIteratorCreateWithRange(indexes, NSMakeRange(12, 64));
  for (NSUInteger idx = 12; idx < 12 + 64; idx++) {
    GHAssertTrue(idx == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext(): invalid index");
  }
  GHAssertTrue(NSNotFound == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext return an index for an empty set");

  // Range with end > last index
  iter = WBIndexIteratorCreateWithRange(indexes, NSMakeRange(60, 128));
  for (NSUInteger idx = 60; idx < 12 + 64; idx++) {
    GHAssertTrue(idx == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext(): invalid index");
  }
  GHAssertTrue(NSNotFound == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext return an index for an empty set");

  // Range with start < first index
  iter = WBIndexIteratorCreateWithRange(indexes, NSMakeRange(0, 50));
  for (NSUInteger idx = 12; idx < 50; idx++) {
    GHAssertTrue(idx == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext(): invalid index");
  }
  GHAssertTrue(NSNotFound == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext return an index for an empty set");

  // Test invalid ranges
  iter = WBIndexIteratorCreateWithRange(indexes, NSMakeRange(NSNotFound, 10));
  GHAssertTrue(NSNotFound == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext return an index for an empty set");

  iter = WBIndexIteratorCreateWithRange(indexes, NSMakeRange(15, NSNotFound));
  GHAssertTrue(NSNotFound == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext return an index for an empty set");
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
  WBIndexIterator iter = WBIndexIteratorCreate(indexes);
  for (NSUInteger idx = 0; idx < 32; idx++) {
    NSUInteger value = WBIndexIteratorNext(&iter);
    GHAssertTrue(values[idx] == value, @"WBIndexIteratorNext(): invalid index");
  }
  GHAssertTrue(NSNotFound == WBIndexIteratorNext(&iter), @"WBIndexIteratorNext return an index for an empty set");
}

- (void)test_7_IteratorMacros {
  NSUInteger expected = 12;
  WBIndexesIterator(idx, [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(12, 64)]) {
    GHAssertTrue(idx == expected, @"WBIndexIteratorNext(): invalid index");
    expected++;
  }
  GHAssertTrue(76 == expected, @"WBIndexIteratorNext(): end prematurely");

  expected = 0;
  WBIndexesIterator(idx, [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 127)]) {
    GHAssertTrue(idx == expected, @"WBIndexIteratorNext(): invalid index");
    expected++;
  }
  GHAssertTrue(127 == expected, @"WBIndexIteratorNext(): end prematurely");
}

@end
