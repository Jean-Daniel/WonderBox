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
#import "WBScope.h"

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

- (void)testCFScoped {
  CFIndex rc;
  CFStringRef tmp;
  {
    WBScopeCFReleased(CFMutableStringRef, test, CFStringCreateMutable(kCFAllocatorDefault, 0));
    tmp = CFRetain(test);
    rc = CFGetRetainCount(test);
  }
  GHAssertTrue(rc - 1 == CFGetRetainCount(tmp), @"invalid retain count: %u instead of %u", CFGetRetainCount(tmp), rc - 1);
  CFRelease(tmp);

  {
    // Affect after declaration test
    WBScopeCFReleased(CFMutableStringRef, test, NULL);
    test = CFStringCreateMutable(kCFAllocatorDefault, 0);
    tmp = CFRetain(test);
    rc = CFGetRetainCount(test);
  }
  GHAssertTrue(rc - 1 == CFGetRetainCount(tmp), @"invalid retain count: %u instead of %u", CFGetRetainCount(tmp), rc - 1);
  CFRelease(tmp);
}

- (void)testAutoreleaseScoped {
  NSString *tmp;
  NSUInteger rc;
  {
    WBScopeAutoreleasePool();
    WBScopeAutoreleasePool();

    NSString *test = [[NSMutableString alloc] init];
    tmp = [[test retain] autorelease];
    rc = [test retainCount];
  }
  GHAssertTrue(rc - 1 == [tmp retainCount], @"invalid retain count: %u instead of %u", [tmp retainCount], rc - 1);
}

@end
