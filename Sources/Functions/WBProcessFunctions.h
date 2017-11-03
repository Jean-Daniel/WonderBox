/*
 *  WBProcessFunctions.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#if !defined(__WB_PROCESS_FUNCTIONS_H)
#define __WB_PROCESS_FUNCTIONS_H

#include <WonderBox/WBBase.h>

#include <CoreServices/CoreServices.h>

#pragma mark Process
WB_EXPORT
OSType WBProcessGetSignature(ProcessSerialNumber *psn) WB_DEPRECATED("ProcessSerialNumber is obsolete");
WB_EXPORT
CFStringRef WBProcessCopyBundleIdentifier(ProcessSerialNumber *psn) WB_DEPRECATED("ProcessSerialNumber is obsolete");

WB_EXPORT
bool WBProcessIsBackgroundOnly(ProcessSerialNumber *psn) WB_DEPRECATED("ProcessSerialNumber is obsolete");

WB_EXPORT
OSType WBProcessGetFrontProcessSignature(void) WB_DEPRECATED("Signature is obsolete");
WB_EXPORT
CFStringRef WBProcessCopyFrontProcessBundleIdentifier(void) WB_DEPRECATED("NSRunningApplication");

WB_EXPORT
pid_t WBProcessGetProcessIdentifierForBundleIdentifier(CFStringRef bundleId) WB_DEPRECATED("NSRunningApplication");

WB_EXPORT
ProcessSerialNumber WBProcessGetProcessWithSignature(OSType type) WB_DEPRECATED("ProcessSerialNumber is obsolete");
WB_EXPORT
ProcessSerialNumber WBProcessGetProcessWithBundleIdentifier(CFStringRef bundleId) WB_DEPRECATED("ProcessSerialNumber is obsolete");
WB_EXPORT
ProcessSerialNumber WBProcessGetProcessWithProperty(CFStringRef property, CFPropertyListRef value) WB_DEPRECATED("ProcessSerialNumber is obsolete");

#pragma mark BSD
WB_EXPORT
Boolean WBProcessIsNative(pid_t pid);

WB_EXPORT
CFStringRef WBProcessCopyNameForPID(pid_t pid);

struct kinfo_proc;
WB_EXPORT
int WBProcessIterate(bool (*callback)(struct kinfo_proc *info, void *ctxt), void *ctxt);

#endif /* __WB_PROCESS_FUNCTIONS_H */
