/*
 *  WBMacroTests.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <XCTest/XCTest.h>

@interface WBMacroTests : XCTestCase {

}

@end

@implementation WBMacroTests

- (void)testFlagsMacros {
  struct {
    unsigned int foo:1;
  } test;
  test.foo = 0;
  XCTAssertFalse(test.foo, @"sanity check");
  SPXFlagSet(test.foo, 1);
  XCTAssertTrue(test.foo, @"SPXFlagSet");
  /* true => true */
  bool eval = SPXFlagTestAndSet(test.foo, 1);
  XCTAssertTrue(test.foo, @"WBFlagTestAndSet");
  XCTAssertTrue(eval, @"WBFlagTestAndSet");

  /* true => false */
  eval = SPXFlagTestAndSet(test.foo, 0);
  XCTAssertFalse(test.foo, @"WBFlagTestAndSet");
  XCTAssertTrue(eval, @"WBFlagTestAndSet");

  /* false => false */
  eval = SPXFlagTestAndSet(test.foo, 0);
  XCTAssertFalse(test.foo, @"WBFlagTestAndSet");
  XCTAssertFalse(eval, @"WBFlagTestAndSet");

  /* false => true */
  eval = SPXFlagTestAndSet(test.foo, 1);
  XCTAssertTrue(test.foo, @"WBFlagTestAndSet");
  XCTAssertFalse(eval, @"WBFlagTestAndSet");
}


@end
