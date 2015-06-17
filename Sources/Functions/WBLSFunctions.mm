/*
 *  WBLSFunctions.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBLSFunctions.h>

#pragma mark -
#pragma mark Launch Service
OSType WBLSGetSignatureForURL(CFURLRef url) {
  if (url) {
    LSItemInfoRecord info;
    OSStatus err = LSCopyItemInfoForURL(url, kLSRequestTypeCreator, &info);
    if (noErr == err && info.creator)
      return info.creator;
  }
  return kLSUnknownType;
}

CFStringRef WBLSCopyBundleIdentifierForURL(CFURLRef url) {
  if (url) {
    spx::unique_cfptr<CFBundleRef> bundle(CFBundleCreate(kCFAllocatorDefault, url));
    if (bundle) {
      CFStringRef identifier = CFBundleGetIdentifier(bundle.get());
      if (identifier)
        CFRetain(identifier);
      return identifier;
    }
  }
  return nullptr;
}

OSType WBLSGetSignatureForPath(CFStringRef path) {
  if (path) {
    spx::unique_cfptr<CFURLRef> url(CFURLCreateWithFileSystemPath(kCFAllocatorDefault, path, kCFURLPOSIXPathStyle, FALSE));
    if (url)
      return WBLSGetSignatureForURL(url.get());
  }
  return kLSUnknownType;
}

CFStringRef WBLSCopyBundleIdentifierForPath(CFStringRef path) {
  if (!path)
    return nullptr;

  spx::unique_cfptr<CFURLRef> url(CFURLCreateWithFileSystemPath(kCFAllocatorDefault, path, kCFURLPOSIXPathStyle, FALSE));
  if (url)
    return WBLSCopyBundleIdentifierForURL(url.get());
  return nullptr;
}

CFURLRef WBLSCopyApplicationURLForSignature(OSType sign) {
  if (!sign || kUnknownType == sign)
    return nullptr;
  CFURLRef application = nullptr;
  LSFindApplicationForInfo(sign, nullptr, nullptr, nullptr, &application);
  return application;
}

CFURLRef WBLSCopyApplicationURLForBundleIdentifier(CFStringRef identifier) {
  if (!identifier)
    return nullptr;
  CFURLRef application = nullptr;
  LSFindApplicationForInfo(kLSUnknownType, identifier, nullptr, nullptr, &application);
  return application;
}

OSStatus WBLSGetApplicationForSignature(OSType sign, FSRef *app) {
  if (!sign || kUnknownType == sign)
    return paramErr;
  return LSFindApplicationForInfo(sign, nullptr, nullptr, app, nullptr);
}

OSStatus WBLSGetApplicationForBundleIdentifier(CFStringRef identifier, FSRef *app) {
  if (!identifier)
    return paramErr;
  return LSFindApplicationForInfo(kLSUnknownCreator, identifier, nullptr, app, nullptr);
}

#pragma mark -
OSStatus WBLSIsApplication(const FSRef *aRef, Boolean *isApp) {
  if (!aRef || !isApp)
    return paramErr;
  LSItemInfoRecord info;
  OSStatus err = LSCopyItemInfoForRef(aRef, kLSRequestBasicFlagsOnly, &info);
  if (noErr == err) {
    *isApp = (kLSItemInfoIsApplication & info.flags) != 0;
  }
  return err;
}

OSStatus WBLSIsApplicationAtURL(CFURLRef anURL, Boolean *isApp) {
  if (!anURL || !isApp)
    return paramErr;
  LSItemInfoRecord info;
  OSStatus err = LSCopyItemInfoForURL(anURL, kLSRequestBasicFlagsOnly, &info);
  if (noErr == err) {
    *isApp = (kLSItemInfoIsApplication & info.flags) != 0;
  }
  return err;
}

OSStatus WBLSIsApplicationAtPath(CFStringRef aPath, Boolean *isApp) {
  if (aPath) {
    spx::unique_cfptr<CFURLRef> url(CFURLCreateWithFileSystemPath(kCFAllocatorDefault, aPath, kCFURLPOSIXPathStyle, TRUE));
    if (url)
      return WBLSIsApplicationAtURL(url.get(), isApp);
  }
  return paramErr;
}

OSStatus WBLSLaunchApplication(FSRef *app, LSLaunchFlags flags, ProcessSerialNumber *psn) {
  LSApplicationParameters params = {};
  params.application = app;
  params.flags = flags;
  params.version = 0;
  return LSOpenApplication(&params, psn);
}

OSStatus WBLSLaunchApplicationAtPath(CFStringRef aPath, CFURLPathStyle pathStyle, LSLaunchFlags flags, ProcessSerialNumber *psn) {
  spx::unique_cfptr<CFURLRef> url(CFURLCreateWithFileSystemPath(kCFAllocatorDefault, aPath, pathStyle, TRUE));
  if (url) {
    FSRef ref;
    if (CFURLGetFSRef(url.get(), &ref))
      return WBLSLaunchApplication(&ref, flags, psn);
  }
  return coreFoundationUnknownErr;
}

OSStatus WBLSLaunchApplicationWithSignature(OSType sign, LSLaunchFlags flags, ProcessSerialNumber *psn) {
  FSRef app;
  OSStatus err = WBLSGetApplicationForSignature(sign, &app);
  if (noErr == err) {
    err = WBLSLaunchApplication(&app, flags, psn);
  }
  return err;
}

OSStatus WBLSLaunchApplicationWithBundleIdentifier(CFStringRef bundle, LSLaunchFlags flags, ProcessSerialNumber *psn) {
  FSRef app;
  OSStatus err = WBLSGetApplicationForBundleIdentifier(bundle, &app);
  if (noErr == err) {
    err = WBLSLaunchApplication(&app, flags, psn);
  }
  return err;
}

#pragma mark -
#pragma mark Objective-C
NSString *WBLSFindApplicationForSignature(OSType signature) {
  spx::unique_cfptr<CFURLRef> url(WBLSCopyApplicationURLForSignature(signature));
  if (url)
    return SPXCFStringBridgingRelease(CFURLCopyFileSystemPath(url.get(), kCFURLPOSIXPathStyle));
  return nullptr;
}

NSString *WBLSFindApplicationForBundleIdentifier(NSString *bundle) {
  spx::unique_cfptr<CFURLRef> url(WBLSCopyApplicationURLForBundleIdentifier(SPXNSToCFString(bundle)));
  if (url)
    return SPXCFStringBridgingRelease(CFURLCopyFileSystemPath(url.get(), kCFURLPOSIXPathStyle));
  return nullptr;
}

