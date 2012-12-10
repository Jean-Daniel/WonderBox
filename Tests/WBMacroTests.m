/*
 *  WBMacroTests.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <SenTestingKit/SenTestingKit.h>

@interface WBMacroTests : SenTestCase {

}

@end

@implementation WBMacroTests

- (void)testFlagsMacros {
  struct {
    unsigned int foo:1;
  } test;
  test.foo = 0;
  STAssertFalse(test.foo, @"sanity check");
  SPXFlagSet(test.foo, 1);
  STAssertTrue(test.foo, @"SPXFlagSet");
  /* true => true */
  bool eval = SPXFlagTestAndSet(test.foo, 1);
  STAssertTrue(test.foo, @"WBFlagTestAndSet");
  STAssertTrue(eval, @"WBFlagTestAndSet");

  /* true => false */
  eval = SPXFlagTestAndSet(test.foo, 0);
  STAssertFalse(test.foo, @"WBFlagTestAndSet");
  STAssertTrue(eval, @"WBFlagTestAndSet");

  /* false => false */
  eval = SPXFlagTestAndSet(test.foo, 0);
  STAssertFalse(test.foo, @"WBFlagTestAndSet");
  STAssertFalse(eval, @"WBFlagTestAndSet");

  /* false => true */
  eval = SPXFlagTestAndSet(test.foo, 1);
  STAssertTrue(test.foo, @"WBFlagTestAndSet");
  STAssertFalse(eval, @"WBFlagTestAndSet");
}


@end
