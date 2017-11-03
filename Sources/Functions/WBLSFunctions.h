/*
 *  WBLSFunctions.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#if !defined(__WB_LS_FUNCTIONS_H)
#define __WB_LS_FUNCTIONS_H

#import <WonderBox/WBBase.h>

#import <CoreServices/CoreServices.h>

WB_EXPORT
OSType WBLSGetSignatureForURL(CFURLRef url);
WB_EXPORT
CFStringRef WBLSCopyBundleIdentifierForURL(CFURLRef url);

WB_EXPORT
OSType WBLSGetSignatureForPath(CFStringRef path) WB_DEPRECATED("URL API");
WB_EXPORT
CFStringRef WBLSCopyBundleIdentifierForPath(CFStringRef path) WB_DEPRECATED("URL API");

WB_EXPORT
CFURLRef WBLSCopyApplicationURLForSignature(OSType sign);
WB_EXPORT
CFURLRef WBLSCopyApplicationURLForBundleIdentifier(CFStringRef identifier);

WB_EXPORT
OSStatus WBLSGetApplicationForSignature(OSType sign, FSRef *app);
WB_EXPORT
OSStatus WBLSGetApplicationForBundleIdentifier(CFStringRef identifier, FSRef *app);

WB_EXPORT
OSStatus WBLSIsApplication(const FSRef *aRef, Boolean *isApp);
WB_EXPORT
OSStatus WBLSIsApplicationAtURL(CFURLRef anURL, Boolean *isApp);
WB_EXPORT
OSStatus WBLSIsApplicationAtPath(CFStringRef aPath, Boolean *isApp);

WB_EXPORT WB_DEPRECATED("ProcessSerialNumber")
OSStatus WBLSLaunchApplicationAtPath(CFStringRef aPath, CFURLPathStyle pathStyle, LSLaunchFlags flags, ProcessSerialNumber *psn);
WB_EXPORT WB_DEPRECATED("ProcessSerialNumber")
OSStatus WBLSLaunchApplicationWithBundleIdentifier(CFStringRef bundle, LSLaunchFlags flags, ProcessSerialNumber *psn);

WB_EXPORT WB_DEPRECATED("FSRef/ProcessSerialNumber")
OSStatus WBLSLaunchApplication(FSRef *app, LSLaunchFlags flags, ProcessSerialNumber *psn);
WB_EXPORT WB_DEPRECATED("Signature/ProcessSerialNumber")
OSStatus WBLSLaunchApplicationWithSignature(OSType sign, LSLaunchFlags flags, ProcessSerialNumber *psn);

#if defined(__OBJC__)

WB_EXPORT
NSString *WBLSFindApplicationForSignature(OSType signature) WB_DEPRECATED("URL API");
WB_EXPORT
NSString *WBLSFindApplicationForBundleIdentifier(NSString *bundle) WB_DEPRECATED("URL API");

#endif /* __OBJC__ */

#endif /* __WB_LS_FUNCTIONS_H */
