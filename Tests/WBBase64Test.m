//
//  WBBase64Test.m
//
//  Copyright 2006-2008 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not
//  use this file except in compliance with the License.  You may obtain a copy
//  of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
//  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
//  License for the specific language governing permissions and limitations under
//  the License.
//

#import <GHUnit/GHUnit.h>
#import "WBBase64.h"
#include <stdlib.h> // for randiom/srandomdev

static void FillWithRandom(UInt8 *data, CFIndex len) {
  UInt8 *max = data + len;
  for ( ; data < max ; ++data) {
    *data = random() & 0xff;
  }
}

static BOOL NoEqualChar(CFDataRef data) {
  const char *scan = (const char *)CFDataGetBytePtr(data);
  const char *max = scan + CFDataGetLength(data);
  for ( ; scan < max ; ++scan) {
    if (*scan == '=') {
      return NO;
    }
  }
  return YES;
}

@interface WBBase64Test : GHTestCase
@end

@implementation WBBase64Test

- (void)setUp {
  // seed random from /dev/random
  srandomdev();
}

- (void)testBase64 {
  // generate a range of sizes w/ random content
  for (int x = 1 ; x < 1024 ; ++x) {
    CFMutableDataRef data = CFDataCreateMutable(kCFAllocatorDefault, 0);
    GHAssertNotNil(WBCFToNSData(data), @"failed to alloc data block");
    CFDataSetLength(data, x);
    FillWithRandom(CFDataGetMutableBytePtr(data), CFDataGetLength(data));

    // w/ *Bytes apis
    CFDataRef encoded = WBBase64CreateDataByEncodingBytes(CFDataGetBytePtr(data), CFDataGetLength(data));
    GHAssertEquals((CFDataGetLength(encoded) % 4), (CFIndex)0,
                   @"encoded size via *Bytes apis should be a multiple of 4");
    CFDataRef dataPrime = WBBase64CreateDataByDecodingBytes(CFDataGetBytePtr(encoded),
                                                            CFDataGetLength(encoded));
    GHAssertEqualObjects(WBCFToNSData(data), WBCFToNSData(dataPrime),
                         @"failed to round trip via *Bytes apis");
    CFRelease(dataPrime);
    CFRelease(encoded);
    // w/ *Data apis
    encoded = WBBase64CreateDataByEncodingData(data);
    GHAssertEquals((CFDataGetLength(encoded) % 4), (CFIndex)0,
                   @"encoded size via *Data apis should be a multiple of 4");

    dataPrime = WBBase64CreateDataByDecodingData(encoded);
    GHAssertEqualObjects(WBCFToNSData(data), WBCFToNSData(dataPrime),
                         @"failed to round trip via *Data apis");
    CFRelease(dataPrime);
    CFRelease(encoded);

    // Bytes to String and back
    CFStringRef encodedString = WBBase64CreateStringByEncodingBytes(CFDataGetBytePtr(data),
                                                                    CFDataGetLength(data));
    GHAssertEquals((CFStringGetLength(encodedString) % 4), (CFIndex)0,
                   @"encoded size for Bytes to Strings should be a multiple of 4");
    dataPrime = WBBase64CreateDataByDecodingString(encodedString);
    GHAssertEqualObjects(WBCFToNSData(data), WBCFToNSData(dataPrime),
                         @"failed to round trip for Bytes to Strings");
    CFRelease(encodedString);
    CFRelease(dataPrime);

    // Data to String and back
    encodedString = WBBase64CreateStringByEncodingData(data);
    GHAssertEquals((CFStringGetLength(encodedString) % 4), (CFIndex)0,
                   @"encoded size for Data to Strings should be a multiple of 4");
    dataPrime = WBBase64CreateDataByDecodingString(encodedString);
    GHAssertEqualObjects(WBCFToNSData(data), WBCFToNSData(dataPrime),
                         @"failed to round trip for Bytes to Strings");
    CFRelease(encodedString);
    CFRelease(dataPrime);
    CFRelease(data);
  }

  {
    // now test all byte values
    CFMutableDataRef data = CFDataCreateMutable(kCFAllocatorDefault, 0);
    GHAssertNotNil(WBCFToNSData(data), @"failed to alloc data block");
    CFDataSetLength(data, 256);
    unsigned char *scan = CFDataGetMutableBytePtr(data);
    for (int x = 0 ; x <= 255 ; ++x) {
      *scan++ = x;
    }

    // w/ *Bytes apis
    CFDataRef encoded = WBBase64CreateDataByEncodingBytes(CFDataGetBytePtr(data),
                                                          CFDataGetLength(data));
    GHAssertEquals((CFDataGetLength(encoded) % 4), (CFIndex)0,
                   @"encoded size via *Bytes apis should be a multiple of 4");
    CFDataRef dataPrime = WBBase64CreateDataByDecodingBytes(CFDataGetBytePtr(encoded),
                                                            CFDataGetLength(encoded));
    GHAssertEqualObjects(WBCFToNSData(data), WBCFToNSData(dataPrime),
                         @"failed to round trip via *Bytes apis");
    CFRelease(dataPrime);
    CFRelease(encoded);

    // w/ *Data apis
    encoded = WBBase64CreateDataByEncodingData(data);
    GHAssertEquals((CFDataGetLength(encoded) % 4), (CFIndex)0,
                   @"encoded size via *Data apis should be a multiple of 4");

    dataPrime = WBBase64CreateDataByDecodingData(encoded);
    GHAssertEqualObjects(WBCFToNSData(data), WBCFToNSData(dataPrime),
                         @"failed to round trip via *Data apis");
    CFRelease(dataPrime);
    CFRelease(encoded);

    // Bytes to String and back
    CFStringRef encodedString = WBBase64CreateStringByEncodingBytes(CFDataGetBytePtr(data),
                                                                    CFDataGetLength(data));
    GHAssertEquals((CFStringGetLength(encodedString) % 4), (CFIndex)0,
                   @"encoded size for Bytes to Strings should be a multiple of 4");
    dataPrime = WBBase64CreateDataByDecodingString(encodedString);
    GHAssertEqualObjects(WBCFToNSData(data), WBCFToNSData(dataPrime),
                         @"failed to round trip for Bytes to Strings");
    CFRelease(encodedString);
    CFRelease(dataPrime);

    // Data to String and back
    encodedString = WBBase64CreateStringByEncodingData(data);
    GHAssertEquals((CFStringGetLength(encodedString) % 4), (CFIndex)0,
                   @"encoded size for Data to Strings should be a multiple of 4");
    dataPrime = WBBase64CreateDataByDecodingString(encodedString);
    GHAssertEqualObjects(WBCFToNSData(data), WBCFToNSData(dataPrime),
                         @"failed to round trip for Bytes to Strings");
    CFRelease(encodedString);
    CFRelease(dataPrime);
    CFRelease(data);
  }

  {
    // test w/ a mix of spacing characters

    // generate some data, encode it, and add spaces
    CFMutableDataRef data = CFDataCreateMutable(kCFAllocatorDefault, 0);
    GHAssertNotNil(WBCFToNSData(data), @"failed to alloc data block");
    CFDataSetLength(data, 253); // should get some padding chars on the end
    FillWithRandom(CFDataGetMutableBytePtr(data), CFDataGetLength(data));

    CFStringRef encodedString = WBBase64CreateStringByEncodingData(data);
    CFMutableStringRef encodedAndSpaced = CFStringCreateMutableCopy(kCFAllocatorDefault, 0, encodedString);
    CFRelease(encodedString);

    CFStringRef spaces[] = { CFSTR("\t"), CFSTR("\n"), CFSTR("\r"), CFSTR(" ") };
    const CFIndex numSpaces = sizeof(spaces) / sizeof(CFStringRef);
    for (int x = 0 ; x < 512 ; ++x) {
      CFIndex offset = random() % (CFStringGetLength(encodedAndSpaced) + 1);
      CFStringInsert(encodedAndSpaced, offset, spaces[random() % numSpaces]);
    }

    // we'll need it as data for apis
    CFDataRef encodedAsData = CFStringCreateExternalRepresentation(kCFAllocatorDefault, encodedAndSpaced,
                                                                   NSASCIIStringEncoding, 0);
    GHAssertNotNil(WBCFToNSData(encodedAsData), @"failed to extract from string");
    GHAssertEquals(CFDataGetLength(encodedAsData), CFStringGetLength(encodedAndSpaced),
                   @"lengths for encoded string and data didn't match?");

    // all the decode modes
    CFDataRef dataPrime = WBBase64CreateDataByDecodingData(encodedAsData);
    GHAssertEqualObjects(WBCFToNSData(data), WBCFToNSData(dataPrime),
                         @"failed Data decode w/ spaces");
    CFRelease(dataPrime);

    dataPrime = WBBase64CreateDataByDecodingBytes(CFDataGetBytePtr(encodedAsData),
                                                  CFDataGetLength(encodedAsData));
    GHAssertEqualObjects(WBCFToNSData(data), WBCFToNSData(dataPrime),
                         @"failed Bytes decode w/ spaces");
    CFRelease(dataPrime);

    dataPrime = WBBase64CreateDataByDecodingString(encodedAndSpaced);
    GHAssertEqualObjects(WBCFToNSData(data), WBCFToNSData(dataPrime),
                         @"failed String decode w/ spaces");

    CFRelease(encodedAndSpaced);
    CFRelease(encodedAsData);
    CFRelease(dataPrime);
    CFRelease(data);
  }
}
#if 0
- (void)testWebSafeBase64 {
  // loop to test w/ and w/o padding
  for (int paddedLoop = 0; paddedLoop < 2 ; ++paddedLoop) {
    BOOL padded = (paddedLoop == 1);

    // generate a range of sizes w/ random content
    for (int x = 1 ; x < 1024 ; ++x) {
      CFMutableDataRef data = [NSMutableData data];
      GHAssertNotNil(data, @"failed to alloc data block");

      [data setLength:x];
      FillWithRandom([data mutableBytes], CFDataGetLength(data));

      // w/ *Bytes apis
      CFDataRef encoded = [WBBase64 webSafeEncodeBytes:CFDataGetBytePtr(data)
                                                length:CFDataGetLength(data)
                                                padded:padded];
      if (padded) {
        GHAssertEquals((CFDataGetLength(encoded) % 4), (CFIndex)0,
                       @"encoded size via *Bytes apis should be a multiple of 4");
      } else {
        GHAssertTrue(NoEqualChar(encoded),
                     @"encoded via *Bytes apis had a base64 padding char");
      }
      CFDataRef dataPrime = [WBBase64 webSafeDecodeBytes:CFDataGetBytePtr(encoded)
                                                  length:CFDataGetLength(encoded)];
      GHAssertEqualObjects(data, dataPrime,
                           @"failed to round trip via *Bytes apis");

      // w/ *Data apis
      encoded = [WBBase64 webSafeEncodeData:data padded:padded];
      if (padded) {
        GHAssertEquals((CFDataGetLength(encoded) % 4), (CFIndex)0,
                       @"encoded size via *Data apis should be a multiple of 4");
      } else {
        GHAssertTrue(NoEqualChar(encoded),
                     @"encoded via *Data apis had a base64 padding char");
      }
      dataPrime = [WBBase64 webSafeDecodeData:encoded];
      GHAssertEqualObjects(data, dataPrime,
                           @"failed to round trip via *Data apis");

      // Bytes to String and back
      NSString *encodedString =
      [WBBase64 stringByWebSafeEncodingBytes:CFDataGetBytePtr(data)
                                      length:CFDataGetLength(data)
                                      padded:padded];
      if (padded) {
        GHAssertEquals((CFDataGetLength(encoded) % 4), (CFIndex)0,
                       @"encoded size via *Bytes apis should be a multiple of 4");
      } else {
        GHAssertTrue(NoEqualChar(encoded),
                     @"encoded via Bytes to Strings had a base64 padding char");
      }
      dataPrime = [WBBase64 webSafeDecodeString:encodedString];
      GHAssertEqualObjects(data, dataPrime,
                           @"failed to round trip for Bytes to Strings");

      // Data to String and back
      encodedString =
      [WBBase64 stringByWebSafeEncodingData:data padded:padded];
      if (padded) {
        GHAssertEquals((CFDataGetLength(encoded) % 4), (CFIndex)0,
                       @"encoded size via *Data apis should be a multiple of 4");
      } else {
        GHAssertTrue(NoEqualChar(encoded),
                     @"encoded via Data to Strings had a base64 padding char");
      }
      dataPrime = [WBBase64 webSafeDecodeString:encodedString];
      GHAssertEqualObjects(data, dataPrime,
                           @"failed to round trip for Data to Strings");
    }

    {
      // now test all byte values
      CFMutableDataRef data = [NSMutableData data];
      GHAssertNotNil(data, @"failed to alloc data block");

      [data setLength:256];
      unsigned char *scan = (unsigned char*)[data mutableBytes];
      for (int x = 0 ; x <= 255 ; ++x) {
        *scan++ = x;
      }

      // w/ *Bytes apis
      CFDataRef encoded =
      [WBBase64 webSafeEncodeBytes:CFDataGetBytePtr(data)
                            length:CFDataGetLength(data)
                            padded:padded];
      if (padded) {
        GHAssertEquals((CFDataGetLength(encoded) % 4), (CFIndex)0,
                       @"encoded size via *Bytes apis should be a multiple of 4");
      } else {
        GHAssertTrue(NoEqualChar(encoded),
                     @"encoded via *Bytes apis had a base64 padding char");
      }
      CFDataRef dataPrime = [WBBase64 webSafeDecodeBytes:CFDataGetBytePtr(encoded)
                                                  length:CFDataGetLength(encoded)];
      GHAssertEqualObjects(data, dataPrime,
                           @"failed to round trip via *Bytes apis");

      // w/ *Data apis
      encoded = [WBBase64 webSafeEncodeData:data padded:padded];
      if (padded) {
        GHAssertEquals((CFDataGetLength(encoded) % 4), (CFIndex)0,
                       @"encoded size via *Data apis should be a multiple of 4");
      } else {
        GHAssertTrue(NoEqualChar(encoded),
                     @"encoded via *Data apis had a base64 padding char");
      }
      dataPrime = [WBBase64 webSafeDecodeData:encoded];
      GHAssertEqualObjects(data, dataPrime,
                           @"failed to round trip via *Data apis");

      // Bytes to String and back
      NSString *encodedString =
      [WBBase64 stringByWebSafeEncodingBytes:CFDataGetBytePtr(data)
                                      length:CFDataGetLength(data)
                                      padded:padded];
      if (padded) {
        GHAssertEquals((CFDataGetLength(encoded) % 4), (CFIndex)0,
                       @"encoded size via *Bytes apis should be a multiple of 4");
      } else {
        GHAssertTrue(NoEqualChar(encoded),
                     @"encoded via Bytes to Strings had a base64 padding char");
      }
      dataPrime = [WBBase64 webSafeDecodeString:encodedString];
      GHAssertEqualObjects(data, dataPrime,
                           @"failed to round trip for Bytes to Strings");

      // Data to String and back
      encodedString =
      [WBBase64 stringByWebSafeEncodingData:data padded:padded];
      if (padded) {
        GHAssertEquals((CFDataGetLength(encoded) % 4), (CFIndex)0,
                       @"encoded size via *Data apis should be a multiple of 4");
      } else {
        GHAssertTrue(NoEqualChar(encoded),
                     @"encoded via Data to Strings had a base64 padding char");
      }
      dataPrime = [WBBase64 webSafeDecodeString:encodedString];
      GHAssertEqualObjects(data, dataPrime,
                           @"failed to round trip for Data to Strings");
    }

    {
      // test w/ a mix of spacing characters

      // generate some data, encode it, and add spaces
      CFMutableDataRef data = [NSMutableData data];
      GHAssertNotNil(data, @"failed to alloc data block");

      [data setLength:253]; // should get some padding chars on the end
      FillWithRandom([data mutableBytes], CFDataGetLength(data));

      NSString *encodedString = [WBBase64 stringByWebSafeEncodingData:data
                                                               padded:padded];
      NSMutableString *encodedAndSpaced =
      [[encodedString mutableCopy] autorelease];

      NSString *spaces[] = { @"\t", @"\n", @"\r", @" " };
      const CFIndex numSpaces = sizeof(spaces) / sizeof(NSString*);
      for (int x = 0 ; x < 512 ; ++x) {
        CFIndex offset = random() % ([encodedAndSpaced length] + 1);
        [encodedAndSpaced insertString:spaces[random() % numSpaces]
                               atIndex:offset];
      }

      // we'll need it as data for apis
      CFDataRef encodedAsData =
      [encodedAndSpaced dataUsingEncoding:NSASCIIStringEncoding];
      GHAssertNotNil(encodedAsData, @"failed to extract from string");
      GHAssertEquals([encodedAsData length], [encodedAndSpaced length],
                     @"lengths for encoded string and data didn't match?");

      // all the decode modes
      CFDataRef dataPrime = [WBBase64 webSafeDecodeData:encodedAsData];
      GHAssertEqualObjects(data, dataPrime,
                           @"failed Data decode w/ spaces");
      dataPrime = [WBBase64 webSafeDecodeBytes:[encodedAsData bytes]
                                        length:[encodedAsData length]];
      GHAssertEqualObjects(data, dataPrime,
                           @"failed Bytes decode w/ spaces");
      dataPrime = [WBBase64 webSafeDecodeString:encodedAndSpaced];
      GHAssertEqualObjects(data, dataPrime,
                           @"failed String decode w/ spaces");
    }
  } // paddedLoop
}

