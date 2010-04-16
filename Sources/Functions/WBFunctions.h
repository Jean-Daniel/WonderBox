/*
 *  WBFunctions.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#if !defined (__WB_FUNCTIONS_H)
#define __WB_FUNCTIONS_H 1

__BEGIN_DECLS

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

// Hash functions
WB_EXPORT
CFHashCode WBHashInteger(CFIndex i);
WB_EXPORT
CFHashCode WBHashDouble(double d);
WB_EXPORT
CFHashCode WBHashBytes(const uint8_t *bytes, size_t length);

#pragma mark Objective C Functions
#if defined(__OBJC__)
WB_INLINE
NSString *WBStringForOSType(OSType type) {
  return WBCFAutorelease(WBCreateStringForOSType(type));
}
WB_INLINE
OSType WBOSTypeFromString(NSString *type) {
  return type ? WBGetOSTypeFromString(WBNSToCFString(type)) : 0;
}
WB_INLINE 
NSString *WBApplicationGetName(void) {
	return [[NSBundle mainBundle] objectForInfoDictionaryKey:(id)kCFBundleNameKey] ? :
	[[NSProcessInfo processInfo] processName];
}
#endif

__END_DECLS

#endif /* __WB_FUNCTIONS_H */
