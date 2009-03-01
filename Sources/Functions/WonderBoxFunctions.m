/*
 *  WonderBoxFunctions.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WonderBoxFunctions.h)

CFStringRef WBCreateStringForOSType(OSType type) {
  type = OSSwapHostToBigInt32(type);
  return (type) ? CFStringCreateWithBytes(kCFAllocatorDefault, (unsigned char *)&type, sizeof(type), kCFStringEncodingMacRoman, FALSE) : nil;
}

OSType WBGetOSTypeFromString(CFStringRef str) {
  OSType result = 0;
  if (str && CFStringGetLength(str) >= 4) {
    CFStringGetBytes(str, CFRangeMake(0, 4), kCFStringEncodingMacRoman, 0, FALSE, (UInt8 *)&result, sizeof(result), NULL);
  }
  return OSSwapBigToHostInt32(result);
}

#pragma mark Versions
SInt32 WBSystemMajorVersion(void) {
  SInt32 macVersion;
  return Gestalt(gestaltSystemVersionMajor, &macVersion) == noErr ? macVersion : 0;
}
SInt32 WBSystemMinorVersion(void) {
  SInt32 macVersion;
  return Gestalt(gestaltSystemVersionMinor, &macVersion) == noErr ? macVersion : 0;
}
SInt32 WBSystemBugFixVersion(void) {
  SInt32 macVersion;
  return Gestalt(gestaltSystemVersionBugFix, &macVersion) == noErr ? macVersion : 0;
}

#pragma mark -
CFComparisonResult WBUTCDateTimeCompare(UTCDateTime *t1, UTCDateTime *t2) {
  if (t1->highSeconds < t2->highSeconds) return kCFCompareLessThan;
  else if (t1->highSeconds > t2->highSeconds) return kCFCompareGreaterThan;

  if (t1->lowSeconds < t2->lowSeconds) return kCFCompareLessThan;
  else if (t1->lowSeconds > t2->lowSeconds) return kCFCompareGreaterThan;

  if (t1->fraction < t2->fraction) return kCFCompareLessThan;
  else if (t1->fraction > t2->fraction) return kCFCompareGreaterThan;
  
  return kCFCompareEqualTo;
}

#pragma mark Base 16
WB_INLINE
CFIndex __WBHexCharToByte(UniChar ch) {
  if (ch >= '0' && ch <= '9') return ch - '0';
  if (ch >= 'a' && ch <= 'f') return 10 + ch - 'a';
  if (ch >= 'A' && ch <= 'F') return 10 + ch - 'A';
  return -1;
}

CFDataRef WBCFDataCreateFromHexString(CFStringRef str) {
  check(str);
  CFIndex length = CFStringGetLength(str);
  /* String length MUST be even */
  if (length % 2)
    return NULL;
  
  CFMutableDataRef data = CFDataCreateMutable(kCFAllocatorDefault, length / 2);
  CFDataSetLength(data, length / 2);
  UInt8 *bytes = CFDataGetMutableBytePtr(data);
  
  bool isValid = true;
  CFStringInlineBuffer buffer;
  CFStringInitInlineBuffer(str, &buffer, CFRangeMake(0, length));
  for (CFIndex idx = 0; isValid && idx < length; idx+=2) {
    CFIndex v1 = __WBHexCharToByte(CFStringGetCharacterFromInlineBuffer(&buffer, idx));
    CFIndex v2 = __WBHexCharToByte(CFStringGetCharacterFromInlineBuffer(&buffer, idx + 1));
    if (v1 >= 0 && v2 >= 0)
      *(bytes++) = v1 * 16 + v2;
    else
      isValid = false;
  }
  if (!isValid) {
    CFRelease(data);
    data = NULL;
  }
  return data;
}
