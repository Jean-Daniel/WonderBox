/*
 *  WBBase64.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBBase64.h>

static const char *kBase64EncodeChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static const char *kWebSafeBase64EncodeChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
static const char kBase64PaddingChar = '=';
static const char kBase64InvalidChar = 99;

static const char kBase64DecodeChars[] = {
// This array was generated by the following code:
// #include <sys/time.h>
// #include <stdlib.h>
// #include <string.h>
// main()
// {
//   static const char Base64[] =
//     "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
//   char *pos;
//   int idx, i, j;
//   printf("    ");
//   for (i = 0; i < 255; i += 8) {
//     for (j = i; j < i + 8; j++) {
//       pos = strchr(Base64, j);
//       if ((pos == NULL) || (j == 0))
//         idx = 99;
//       else
//         idx = pos - Base64;
//       if (idx == 99)
//         printf(" %2d,     ", idx);
//       else
//         printf(" %2d/*%c*/,", idx, j);
//     }
//     printf("\n    ");
//   }
// }
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      62/*+*/, 99,      99,      99,      63/*/ */,
52/*0*/, 53/*1*/, 54/*2*/, 55/*3*/, 56/*4*/, 57/*5*/, 58/*6*/, 59/*7*/,
60/*8*/, 61/*9*/, 99,      99,      99,      99,      99,      99,
99,       0/*A*/,  1/*B*/,  2/*C*/,  3/*D*/,  4/*E*/,  5/*F*/,  6/*G*/,
7/*H*/,  8/*I*/,  9/*J*/, 10/*K*/, 11/*L*/, 12/*M*/, 13/*N*/, 14/*O*/,
15/*P*/, 16/*Q*/, 17/*R*/, 18/*S*/, 19/*T*/, 20/*U*/, 21/*V*/, 22/*W*/,
23/*X*/, 24/*Y*/, 25/*Z*/, 99,      99,      99,      99,      99,
99,      26/*a*/, 27/*b*/, 28/*c*/, 29/*d*/, 30/*e*/, 31/*f*/, 32/*g*/,
33/*h*/, 34/*i*/, 35/*j*/, 36/*k*/, 37/*l*/, 38/*m*/, 39/*n*/, 40/*o*/,
41/*p*/, 42/*q*/, 43/*r*/, 44/*s*/, 45/*t*/, 46/*u*/, 47/*v*/, 48/*w*/,
49/*x*/, 50/*y*/, 51/*z*/, 99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99
};

static const char kWebSafeBase64DecodeChars[] = {
// This array was generated by the following code:
// #include <sys/time.h>
// #include <stdlib.h>
// #include <string.h>
// main()
// {
//   static const char Base64[] =
//     "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
//   char *pos;
//   int idx, i, j;
//   printf("    ");
//   for (i = 0; i < 255; i += 8) {
//     for (j = i; j < i + 8; j++) {
//       pos = strchr(Base64, j);
//       if ((pos == NULL) || (j == 0))
//         idx = 99;
//       else
//         idx = pos - Base64;
//       if (idx == 99)
//         printf(" %2d,     ", idx);
//       else
//         printf(" %2d/*%c*/,", idx, j);
//     }
//     printf("\n    ");
//   }
// }
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      62/*-*/, 99,      99,
52/*0*/, 53/*1*/, 54/*2*/, 55/*3*/, 56/*4*/, 57/*5*/, 58/*6*/, 59/*7*/,
60/*8*/, 61/*9*/, 99,      99,      99,      99,      99,      99,
99,       0/*A*/,  1/*B*/,  2/*C*/,  3/*D*/,  4/*E*/,  5/*F*/,  6/*G*/,
7/*H*/,  8/*I*/,  9/*J*/, 10/*K*/, 11/*L*/, 12/*M*/, 13/*N*/, 14/*O*/,
15/*P*/, 16/*Q*/, 17/*R*/, 18/*S*/, 19/*T*/, 20/*U*/, 21/*V*/, 22/*W*/,
23/*X*/, 24/*Y*/, 25/*Z*/, 99,      99,      99,      99,      63/*_*/,
99,      26/*a*/, 27/*b*/, 28/*c*/, 29/*d*/, 30/*e*/, 31/*f*/, 32/*g*/,
33/*h*/, 34/*i*/, 35/*j*/, 36/*k*/, 37/*l*/, 38/*m*/, 39/*n*/, 40/*o*/,
41/*p*/, 42/*q*/, 43/*r*/, 44/*s*/, 45/*t*/, 46/*u*/, 47/*v*/, 48/*w*/,
49/*x*/, 50/*y*/, 51/*z*/, 99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99,
99,      99,      99,      99,      99,      99,      99,      99
};


