/*
 *  WBVersionFunctions.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBVersionFunctions.h>

// MARK: Version Parser

/* According to “Runtime Configuration Guidelines”, we should use short version string */
CFStringRef const WBVersionBundleKey = CFSTR("CFBundleShortVersionString");

/*
 Version number:
 major.minor.bug[status]build
 - Possible status:
 d: devel
 a: alpha
 b: beta
 rc: release candidate
 f: final ~ r: release
 */
bool WBVersionGetCurrent(CFIndex *major, CFIndex *minor, CFIndex *bug, WBVersionStage *stage, CFIndex *build) {
  return WBVersionGetBundleVersion(CFBundleGetMainBundle(), major, minor, bug, stage, build);
}

bool WBVersionGetBundleVersion(CFBundleRef bundle, CFIndex *major, CFIndex *minor, CFIndex *bug, WBVersionStage *stage, CFIndex *build) {
  if (!bundle) return false;

  CFStringRef vers = CFBundleGetValueForInfoDictionaryKey(bundle, WBVersionBundleKey);
  if (vers)
    return WBVersionDecompose(vers, major, minor, bug, stage, build);
  return false;
}

bool WBVersionDecompose(CFStringRef version, CFIndex *major, CFIndex *minor, CFIndex *bug, WBVersionStage *stage, CFIndex *build) {
  if (!version || CFStringGetLength(version) > 64)
    return 0;

  bool ok = true;
  char buffer[128];
  CFIndex vers[3] = {0, 0, 0};
  if (CFStringGetCString(version, buffer, 128, kCFStringEncodingUTF8)) {
    CFIndex idx = 0;
    char *ptr = buffer;
    while (*ptr && idx < 3) {
      if (isdigit(*ptr)) {
        vers[idx] *= 10;
        vers[idx] += (*ptr - '0');
      } else {
        idx++;
        if ('.' != *ptr)
          break;
      }
      ptr++;
    }
    if (major) *major = vers[0];
    if (minor) *minor = vers[1];
    if (bug) *bug = vers[2];

    /* default values */
    if (stage) *stage = kWBVersionStageFinal;
    if (build) *build = 0;
    /* Check stage */
    if (*ptr) {
      switch (*ptr) {
        case 'd': //devel
        case 'D':
          if (stage) *stage = kWBVersionStageDevelopement;
          break;
        case 'a': // alpha
        case 'A':
          if (stage) *stage = kWBVersionStageAlpha;
          break;
        case 'b': // beta
        case 'B':
          if (stage) *stage = kWBVersionStageBeta;
          break;
        case 'f': // final
        case 'F':
          if (stage) *stage = kWBVersionStageFinal;
          break;
        case 'r': // release or candidate
        case 'R':
          if ('c' == ptr[1] || 'C' == ptr[1]) {
            ptr++;
            if (stage) *stage = kWBVersionStageCandidate;
          } else if (stage) {
            *stage = kWBVersionStageRelease;
          }
          break;
        default:
          // invalid stage
          if (stage) *stage = 0;
          ok = false;
          ptr--;
      }
      ptr++;
      if (*ptr && !isdigit(*ptr)) {
        ok = false;
      } else if (*ptr && build) {
        *build = strtol(ptr, NULL, 10);
      }
    }
  } else {
    ok = false;
  }
  return ok;
}

CFStringRef WBVersionCreateString(CFIndex major, CFIndex minor, CFIndex bug, WBVersionStage stage, CFIndex build) {
  if (major < 0 || minor < 0 || bug < 0 || stage < 0 || build < 0)
    return NULL;
  if (stage > kWBVersionStageFinal) // undefined stage
    return NULL;

  CFMutableStringRef str = CFStringCreateMutable(kCFAllocatorDefault, 64);
  CFStringAppendFormat(str, NULL, CFSTR("%lu.%lu"), (long)major, (long)minor);
  if (bug)
    CFStringAppendFormat(str, NULL, CFSTR(".%lu"), (long)bug);

  if (build || kWBVersionStageFinal != stage) {
    const char *stg = nil;
    switch (stage) {
      case kWBVersionStageDevelopement:
        stg = "d"; break;
      case kWBVersionStageAlpha:
        stg = "a"; break;
      case kWBVersionStageBeta:
        stg = "b"; break;
      case kWBVersionStageCandidate:
        stg = "rc"; break;
      case kWBVersionStageFinal:
        stg = "r"; break;
    }
    if (stg && build)
      CFStringAppendFormat(str, NULL, CFSTR("%s%lu"), stg, (long)build);
    else if (stg)
      CFStringAppendFormat(str, NULL, CFSTR("%s"), stg);
  }
  return str;
}

UInt64 WBVersionGetCurrentNumber(void) {
  return WBVersionGetBundleNumber(CFBundleGetMainBundle());
}

UInt64 WBVersionGetBundleNumber(CFBundleRef bundle) {
  CFIndex build;
  WBVersionStage stage;
  CFIndex major, minor, bug;
  if (WBVersionGetBundleVersion(bundle, &major, &minor, &bug, &stage, &build))
    return WBVersionComposeNumber(major, minor, bug, stage, build);
  return kWBVersionInvalid;
}

UInt64 WBVersionGetNumberFromString(CFStringRef version) {
  CFIndex build;
  WBVersionStage stage;
  CFIndex major, minor, bug;
  if (WBVersionDecompose(version, &major, &minor, &bug, &stage, &build))
    return WBVersionComposeNumber(major, minor, bug, stage, build);
  return kWBVersionInvalid;
}

CFStringRef WBVersionCreateStringForNumber(UInt64 version) {
  if (kWBVersionInvalid == version)
    return NULL;
  CFIndex build;
  WBVersionStage stage;
  CFIndex major, minor, bug;
  WBVersionDecomposeNumber(version, &major, &minor, &bug, &stage, &build);
  return WBVersionCreateString(major, minor, bug, stage, build);
}

UInt64 WBVersionComposeNumber(CFIndex major, CFIndex minor, CFIndex bug, WBVersionStage stage, CFIndex build) {
  if (major > 0xffff || minor > 0xffff || bug > 0xffff || stage > 0x7 || build > 0x1fff)
    return kWBVersionInvalid;
  if (major < 0 || minor < 0 || bug < 0 || stage < 0 || build < 0)
    return kWBVersionInvalid;
  return ((UInt64)major & 0xffff) << 48 | ((UInt64)minor & 0xffff) << 32 | ((uint32_t)bug & 0xffff) << 16 | ((uint32_t)stage & 0x7) << 13 | (build & 0x1fff);
}

void WBVersionDecomposeNumber(UInt64 version, CFIndex *major, CFIndex *minor, CFIndex *bug, WBVersionStage *stage, CFIndex *build) {
  if (major) *major = (version & 0xffff000000000000) >> 48;
  if (minor) *minor = (version & 0x0000ffff00000000) >> 32;
  if (bug)     *bug = (version & 0x00000000ffff0000) >> 16;
  if (stage) *stage = (version & 0x000000000000e000) >> 13;
  if (build) *build = (version & 0x0000000000001fff);
}
