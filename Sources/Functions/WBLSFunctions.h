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
CFStringRef WBLSCopyBundleIdentifierForURL(CFURLRef url);

WB_EXPORT
OSStatus WBLSIsApplicationAtURL(CFURLRef anURL, Boolean *isApp) __OS_AVAILABILITY_MSG(macosx, deprecated=10.11, "Use the URL resource property kCFURLIsApplicationKey or NSURLIsApplicationKey instead.");

#endif /* __WB_LS_FUNCTIONS_H */
