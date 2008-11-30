/*
 *  WBFunctions.h
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

#if !defined (__WONDERBOX_FUNCTIONS_H)
#define __WONDERBOX_FUNCTIONS_H 1

WB_EXPORT
OSType WBGetOSTypeFromString(CFStringRef str);
WB_EXPORT
CFStringRef WBCreateStringForOSType(OSType type);

#pragma mark -
#pragma mark OS Utilities

WB_EXPORT
SInt32 WBSystemMajorVersion(void);
WB_EXPORT
SInt32 WBSystemMinorVersion(void);
WB_EXPORT
SInt32 WBSystemBugFixVersion(void);

WB_EXPORT
CFComparisonResult WBUTCDateTimeCompare(UTCDateTime *t1, UTCDateTime *t2);

WB_EXPORT
CFDataRef WBCFDataCreateFromHexString(CFStringRef str);

#pragma mark Objective C Functions
#if defined(__OBJC__)
WB_INLINE
NSString *WBStringForOSType(OSType type) {
  return [(id)WBCreateStringForOSType(type) autorelease];
}
WB_INLINE
OSType WBOSTypeFromString(NSString *type) {
  return type ? WBGetOSTypeFromString((CFStringRef)type) : 0;
}
WB_INLINE 
NSString *WBApplicationGetName(void) {
	return [[NSBundle mainBundle] objectForInfoDictionaryKey:(id)kCFBundleNameKey] ? :
	[[NSProcessInfo processInfo] processName];
}
#endif

#endif /* __WONDERBOX_FUNCTIONS_H */
