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

// MARK: -
// MARK: Launch Service

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

// MARK: -
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

