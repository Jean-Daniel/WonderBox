//
//  WBEnumeratorTest.m
//  WonderBox
//
//  Created by Grayfox on 28/07/06.
//  Copyright 2006 Shadow Lab. All rights reserved.
//

#import "WBEnumeratorTest.h"
#import WBHEADER(WBEnumerator.h)

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
    STAssertTrue([str isEqualToString:@"Bonjour"] ||
                 [str isEqualToString:@"Monde"] ||
                 [str isEqualToString:@"!"], @"Invalid value");
  }
  STAssertTrue(0 == count, @"Count must be null");
  
  NSInteger key = 0;
  enume = WBMapTableEnumerator(table, YES);
  while (key = (NSInteger)[enume nextObject]) {
    STAssertTrue(25 == key ||
                 32 == key ||
                 43 == key, @"Invalid key");
  }
  NSFreeMapTable(table);
}

@end
