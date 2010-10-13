/*
 *  WBMacroTests.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <GHUnit/GHUnit.h>

@interface WBMacroTests : GHTestCase {

}

@end

@implementation WBMacroTests

- (void)testFlagsMacros {
  struct {
    unsigned int foo:1;
  } test;
  test.foo = 0;
  GHAssertFalse(test.foo, @"sanity check");
  WBFlagSet(test.foo, 1);
  GHAssertTrue(test.foo, @"WBFlagSet");
  bool eval = WBFlagTestAndSet(test.foo, 1);
  GHAssertTrue(eval, @"WBFlagTestAndSet");
  eval = WBFlagTestAndSet(test.foo, 0);
  GHAssertFalse(test.foo, @"WBFlagTestAndSet");
  GHAssertTrue(eval, @"WBFlagTestAndSet");
}


@end
