/*
 *  WBLSFunctionsTest.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <SenTestingKit/SenTestingKit.h>

#import "WBLSFunctions.h"

@interface WBLSFunctionsTest : SenTestCase {

}

@end


@implementation WBLSFunctionsTest

- (void)testIsApplication {
  NSString *iTunes = [[NSWorkspace sharedWorkspace] fullPathForApplication:@"iTunes"];
  STAssertNotNil(iTunes, @"iTunes not found. Cannot test isApplication");
  Boolean isApp = FALSE;
  OSStatus err = WBLSIsApplicationAtPath(SPXNSToCFString(iTunes), &isApp);
  STAssertTrue(noErr == err, @"WBLSIsApplicationAtPath: %s", GetMacOSStatusCommentString(err));
  STAssertTrue(isApp, @"iTunes should be an Application");
}

@end