// Tests a character to see if it's a whitespace character.
//
// Returns:
//   YES if the character is a whitespace character.
//   NO if the character is not a whitespace character.
//
WB_INLINE
bool IsSpace(unsigned char c) {
  // we use our own mapping here because we don't want anything w/ locale
  // support.
  static uint8_t kSpaces[256] = {
    0, 0, 0, 0, 0, 0, 0, 0, 0, 1,  // 0-9
    1, 1, 1, 1, 0, 0, 0, 0, 0, 0,  // 10-19
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 20-29
    0, 0, 1, 0, 0, 0, 0, 0, 0, 0,  // 30-39
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 40-49
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 50-59
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 60-69
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 70-79
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 80-89
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 90-99
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 100-109
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 110-119
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 120-129
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 130-139
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 140-149
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 150-159
    1, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 160-169
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 170-179
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 180-189
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 190-199
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 200-209
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 210-219
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 220-229
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 230-239
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 240-249
    0, 0, 0, 0, 0, 1,              // 250-255
  };
  return kSpaces[c];
}

// Calculate how long the data will be once it's base64 encoded.
//
// Returns:
//   The guessed encoded length for a source length
//
WB_INLINE
CFIndex CalcEncodedLength(CFIndex srcLen, bool padded) {
  CFIndex intermediate_result = 8 * srcLen + 5;
  CFIndex len = intermediate_result / 6;
  if (padded) {
    len = ((len + 3) / 4) * 4;
  }
  return len;
}

// Tries to calculate how long the data will be once it's base64 decoded.
// Unlike the above, this is always an upperbound, since the source data
// could have spaces and might end with the padding characters on them.
//
// Returns:
//   The guessed decoded length for a source length
//
WB_INLINE
CFIndex GuessDecodedLength(CFIndex srcLen) {
  return (srcLen + 3) / 4 * 3;
}

static
CFDataRef _WBBase64CreateDataByEncodingBytes(const void *bytes, CFIndex length,
                                             const char *charset, bool padded);
static
CFDataRef _WBBase64CreateDataByDecodingBytes(const void *bytes, CFIndex length,
                                             const char *charset, bool requirePadding);

static
CFIndex _WBBase64EncodeBytes(const char *srcBytes, CFIndex srcLen,
                             UInt8 *destBytes, CFIndex destLen,
                             const char *charset, bool padded);

static
CFIndex _WBBase64DecodeBytes(const char *srcBytes, CFIndex srcLen,
                             UInt8 *destBytes, CFIndex destLen,
                             const char *charset, bool requirePadding);


//
// Standard Base64 (RFC) handling
//

CFDataRef WBBase64CreateDataByEncodingData(CFDataRef data) {
  if (!data) return NULL;
  return _WBBase64CreateDataByEncodingBytes(CFDataGetBytePtr(data),
                                            CFDataGetLength(data),
                                            kBase64EncodeChars, true);
}

CFDataRef WBBase64CreateDataByDecodingData(CFDataRef data) {
  if (!data) return NULL;
  return _WBBase64CreateDataByDecodingBytes(CFDataGetBytePtr(data),
                                            CFDataGetLength(data),
                                            kBase64DecodeChars, true);
}

CFDataRef WBBase64CreateDataByEncodingBytes(const void *bytes, CFIndex length) {
  return _WBBase64CreateDataByEncodingBytes(bytes, length, kBase64EncodeChars, true);
}

CFDataRef WBBase64CreateDataByDecodingBytes(const void *bytes, CFIndex length) {
  return _WBBase64CreateDataByDecodingBytes(bytes, length, kBase64DecodeChars, true);
}

CFStringRef WBBase64CreateStringByEncodingData(CFDataRef data) {
  if (!data) return NULL;
  CFStringRef result = NULL;
  CFDataRef converted = _WBBase64CreateDataByEncodingBytes(CFDataGetBytePtr(data),
                                                           CFDataGetLength(data),
                                                           kBase64EncodeChars, true);
  if (converted) {
    result = CFStringCreateWithBytes(kCFAllocatorDefault, CFDataGetBytePtr(converted),
                                     CFDataGetLength(converted), kCFStringEncodingASCII, false);
    CFRelease(converted);
  }
  return result;
}

