/*
 *  WBProcessFunctions.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#if !defined(__WBPROCESS_FUNCTIONS_H)
#define __WBPROCESS_FUNCTIONS_H

#include <sys/sysctl.h>

#pragma mark Process
WB_EXPORT
OSType WBProcessGetSignature(ProcessSerialNumber *psn);
WB_EXPORT
CFStringRef WBProcessCopyBundleIdentifier(ProcessSerialNumber *psn);

WB_EXPORT
bool WBProcessIsBackgroundOnly(ProcessSerialNumber *psn);

WB_EXPORT 
OSType WBProcessGetFrontProcessSignature(void);
WB_EXPORT
CFStringRef WBProcessCopyFrontProcessBundleIdentifier(void);

WB_EXPORT
ProcessSerialNumber WBProcessGetProcessWithSignature(OSType type);
WB_EXPORT
ProcessSerialNumber WBProcessGetProcessWithBundleIdentifier(CFStringRef bundleId);
WB_EXPORT
ProcessSerialNumber WBProcessGetProcessWithProperty(CFStringRef property, CFPropertyListRef value);

#pragma mark BSD
WB_EXPORT
Boolean WBProcessIsNative(pid_t pid);

WB_EXPORT
CFStringRef WBProcessCopyNameForPID(pid_t pid);

#endif /* __WBPROCESS_FUNCTIONS_H */
