/*
 *  WBFunctions.h
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

#if !defined (__WBFUNCTIONS_H)
#define __WBFUNCTIONS_H 1

WB_EXPORT
OSType WBGetOSTypeFromString(CFStringRef str);
WB_EXPORT
CFStringRef WBCreateStringForOSType(OSType type);

#if defined(__WB_OBJC__)
#pragma mark -
#pragma mark Objective-C Functions
WB_EXPORT
Class WBRuntimeSetObjectClass(id anObject, Class newClass);
WB_EXPORT
NSArray *WBRuntimeGetSubclasses(Class parent, BOOL strict);

/* Method Swizzling */
WB_EXPORT
void WBRuntimeExchangeClassMethods(Class cls, SEL orig, SEL replace);
WB_EXPORT
void WBRuntimeExchangeInstanceMethods(Class cls, SEL orig, SEL replace);

WB_EXPORT
IMP WBRuntimeSetClassMethodImplementation(Class base, SEL selector, IMP placeholder);
WB_EXPORT
IMP WBRuntimeSetInstanceMethodImplementation(Class base, SEL selector, IMP placeholder);

/* Does not check super class */
WB_EXPORT
BOOL WBRuntimeObjectImplementsSelector(id object, SEL method);
WB_EXPORT
BOOL WBRuntimeClassImplementsSelector(Class cls, SEL method);
WB_EXPORT
BOOL WBRuntimeInstanceImplementsSelector(Class cls, SEL method);

#pragma mark -
WB_INLINE
NSString *WBStringForOSType(OSType type) {
  return [(id)WBCreateStringForOSType(type) autorelease];
}
WB_INLINE
OSType WBOSTypeFromString(NSString *type) {
  return type ? WBGetOSTypeFromString((CFStringRef)type) : 0;
}

#pragma mark -
WB_INLINE
NSSize WBMaxSizeForSizes(NSSize s1, NSSize s2) {
  NSSize s;
  s.width = MAX(s1.width, s2.width);
  s.height = MAX(s1.height, s2.height);
  return s;
}

WB_INLINE
NSSize WBMinSizeForSizes(NSSize s1, NSSize s2) {
  NSSize s;
  s.width = MIN(s1.width, s2.width);
  s.height = MIN(s1.height, s2.height);
  return s;
}

WB_INLINE
CGFloat WBWindowUserSpaceScaleFactor(NSWindow *window) {
  return window ? [window userSpaceScaleFactor] : 1;
}

WB_INLINE
CGFloat WBScreenUserSpaceScaleFactor(NSScreen *screen) {
  return screen ? [screen userSpaceScaleFactor] : 1;
}

#pragma mark Scaling
enum {
  kWBScalingModeProportionallyFit, // default
  kWBScalingModeProportionallyFill,
  kWBScalingModeProportionallyFitDown,
  kWBScalingModeProportionallyFillDown,
  kWBScalingModeAxesIndependently,
  kWBScalingModeNone,
};
typedef NSUInteger WBScalingMode;

WB_EXPORT
CGRect WBRectScale(CGSize source, CGRect destination, WBScalingMode mode);

WB_INLINE
CGFloat WBScaleGetProportionalRatio(NSSize imageSize, NSRect canvasRect) {
  return MIN(NSWidth(canvasRect) / imageSize.width, NSHeight(canvasRect) / imageSize.height);
}

WB_INLINE
NSSize WBScaleProportionally(NSSize imageSize, NSRect canvasRect) {
  // get the smaller ratio and scale the image size by it
  CGFloat ratio = WBScaleGetProportionalRatio(imageSize, canvasRect);
  imageSize.width *= ratio;
  imageSize.height *= ratio;
  return imageSize;
}

#endif /* __WB_OBJC__ */

#pragma mark -
#pragma mark OS Utilities
#if defined(__WB_OBJC__)
WB_EXPORT 
NSString *WBApplicationGetName(void);
#endif

WB_EXPORT
SInt32 WBSystemMajorVersion(void);
WB_EXPORT
SInt32 WBSystemMinorVersion(void);
WB_EXPORT
SInt32 WBSystemBugFixVersion(void);

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

#pragma mark -
#pragma mark Base 16
WB_EXPORT
CFDataRef WBCFDataCreateFromHexString(CFStringRef str);

#pragma mark Base 64
WB_EXPORT
CFDataRef WBBase64CreateBase64DataFromData(CFDataRef data);
WB_EXPORT
CFDataRef WBBase64CreateBase64DataFromBytes(const UInt8 *bytes, CFIndex length);

WB_EXPORT
CFDataRef WBBase64CreateDataFromBase64Data(CFDataRef data);
WB_EXPORT
CFDataRef WBBase64CreateDataFromBase64Bytes(const UInt8 *bytes, CFIndex length);

#pragma mark Misc
WB_EXPORT
CFComparisonResult WBUTCDateTimeCompare(UTCDateTime *t1, UTCDateTime *t2);

#endif /* __WBFUNCTIONS_H */
