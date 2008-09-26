//
//  WBLSFunctionsTest.m
//  WonderBox
//
//  Created by Grayfox on 29/07/06.
//  Copyright 2006 Shadow Lab. All rights reserved.
//

#import "WBLSFunctionsTest.h"
#import WBHEADER(WBLSFunctions.h)

@implementation WBLSFunctionsTest

- (void)testIsApplication {
  NSString *iTunes = [[NSWorkspace sharedWorkspace] fullPathForApplication:@"iTunes"];
  STAssertNotNil(iTunes, @"iTunes not found. Cannot test isApplication");
  Boolean isApp = FALSE;
  OSStatus err = WBLSIsApplicationAtPath((CFStringRef)iTunes, &isApp);
  STAssertTrue(noErr == err, @"WBLSIsApplicationAtPath: %s", GetMacOSStatusCommentString(err));
  STAssertTrue(isApp, @"iTunes should be an Application");
}

@end
