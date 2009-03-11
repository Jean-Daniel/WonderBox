/*
 *  WBVersionFunctions.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#if !defined (__WBVERSION_FUNCTIONS_H)
#define __WBVERSION_FUNCTIONS_H 1

#pragma mark Versions
enum {
  kWBVersionStageDevelopement = 0,
  kWBVersionStageAlpha        = 1,
  kWBVersionStageBeta         = 2,
  kWBVersionStageCandidate    = 3,
  kWBVersionStageFinal        = 4,
  kWBVersionStageRelease = kWBVersionStageFinal,
};
typedef CFIndex WBVersionStage;

enum  {
  kWBVersionInvalid = -1LLU
};

WB_EXPORT CFStringRef WBVersionBundleKey;

/* 
Version number: 
 major.minor.bug[status]build
 - Possible status:
 d: devel
 a: alpha
 b: beta
rc: release candidate
 f: final ~ r: release
 
 - example: 1.2.3b5, 1.0, 1.2r1
 */
WB_EXPORT
bool WBVersionDecompose(CFStringRef version, CFIndex *major, CFIndex *minor, CFIndex *bug, WBVersionStage *stage, CFIndex *build);
WB_EXPORT
CFStringRef WBVersionCreateString(CFIndex major, CFIndex minor, CFIndex bug, WBVersionStage stage, CFIndex build);
/*!
@function
 @discussion According to “Runtime Configuration Guidelines”, this function use short version string (CFBundleShortVersionString)
 and not bundle build version (CFBundleVersion).
 */
WB_EXPORT
bool WBVersionGetCurrent(CFIndex *major, CFIndex *minor, CFIndex *bug, WBVersionStage *stage, CFIndex *build);
WB_EXPORT
bool WBVersionGetBundleVersion(CFBundleRef bundle, CFIndex *major, CFIndex *minor, CFIndex *bug, WBVersionStage *stage, CFIndex *build);


/* Number layout (64 bits unsigned integer)
  | major (16 bits) | minor (16 bits) | bug (16 bits) | stage (3 bits) | build (13 bits) |
*/
WB_EXPORT
UInt64 WBVersionGetNumberFromString(CFStringRef version);
WB_EXPORT
CFStringRef WBVersionCreateStringForNumber(UInt64 version);

/*!
@function
 @discussion According to “Runtime Configuration Guidelines”, this function use short version string (CFBundleShortVersionString)
 and not bundle build version (CFBundleVersion).
 */
WB_EXPORT
UInt64 WBVersionGetCurrentNumber(void);
WB_EXPORT
UInt64 WBVersionGetBundleNumber(CFBundleRef bundle);

WB_EXPORT
UInt64 WBVersionComposeNumber(CFIndex major, CFIndex minor, CFIndex bug, WBVersionStage stage, CFIndex build);
WB_EXPORT
void WBVersionDecomposeNumber(UInt64 version, CFIndex *major, CFIndex *minor, CFIndex *bug, WBVersionStage *stage, CFIndex *build);


#endif /* __WBVERSION_FUNCTIONS_H */
