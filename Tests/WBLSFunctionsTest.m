/*
 *  WBLSFunctionsTest.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <GHUnit/GHUnit.h>
#import "WBLSFunctions.h"

@interface WBLSFunctionsTest : GHTestCase {

}

@end


@implementation WBLSFunctionsTest

- (void)testIsApplication {
  NSString *iTunes = [[NSWorkspace sharedWorkspace] fullPathForApplication:@"iTunes"];
  GHAssertNotNil(iTunes, @"iTunes not found. Cannot test isApplication");
  Boolean isApp = FALSE;
  OSStatus err = WBLSIsApplicationAtPath((CFStringRef)iTunes, &isApp);
  GHAssertTrue(noErr == err, @"WBLSIsApplicationAtPath: %s", GetMacOSStatusCommentString(err));
  GHAssertTrue(isApp, @"iTunes should be an Application");
}

@end
