/*
 *  WBScopeTest.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <GHUnit/GHUnit.h>
#import WBHEADER(WBScope.h)

@interface WBScopeTest : GHTestCase {
  
}

@end

@implementation WBScopeTest

- (void)testScoped {
  NSString *tmp;
  NSUInteger rc;
  {
    WBScopeReleased NSString *test = [[NSMutableString alloc] init];
    tmp = [test retain];
    rc = [test retainCount];
  }
  GHAssertTrue(rc - 1 == [tmp retainCount], @"invalid retain count: %u instead of %u", [tmp retainCount], rc - 1);
  [tmp release];
}

- (void)testAutoreleaseScoped {
  NSString *tmp;
  NSUInteger rc;
  {
    WBScopeAutoreleasePool();
    
    NSString *test = [[NSMutableString alloc] init];
    tmp = [[test retain] autorelease];
    rc = [test retainCount];
  }
  GHAssertTrue(rc - 1 == [tmp retainCount], @"invalid retain count: %u instead of %u", [tmp retainCount], rc - 1);
}

@end
