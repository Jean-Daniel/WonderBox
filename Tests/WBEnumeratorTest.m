/*
 *  WBEnumeratorTest.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <GHUnit/GHUnit.h>
#import WBHEADER(WBEnumerator.h)

@interface WBEnumeratorTest : GHTestCase {

}

@end

@implementation WBEnumeratorTest

- (void)testWBMapEnumerator {
  NSMapTable *table = NSCreateMapTable(NSIntegerMapKeyCallBacks, NSObjectMapValueCallBacks, 0);
  NSMapInsert(table, (void *)25, @"Bonjour");
  NSMapInsert(table, (void *)32, @"Monde");
  NSMapInsert(table, (void *)43, @"!");

  NSString *str;
  NSUInteger count = NSCountMapTable(table);
  NSEnumerator *enume = WBMapTableEnumerator(table, NO);
  while (str = [enume nextObject]) {
    count--;
    GHAssertTrue([str isEqualToString:@"Bonjour"] ||
                 [str isEqualToString:@"Monde"] ||
                 [str isEqualToString:@"!"], @"Invalid value");
  }
  GHAssertTrue(0 == count, @"Count must be null");

  NSInteger key = 0;
  enume = WBMapTableEnumerator(table, YES);
  while (key = (NSInteger)[enume nextObject]) {
    GHAssertTrue(25 == key ||
                 32 == key ||
                 43 == key, @"Invalid key");
  }
  NSFreeMapTable(table);
}

@end