CFStringRef WBBase64CreateStringByEncodingBytes(const void *bytes, CFIndex length) {
  CFStringRef result = nil;
  CFDataRef converted = _WBBase64CreateDataByEncodingBytes(bytes, length,
                                                           kBase64EncodeChars, true);
  if (converted) {
    result = CFStringCreateWithBytes(kCFAllocatorDefault, CFDataGetBytePtr(converted),
                                     CFDataGetLength(converted), kCFStringEncodingASCII, false);
    CFRelease(converted);
  }
  return result;
}

CFDataRef WBBase64CreateDataByDecodingString(CFStringRef string) {
  if (!string) return NULL;
  CFDataRef result = NULL;
  CFDataRef data = CFStringCreateExternalRepresentation(kCFAllocatorDefault, string,
                                                        kCFStringEncodingASCII, 0);
  if (data) {
    result = _WBBase64CreateDataByDecodingBytes(CFDataGetBytePtr(data),
                                                CFDataGetLength(data),
                                                kBase64DecodeChars, true);
    CFRelease(data);
  }
  return result;
}

//
// Modified Base64 encoding so the results can go onto urls.
//
// The changes are in the characters generated and also the result isn't
// padded to a multiple of 4.
// Must use the matching call to encode/decode, won't interop with the
// RFC versions.
//

CFDataRef WBWSBase64CreateDataByEncodingData(CFDataRef data, bool padded) {
  if (!data) return NULL;
  return _WBBase64CreateDataByEncodingBytes(CFDataGetBytePtr(data),
                                            CFDataGetLength(data),
                                            kWebSafeBase64EncodeChars, padded);
}

CFDataRef WBWSBase64CreateDataByDecodingData(CFDataRef data) {
  if (!data) return NULL;
  return _WBBase64CreateDataByDecodingBytes(CFDataGetBytePtr(data),
                                            CFDataGetLength(data),
                                            kWebSafeBase64DecodeChars, false);
}

CFDataRef WBWSBase64CreateDataByEncodingBytes(const void *bytes, CFIndex length, bool padded) {
  return _WBBase64CreateDataByEncodingBytes(bytes, length, kWebSafeBase64EncodeChars, padded);
}

CFDataRef WBWSBase64CreateDataByDecodingBytes(const void *bytes, CFIndex length) {
  return _WBBase64CreateDataByDecodingBytes(bytes, length, kWebSafeBase64DecodeChars, false);
}

CFStringRef WBWSBase64CreateStringByEncodingData(CFDataRef data, bool padded) {
  if (!data) return NULL;
  CFStringRef result = NULL;
  CFDataRef converted = _WBBase64CreateDataByEncodingBytes(CFDataGetBytePtr(data),
                                                           CFDataGetLength(data),
                                                           kWebSafeBase64EncodeChars, padded);
  if (converted) {
    result = CFStringCreateWithBytes(kCFAllocatorDefault, CFDataGetBytePtr(converted),
                                     CFDataGetLength(converted), kCFStringEncodingASCII, false);
    CFRelease(converted);
  }
  return result;
}

CFStringRef WBWSBase64CreateStringByEncodingBytes(const void *bytes, CFIndex length, bool padded) {
  CFStringRef result = nil;
  CFDataRef converted = _WBBase64CreateDataByEncodingBytes(bytes, length,
                                                           kWebSafeBase64EncodeChars, padded);
  if (converted) {
    result = CFStringCreateWithBytes(kCFAllocatorDefault, CFDataGetBytePtr(converted),
                                     CFDataGetLength(converted), kCFStringEncodingASCII, false);
    CFRelease(converted);
  }
  return result;
}

CFDataRef WBWSBase64CreateDataByDecodingString(CFStringRef string) {
  if (!string) return NULL;
  CFDataRef result = NULL;
  CFDataRef data = CFStringCreateExternalRepresentation(kCFAllocatorDefault, string,
                                                        kCFStringEncodingASCII, 0);
  if (data) {
    result = _WBBase64CreateDataByDecodingBytes(CFDataGetBytePtr(data),
                                                CFDataGetLength(data),
                                                kWebSafeBase64DecodeChars, false);
    CFRelease(data);
  }
  return result;
}