#endif

- (void)testErrors {
  const int something = 0;
  CFStringRef nonAscString = CFSTR("This test ©™®๒०᠐٧");

  GHAssertNil(WBCFToNSData(WBBase64CreateDataByEncodingData(NULL)), @"it worked?");
  GHAssertNil(WBCFToNSData(WBBase64CreateDataByDecodingData(NULL)), @"it worked?");
  GHAssertNil(WBCFToNSData(WBBase64CreateDataByEncodingBytes(NULL, 10)), @"it worked?");
  GHAssertNil(WBCFToNSData(WBBase64CreateDataByEncodingBytes(&something, 0)), @"it worked?");
  GHAssertNil(WBCFToNSData(WBBase64CreateDataByDecodingBytes(NULL, 10)), @"it worked?");
  GHAssertNil(WBCFToNSData(WBBase64CreateDataByDecodingBytes(&something, 0)), @"it worked?");
  GHAssertNil(WBCFToNSString(WBBase64CreateStringByEncodingData(NULL)), @"it worked?");
  GHAssertNil(WBCFToNSString(WBBase64CreateStringByEncodingBytes(NULL, 10)), @"it worked?");
  GHAssertNil(WBCFToNSString(WBBase64CreateStringByEncodingBytes(&something, 0)), @"it worked?");
  GHAssertNil(WBCFToNSData(WBBase64CreateDataByDecodingString(NULL)), @"it worked?");
  // test some pads at the end that aren't right
  GHAssertNil(WBCFToNSData(WBBase64CreateDataByDecodingString(CFSTR("=="))), @"it worked?"); // just pads
  GHAssertNil(WBCFToNSData(WBBase64CreateDataByDecodingString(CFSTR("vw="))), @"it worked?"); // missing pad (in state 2)
  GHAssertNil(WBCFToNSData(WBBase64CreateDataByDecodingString(CFSTR("vw"))), @"it worked?"); // missing pad (in state 2)
  GHAssertNil(WBCFToNSData(WBBase64CreateDataByDecodingString(CFSTR("NNw"))), @"it worked?"); // missing pad (in state 3)
  GHAssertNil(WBCFToNSData(WBBase64CreateDataByDecodingString(CFSTR("vw=v"))), @"it worked?"); // missing pad, has something else
  GHAssertNil(WBCFToNSData(WBBase64CreateDataByDecodingString(CFSTR("v="))), @"it worked?"); // missing a needed char, has pad instead
  GHAssertNil(WBCFToNSData(WBBase64CreateDataByDecodingString(CFSTR("v"))), @"it worked?"); // missing a needed char
  GHAssertNil(WBCFToNSData(WBBase64CreateDataByDecodingString(CFSTR("vw== vw"))), @"it worked?");
  GHAssertNil(WBCFToNSData(WBBase64CreateDataByDecodingString(nonAscString)), @"it worked?");
  GHAssertNil(WBCFToNSData(WBBase64CreateDataByDecodingString(CFSTR("@@@not valid###"))), @"it worked?");
  // carefully crafted bad input to make sure we don't overwalk
  GHAssertNil(WBCFToNSData(WBBase64CreateDataByDecodingString(CFSTR("WD=="))), @"it worked?");
#if 0
  GHAssertNil([WBBase64 webSafeEncodeData:nil padded:YES], @"it worked?");
  GHAssertNil([WBBase64 webSafeDecodeData:nil], @"it worked?");
  GHAssertNil([WBBase64 webSafeEncodeBytes:NULL length:10 padded:YES],
              @"it worked?");
  GHAssertNil([WBBase64 webSafeEncodeBytes:&something length:0 padded:YES],
              @"it worked?");
  GHAssertNil([WBBase64 webSafeDecodeBytes:NULL length:10], @"it worked?");
  GHAssertNil([WBBase64 webSafeDecodeBytes:&something length:0], @"it worked?");
  GHAssertNil([WBBase64 stringByWebSafeEncodingData:nil padded:YES],
              @"it worked?");
  GHAssertNil([WBBase64 stringByWebSafeEncodingBytes:NULL
                                              length:10
                                              padded:YES],
              @"it worked?");
  GHAssertNil([WBBase64 stringByWebSafeEncodingBytes:&something
                                              length:0
                                              padded:YES],
              @"it worked?");
  GHAssertNil([WBBase64 webSafeDecodeString:nil], @"it worked?");
  // test some pads at the end that aren't right
  GHAssertNil([WBBase64 webSafeDecodeString:@"=="], @"it worked?"); // just pad chars
  GHAssertNil([WBBase64 webSafeDecodeString:@"aw="], @"it worked?"); // missing pad
  GHAssertNil([WBBase64 webSafeDecodeString:@"aw=a"], @"it worked?"); // missing pad, has something else
  GHAssertNil([WBBase64 webSafeDecodeString:@"a"], @"it worked?"); // missing a needed char
  GHAssertNil([WBBase64 webSafeDecodeString:@"a="], @"it worked?"); // missing a needed char, has pad instead
  GHAssertNil([WBBase64 webSafeDecodeString:@"aw== a"], @"it worked?"); // missing pad
  GHAssertNil([WBBase64 webSafeDecodeString:nonAscString], @"it worked?");
  GHAssertNil([WBBase64 webSafeDecodeString:@"@@@not valid###"], @"it worked?");
  // carefully crafted bad input to make sure we don't overwalk
  GHAssertNil([WBBase64 webSafeDecodeString:@"WD=="], @"it worked?");
#endif
  // make sure our local helper is working right
  GHAssertFalse(NoEqualChar(WBNSToCFData([NSData dataWithBytes:"aa=zz" length:5])), @"");
}

@end
