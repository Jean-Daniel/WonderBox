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

- (void)testEmptySet {
  WBIndexSetIterator iter = WBIndexSetIteratorCreate([NSIndexSet indexSet]);
  GHAssertTrue(NSNotFound == WBIndexSetIteratorNextIndex(&iter), @"WBIndexSetIteratorNextIndex return an index for empty set");
}

- (void)testSingleValueSet {
  WBIndexSetIterator iter = WBIndexSetIteratorCreate([NSIndexSet indexSetWithIndex:0]);
  GHAssertTrue(0 == WBIndexSetIteratorNextIndex(&iter), @"WBIndexSetIteratorNextIndex(): invalid index");
  GHAssertTrue(NSNotFound == WBIndexSetIteratorNextIndex(&iter), @"WBIndexSetIteratorNextIndex return an index for an empty set");

  iter = WBIndexSetIteratorCreate([NSIndexSet indexSetWithIndex:10]);
  GHAssertTrue(10 == WBIndexSetIteratorNextIndex(&iter), @"WBIndexSetIteratorNextIndex(): invalid index");
  GHAssertTrue(NSNotFound == WBIndexSetIteratorNextIndex(&iter), @"WBIndexSetIteratorNextIndex return an index for an empty set");
}

- (void)testMultipleFillSet {
  WBIndexSetIterator iter = WBIndexSetIteratorCreate([NSIndexSet indexSetWithIndexesInRange:NSMakeRange(12, 64)]);
  for (NSUInteger idx = 12; idx < 12 + 64; idx++) {
    GHAssertTrue(idx == WBIndexSetIteratorNextIndex(&iter), @"WBIndexSetIteratorNextIndex(): invalid index");
  }
  GHAssertTrue(NSNotFound == WBIndexSetIteratorNextIndex(&iter), @"WBIndexSetIteratorNextIndex return an index for an empty set");

  iter = WBIndexSetIteratorCreate([NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 20)]);
  for (NSUInteger idx = 0; idx < 20; idx++) {
    GHAssertTrue(idx == WBIndexSetIteratorNextIndex(&iter), @"WBIndexSetIteratorNextIndex(): invalid index");
  }
  GHAssertTrue(NSNotFound == WBIndexSetIteratorNextIndex(&iter), @"WBIndexSetIteratorNextIndex return an index for an empty set");
}

- (void)testWithRange {
  NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(12, 64)];

  // Test ranges with no intersection
  WBIndexSetIterator iter = WBIndexSetIteratorCreateWithRange(indexes, NSMakeRange(0, 12));
  GHAssertTrue(NSNotFound == WBIndexSetIteratorNextIndex(&iter), @"WBIndexSetIteratorNextIndex return an index for an empty set");

  iter = WBIndexSetIteratorCreateWithRange(indexes, NSMakeRange(12, 0));
  GHAssertTrue(NSNotFound == WBIndexSetIteratorNextIndex(&iter), @"WBIndexSetIteratorNextIndex return an index for an empty set");

  // Range with exact end
  iter = WBIndexSetIteratorCreateWithRange(indexes, NSMakeRange(0, 76));
  for (NSUInteger idx = 12; idx < 12 + 64; idx++) {
    GHAssertTrue(idx == WBIndexSetIteratorNextIndex(&iter), @"WBIndexSetIteratorNextIndex(): invalid index");
  }
  GHAssertTrue(NSNotFound == WBIndexSetIteratorNextIndex(&iter), @"WBIndexSetIteratorNextIndex return an index for an empty set");

  // Range with exact start + end
  iter = WBIndexSetIteratorCreateWithRange(indexes, NSMakeRange(12, 64));
  for (NSUInteger idx = 12; idx < 12 + 64; idx++) {
    GHAssertTrue(idx == WBIndexSetIteratorNextIndex(&iter), @"WBIndexSetIteratorNextIndex(): invalid index");
  }
  GHAssertTrue(NSNotFound == WBIndexSetIteratorNextIndex(&iter), @"WBIndexSetIteratorNextIndex return an index for an empty set");

  // Range with end > last index
  iter = WBIndexSetIteratorCreateWithRange(indexes, NSMakeRange(60, 128));
  for (NSUInteger idx = 60; idx < 12 + 64; idx++) {
    GHAssertTrue(idx == WBIndexSetIteratorNextIndex(&iter), @"WBIndexSetIteratorNextIndex(): invalid index");
  }
  GHAssertTrue(NSNotFound == WBIndexSetIteratorNextIndex(&iter), @"WBIndexSetIteratorNextIndex return an index for an empty set");

  // Range with start < first index
  iter = WBIndexSetIteratorCreateWithRange(indexes, NSMakeRange(0, 50));
  for (NSUInteger idx = 12; idx < 50; idx++) {
    GHAssertTrue(idx == WBIndexSetIteratorNextIndex(&iter), @"WBIndexSetIteratorNextIndex(): invalid index");
  }
  GHAssertTrue(NSNotFound == WBIndexSetIteratorNextIndex(&iter), @"WBIndexSetIteratorNextIndex return an index for an empty set");

  // Test invalid ranges
  iter = WBIndexSetIteratorCreateWithRange(indexes, NSMakeRange(NSNotFound, 10));
  GHAssertTrue(NSNotFound == WBIndexSetIteratorNextIndex(&iter), @"WBIndexSetIteratorNextIndex return an index for an empty set");

  iter = WBIndexSetIteratorCreateWithRange(indexes, NSMakeRange(15, NSNotFound));
  GHAssertTrue(NSNotFound == WBIndexSetIteratorNextIndex(&iter), @"WBIndexSetIteratorNextIndex return an index for an empty set");
}

static
int __compareInteger(const void *arg1, const void *arg2) {
  const NSUInteger *i1 = (const NSUInteger *)arg1;
  const NSUInteger *i2 = (const NSUInteger *)arg2;
  return *i1 - *i2;
}
- (void)testRandomSet {
  NSUInteger values[32];
  NSMutableIndexSet *indexes = [[NSMutableIndexSet alloc] init];
  for (NSUInteger idx = 0; idx < 32; idx++) {
    values[idx] = random() & 0x7ffffffe;
    [indexes addIndex:values[idx]];
  }
  qsort(values, 32, sizeof(*values), __compareInteger);
  WBIndexSetIterator iter = WBIndexSetIteratorCreate(indexes);
  for (NSUInteger idx = 0; idx < 32; idx++) {
    NSUInteger value = WBIndexSetIteratorNextIndex(&iter);
    GHAssertTrue(values[idx] == value, @"WBIndexSetIteratorNextIndex(): invalid index");
  }
  GHAssertTrue(NSNotFound == WBIndexSetIteratorNextIndex(&iter), @"WBIndexSetIteratorNextIndex return an index for an empty set");
}

- (void)testForSyntax {
  NSUInteger expected = 12;
  WBIndexesIterator(idx, [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(12, 64)]) {
    GHAssertTrue(idx == expected, @"WBIndexSetIteratorNextIndex(): invalid index");
    expected++;
  }
  GHAssertTrue(76 == expected, @"WBIndexSetIteratorNextIndex(): end prematurely");

  expected = 0;
  WBIndexesIterator(idx, [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 127)]) {
    GHAssertTrue(idx == expected, @"WBIndexSetIteratorNextIndex(): invalid index");
    expected++;
  }
  GHAssertTrue(127 == expected, @"WBIndexSetIteratorNextIndex(): end prematurely");
}

@end
