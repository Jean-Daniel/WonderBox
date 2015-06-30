/*
 *  WBLSFunctionsTest.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <XCTest/XCTest.h>

#import "WBLSFunctions.h"

@interface WBLSFunctionsTest : XCTestCase {

}

@end


@implementation WBLSFunctionsTest

- (void)testIsApplication {
  NSString *iTunes = [[NSWorkspace sharedWorkspace] fullPathForApplication:@"iTunes"];
  XCTAssertNotNil(iTunes, @"iTunes not found. Cannot test isApplication");
  Boolean isApp = FALSE;
  OSStatus err = WBLSIsApplicationAtPath(SPXNSToCFString(iTunes), &isApp);
  XCTAssertTrue(noErr == err, @"WBLSIsApplicationAtPath: %s", GetMacOSStatusCommentString(err));
  XCTAssertTrue(isApp, @"iTunes should be an Application");
}

@end