#pragma mark -
//
// baseEncode:length:charset:padded:
//
// Does the common lifting of creating the dest NSData.  it creates & sizes the
// data for the results.  |charset| is the characters to use for the encoding
// of the data.  |padding| controls if the encoded data should be padded to a
// multiple of 4.
//
// Returns:
//   an autorelease NSData with the encoded data, nil if any error.
//
CFDataRef _WBBase64CreateDataByEncodingBytes(const void *bytes, CFIndex length,
                                             const char *charset, bool padded) {
  // how big could it be?
  CFIndex maxLength = CalcEncodedLength(length, padded);
  // make space
  CFMutableDataRef result = CFDataCreateMutable(kCFAllocatorDefault, maxLength);
  CFDataSetLength(result, maxLength);
  // do it
  CFIndex finalLength = _WBBase64EncodeBytes(bytes, length,
                                             CFDataGetMutableBytePtr(result),
                                             CFDataGetLength(result),
                                             charset, padded);
  if (finalLength) {
    spx_assert(finalLength == maxLength, "how did we calc the length wrong?");
  } else {
    CFRelease(result);
    // shouldn't happen, this means we ran out of space
    result = NULL;
  }
  return result;
}

//
// baseDecode:length:charset:requirePadding:
//
// Does the common lifting of creating the dest NSData.  it creates & sizes the
// data for the results.  |charset| is the characters to use for the decoding
// of the data.
//
// Returns:
//   an autorelease NSData with the decoded data, nil if any error.
//
//
CFDataRef _WBBase64CreateDataByDecodingBytes(const void *bytes, CFIndex length,
                                             const char *charset, bool requirePadding) {
  // could try to calculate what it will end up as
  CFIndex maxLength = GuessDecodedLength(length);
  // make space
  CFMutableDataRef result = CFDataCreateMutable(kCFAllocatorDefault, maxLength);
  CFDataSetLength(result, maxLength);
  // do it
  CFIndex finalLength = _WBBase64DecodeBytes(bytes, length,
                                             CFDataGetMutableBytePtr(result),
                                             CFDataGetLength(result),
                                             charset, requirePadding);
  if (finalLength) {
    if (finalLength != maxLength) {
      // resize down to how big it was
      CFDataSetLength(result, finalLength);
    }
  } else {
    // either an error in the args, or we ran out of space
    CFRelease(result);
    result = NULL;
  }
  return result;
}

//
// baseEncode:srcLen:destBytes:destLen:charset:padded:
//
// Encodes the buffer into the larger.  returns the length of the encoded
// data, or zero for an error.
// |charset| is the characters to use for the encoding
// |padded| tells if the result should be padded to a multiple of 4.
//
// Returns:
//   the length of the encoded data.  zero if any error.
//
CFIndex _WBBase64EncodeBytes(const char *srcBytes, CFIndex srcLen,
                             UInt8 *destBytes, CFIndex destLen,
                             const char *charset, bool padded) {
  if (!srcLen || !destLen || !srcBytes || !destBytes) {
    return 0;
  }

  UInt8 *curDest = destBytes;
  const unsigned char *curSrc = (const unsigned char *)(srcBytes);

  // Three bytes of data encodes to four characters of cyphertext.
  // So we can pump through three-byte chunks atomically.
  while (srcLen > 2) {
    // space?
    spx_assert(destLen >= 4, "our calc for encoded length was wrong");
    curDest[0] = charset[curSrc[0] >> 2];
    curDest[1] = charset[((curSrc[0] & 0x03) << 4) + (curSrc[1] >> 4)];
    curDest[2] = charset[((curSrc[1] & 0x0f) << 2) + (curSrc[2] >> 6)];
    curDest[3] = charset[curSrc[2] & 0x3f];

    curDest += 4;
    curSrc += 3;
    srcLen -= 3;
    destLen -= 4;
  }

  // now deal with the tail (<=2 bytes)
  switch (srcLen) {
    case 0:
      // Nothing left; nothing more to do.
      break;
    case 1:
      // One byte left: this encodes to two characters, and (optionally)
      // two pad characters to round out the four-character cypherblock.
      spx_assert(destLen >= 2, "our calc for encoded length was wrong");
      curDest[0] = charset[curSrc[0] >> 2];
      curDest[1] = charset[(curSrc[0] & 0x03) << 4];
      curDest += 2;
      destLen -= 2;
      if (padded) {
        spx_assert(destLen >= 2, "our calc for encoded length was wrong");
        curDest[0] = kBase64PaddingChar;
        curDest[1] = kBase64PaddingChar;
        curDest += 2;
        destLen -= 2;
      }
      break;
    case 2:
      // Two bytes left: this encodes to three characters, and (optionally)
      // one pad character to round out the four-character cypherblock.
      spx_assert(destLen >= 3, "our calc for encoded length was wrong");
      curDest[0] = charset[curSrc[0] >> 2];
      curDest[1] = charset[((curSrc[0] & 0x03) << 4) + (curSrc[1] >> 4)];
      curDest[2] = charset[(curSrc[1] & 0x0f) << 2];
      curDest += 3;
      destLen -= 3;
      if (padded) {
        spx_assert(destLen >= 1, "our calc for encoded length was wrong");
        curDest[0] = kBase64PaddingChar;
        curDest += 1;
        destLen -= 1;
      }
      break;
  }
  // return the length
  return (curDest - destBytes);
}

