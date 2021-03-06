/*
 *  WBFunctions.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBFunctions.h>

NSString *WBStringForOSType(OSType type) {
  type = OSSwapHostToBigInt32(type);
  return type ? [[NSString alloc] initWithBytes:&type length:4 encoding:NSMacOSRomanStringEncoding] : nil;
}

OSType WBOSTypeFromString(NSString *type) {
  OSType result = 0;
  if (type && type.length >= 4) {
    [type getBytes:&result maxLength:4 usedLength:NULL encoding:NSMacOSRomanStringEncoding options:0 range:NSMakeRange(0, 4) remainingRange:NULL];
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

// MARK: -

/* From CoreFoundation sources

 Hashing algorithm for CFNumber:
 M = Max CFHashCode (assumed to be unsigned)
 For positive integral values: (N * HASHFACTOR) mod M
 For negative integral values: ((-N) * HASHFACTOR) mod M
 For floating point numbers that are not integral: hash(integral part) + hash(float part * M)
 HASHFACTOR is 2654435761, from Knuth's multiplicative method
 */
#define HASHFACTOR 2654435761U

CFHashCode WBHashInteger(CFIndex i) {
  return ((i > 0) ? (CFHashCode)(i) : (CFHashCode)(-i)) * HASHFACTOR;
}
CFHashCode WBHashDouble(double d) {
  double dInt;
  if (d < 0) d = -d;
  dInt = floor(d+0.5);
  CFHashCode integralHash = HASHFACTOR * (CFHashCode)fmod(dInt, (double)ULONG_MAX);
  return (CFHashCode)(integralHash + (CFHashCode)((d - dInt) * ULONG_MAX));
}
#undef HASHFACTOR

#define ELF_STEP(B) T1 = (H << 4) + B; T2 = T1 & 0xF0000000; if (T2) T1 ^= (T2 >> 24); T1 &= (~T2); H = T1;

CFHashCode WBHashBytes(const uint8_t *bytes, size_t length) {
  /* The ELF hash algorithm, used in the ELF object file format */
  UInt32 H = 0, T1, T2;
  size_t rem = length;
  while (3 < rem) {
    ELF_STEP(bytes[length - rem]);
    ELF_STEP(bytes[length - rem + 1]);
    ELF_STEP(bytes[length - rem + 2]);
    ELF_STEP(bytes[length - rem + 3]);
    rem -= 4;
  }
  switch (rem) {
    case 3:  ELF_STEP(bytes[length - 3]);
      // fallthrough
    case 2:  ELF_STEP(bytes[length - 2]);
      // fallthrough
    case 1:  ELF_STEP(bytes[length - 1]);
      // fallthrough
    case 0:  ;
  }
  return H;
}

#undef ELF_STEP

#pragma mark Base 16
WB_INLINE
CFIndex __WBHexCharToByte(UniChar ch) {
  if (ch >= '0' && ch <= '9') return ch - '0';
  if (ch >= 'a' && ch <= 'f') return 10 + ch - 'a';
  if (ch >= 'A' && ch <= 'F') return 10 + ch - 'A';
  return -1;
}

CFDataRef WBCFDataCreateFromHexString(CFStringRef str) {
  assert(str);
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
      *(bytes++) = (uint8_t)(v1 * 16 + v2);
    else
      isValid = false;
  }
  if (!isValid) {
    CFRelease(data);
    data = NULL;
  }
  return data;
}
