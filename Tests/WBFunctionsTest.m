/*
 *  WBFunctionsTest.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <SenTestingKit/SenTestingKit.h>

#import "WBFunctions.h"
#import "WBObjCRuntime.h"
#import "WBVersionFunctions.h"

@interface WBFunctionsTest : SenTestCase {

}

@end


@implementation WBFunctionsTest

- (void)testDataFromHexString {
  CFDataRef data = WBCFDataCreateFromHexString(CFSTR("12af1b5a4c2d84"));
  STAssertNotNil(SPXCFToNSData(data), @"error while creating data");
  STAssertTrue(CFDataGetLength(data) == 7, @"invalid data length: %ld", (long)CFDataGetLength(data));
  const UInt8 *bytes = CFDataGetBytePtr(data);
  const char ref[] = { 0x12, 0xaf, 0x1b, 0x5a, 0x4c, 0x2d, 0x84 };
  STAssertTrue(memcmp(bytes, ref, 7) == 0, @"Invalid data value");

  CFRelease(data);
}

- (void)testWBVersionGetNumberFromString {
  UInt64 vers = WBVersionGetNumberFromString(CFSTR("0.0.0d0"));
  STAssertTrue(0 == vers, @"WBVersionGetNumberFromString(0.0.0d0) => 0x%qx", vers);

  vers = WBVersionGetNumberFromString(CFSTR("0.0.0a1"));
  STAssertTrue(0x0000000000002001 == vers, @"WBVersionGetNumberFromString(0.0.0a1) => 0x%.16qx", vers);

  vers = WBVersionGetNumberFromString(CFSTR("2.0"));
  STAssertTrue(0x0002000000008000 == vers, @"WBVersionGetNumberFromString(2.0) => 0x%.16qx", vers);

  vers = WBVersionGetNumberFromString(CFSTR("2.0b"));
  STAssertTrue(0x0002000000004000 == vers, @"WBVersionGetNumberFromString(2.0b) => 0x%.16qx", vers);

  vers = WBVersionGetNumberFromString(CFSTR("2.0r0"));
  STAssertTrue(0x0002000000008000 == vers, @"WBVersionGetNumberFromString(2.0) => 0x%.16qx", vers);

  vers = WBVersionGetNumberFromString(CFSTR("2.0f1"));
  STAssertTrue(0x0002000000008001 == vers, @"WBVersionGetNumberFromString(2.0) => 0x%.16qx", vers);

  vers = WBVersionGetNumberFromString(CFSTR("0.0.1"));
  STAssertTrue(0x0000000000018000 == vers, @"WBVersionGetNumberFromString(0.0.1) => 0x%.16qx", vers);

  vers = WBVersionGetNumberFromString(CFSTR("0.0.0r15"));
  STAssertTrue(0x000000000000800f == vers, @"WBVersionGetNumberFromString(0.0.0r15) => 0x%.16qx", vers);

  vers = WBVersionGetNumberFromString(CFSTR("12.10rc1"));
  STAssertTrue(0x000c000a00006001 == vers, @"WBVersionGetNumberFromString(12.10rc1) => 0x%.16qx", vers);

  vers = WBVersionGetNumberFromString(CFSTR("12.10rb"));
  STAssertTrue(kWBVersionInvalid == vers, @"WBVersionGetNumberFromString(12.10rb) => 0x%.16qx", vers);

  vers = WBVersionGetNumberFromString(CFSTR("12.10b1"));
  STAssertTrue(0x000c000a00004001 == vers, @"WBVersionGetNumberFromString(12.10b1) => 0x%.16qx", vers);
}

- (void)testWBVersionCreateString {
  CFStringRef str;
  str = WBVersionCreateStringForNumber(0x000c000a00004001);
  STAssertNotNil(SPXCFToNSString(str), @"WBVersionCreateStringForNumber");
  STAssertEqualObjects(SPXCFToNSString(str), @"12.10b1", @"WBVersionCreateStringForNumber() => %@", str);
  if (str) CFRelease(str);

  str = WBVersionCreateStringForNumber(0x0000000000002001);
  STAssertNotNil(SPXCFToNSString(str), @"WBVersionCreateStringForNumber");
  STAssertEqualObjects(SPXCFToNSString(str), @"0.0a1", @"WBVersionCreateStringForNumber() => %@", str);
  if (str) CFRelease(str);

  str = WBVersionCreateStringForNumber(0x0002000000004000);
  STAssertNotNil(SPXCFToNSString(str), @"WBVersionCreateStringForNumber");
  STAssertEqualObjects(SPXCFToNSString(str), @"2.0b", @"WBVersionCreateStringForNumber() => %@", str);
  if (str) CFRelease(str);
}

static inline
bool _CFArrayContainsClass(CFArrayRef classes, Class cls) {
  return CFArrayContainsValue(classes, CFRangeMake(0, CFArrayGetCount(classes)), (__bridge void *)cls);
}
- (void)testWBRuntime {
  CFArrayRef classes = WBRuntimeCopySubclasses([self class], YES);
  STAssertTrue(CFArrayGetCount(classes) == 0, @"invalid sublclass result");
  CFRelease(classes);

  classes = WBRuntimeCopySubclasses([NSArray class], YES);
  STAssertTrue(CFArrayGetCount(classes) > 1, @"invalid sublclass result: %@", classes);
  STAssertTrue(_CFArrayContainsClass(classes, [NSMutableArray class]), @"invalid sublclass result");
  STAssertTrue(!_CFArrayContainsClass(classes, NSClassFromString(@"NSCFArray")), @"invalid sublclass result");
  CFRelease(classes);

  classes = WBRuntimeCopySubclasses([NSArray class], NO);
  STAssertTrue(CFArrayGetCount(classes) > 1, @"invalid sublclass result");
  STAssertTrue(_CFArrayContainsClass(classes, NSClassFromString(@"NSCFArray")), @"invalid sublclass result");
  CFRelease(classes);
}

@end