//
// baseDecode:srcLen:destBytes:destLen:charset:requirePadding:
//
// Decodes the buffer into the larger.  returns the length of the decoded
// data, or zero for an error.
// |charset| is the character decoding buffer to use
//
// Returns:
//   the length of the encoded data.  zero if any error.
//
CFIndex _WBBase64DecodeBytes(const char *srcBytes, CFIndex srcLen,
                             UInt8 *destBytes, CFIndex destLen,
                             const char *charset, bool requirePadding) {
  if (!srcLen || !destLen || !srcBytes || !destBytes) {
    return 0;
  }

  int decode;
  CFIndex destIndex = 0;
  int state = 0;
  char ch = 0;
  while (srcLen-- && (ch = *srcBytes++) != 0)  {
    if (IsSpace(ch))  // Skip whitespace
      continue;

    if (ch == kBase64PaddingChar)
      break;

    decode = charset[(unsigned int)ch];
    if (decode == kBase64InvalidChar)
      return 0;

    // Four cyphertext characters decode to three bytes.
    // Therefore we can be in one of four states.
    switch (state) {
      case 0:
        // We're at the beginning of a four-character cyphertext block.
        // This sets the high six bits of the first byte of the
        // plaintext block.
        spx_assert(destIndex < destLen, "our calc for decoded length was wrong");
        destBytes[destIndex] = decode << 2;
        state = 1;
        break;
      case 1:
        // We're one character into a four-character cyphertext block.
        // This sets the low two bits of the first plaintext byte,
        // and the high four bits of the second plaintext byte.
        spx_assert((destIndex+1) < destLen, "our calc for decoded length was wrong");
        destBytes[destIndex] |= decode >> 4;
        destBytes[destIndex+1] = (decode & 0x0f) << 4;
        destIndex++;
        state = 2;
        break;
      case 2:
        // We're two characters into a four-character cyphertext block.
        // This sets the low four bits of the second plaintext
        // byte, and the high two bits of the third plaintext byte.
        // However, if this is the end of data, and those two
        // bits are zero, it could be that those two bits are
        // leftovers from the encoding of data that had a length
        // of two mod three.
        spx_assert((destIndex+1) < destLen, "our calc for decoded length was wrong");
        destBytes[destIndex] |= decode >> 2;
        destBytes[destIndex+1] = (decode & 0x03) << 6;
        destIndex++;
        state = 3;
        break;
      case 3:
        // We're at the last character of a four-character cyphertext block.
        // This sets the low six bits of the third plaintext byte.
        spx_assert(destIndex < destLen, "our calc for decoded length was wrong");
        destBytes[destIndex] |= decode;
        destIndex++;
        state = 0;
        break;
    }
  }

  // We are done decoding Base-64 chars.  Let's see if we ended
  //      on a byte boundary, and/or with erroneous trailing characters.
  if (ch == kBase64PaddingChar) {               // We got a pad char
    if ((state == 0) || (state == 1)) {
      return 0;  // Invalid '=' in first or second position
    }
    if (srcLen == 0) {
      if (state == 2) { // We run out of input but we still need another '='
        return 0;
      }
      // Otherwise, we are in state 3 and only need this '='
    } else {
      if (state == 2) {  // need another '='
        while ((ch = *srcBytes++) && (srcLen-- > 0)) {
          if (!IsSpace(ch))
            break;
        }
        if (ch != kBase64PaddingChar) {
          return 0;
        }
      }
      // state = 1 or 2, check if all remain padding is space
      while ((ch = *srcBytes++) && (srcLen-- > 0)) {
        if (!IsSpace(ch)) {
          return 0;
        }
      }
    }
  } else {
    // We ended by seeing the end of the string.

    if (requirePadding) {
      // If we require padding, then anything but state 0 is an error.
      if (state != 0) {
        return 0;
      }
    } else {
      // Make sure we have no partial bytes lying around.  Note that we do not
      // require trailing '=', so states 2 and 3 are okay too.
      if (state == 1) {
        return 0;
      }
    }
  }

  // If then next piece of output was valid and got written to it means we got a
  // very carefully crafted input that appeared valid but contains some trailing
  // bits past the real length, so just toss the thing.
  if ((destIndex < destLen) &&
      (destBytes[destIndex] != 0)) {
    return 0;
  }

  return destIndex;
}
