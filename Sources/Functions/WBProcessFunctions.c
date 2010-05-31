/*
 *  WBProcessFunction.c
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBProcessFunctions.h)

#include <unistd.h>
#include <ApplicationServices/ApplicationServices.h>

#pragma mark Process Utilities
WB_INLINE
OSStatus _WBProcessGetInformation(ProcessSerialNumber *psn, ProcessInfoRec *info) {
  info->processInfoLength = (UInt32)sizeof(*info);
  info->processName = NULL;
#if defined(__LP64__) && __LP64__
  info->processAppRef = NULL;
#else
  info->processAppSpec = NULL;
#endif
  return GetProcessInformation(psn, info);
}

OSType WBProcessGetSignature(ProcessSerialNumber *psn) {
  ProcessInfoRec info;
  OSStatus err = _WBProcessGetInformation(psn, &info);
  if (noErr == err)
    return info.processSignature;

  return 0;
}
CFStringRef WBProcessCopyBundleIdentifier(ProcessSerialNumber *psn) {
  CFStringRef identifier = NULL;
  CFDictionaryRef infos = ProcessInformationCopyDictionary(psn, kProcessDictionaryIncludeAllInformationMask);
  if (infos) {
    identifier = CFDictionaryGetValue(infos, kCFBundleIdentifierKey);
    if (identifier)
      CFRetain(identifier);
    CFRelease(infos);
  }
  return identifier;
}

bool WBProcessIsBackgroundOnly(ProcessSerialNumber *psn) {
  ProcessInfoRec info;
  OSStatus err = _WBProcessGetInformation(psn, &info);
  if (noErr == err)
    return (info.processMode & modeOnlyBackground) != 0;

  return 0;
}

#pragma mark Front process
OSType WBProcessGetFrontProcessSignature(void) {
  ProcessSerialNumber psn;
  if (noErr == GetFrontProcess(&psn)) {
    return WBProcessGetSignature(&psn);
  }
  return 0;
}
CFStringRef WBProcessCopyFrontProcessBundleIdentifier(void) {
  ProcessSerialNumber psn;
  if (noErr == GetFrontProcess(&psn)) {
    return WBProcessCopyBundleIdentifier(&psn);
  }
  return NULL;
}

#pragma mark Search Process
ProcessSerialNumber WBProcessGetProcessWithSignature(OSType type) {
  ProcessSerialNumber serialNumber = {kNoProcess, kNoProcess};
  if (type) {
    while (procNotFound != GetNextProcess(&serialNumber))  {
      if (WBProcessGetSignature(&serialNumber) == type) {
        break;
      }
    }
  }
  return serialNumber;
}

ProcessSerialNumber WBProcessGetProcessWithBundleIdentifier(CFStringRef bundleId) {
  return WBProcessGetProcessWithProperty(kCFBundleIdentifierKey, bundleId);
}

ProcessSerialNumber WBProcessGetProcessWithProperty(CFStringRef property, CFPropertyListRef value) {
  ProcessSerialNumber serialNumber = {kNoProcess, kNoProcess};
  if (!value)
    return serialNumber;

  while (procNotFound != GetNextProcess(&serialNumber))  {
    CFDictionaryRef info = ProcessInformationCopyDictionary(&serialNumber, kProcessDictionaryIncludeAllInformationMask); // leak: WBCFRelease
    if (info) {
      CFPropertyListRef procValue = CFDictionaryGetValue(info, property);
      if (procValue && (CFEqual(procValue, value))) {
        CFRelease(info);
        break;
      }
      CFRelease(info);
    }
  }
  return serialNumber;
}

#pragma mark BSD
static
OSStatus sysctlbyname_with_pid(const char *name, pid_t pid,  void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
  if (pid == 0) {
    if (sysctlbyname(name, oldp, oldlenp, newp, newlen) == -1)  {
      WBCLogWarning("%s(0): sysctlbyname failed: %s", __func__, strerror(errno));
      return -1;
    }
  } else {
    int mib[CTL_MAXNAME];
    size_t len = CTL_MAXNAME;
    if (sysctlnametomib(name, mib, &len) == -1) {
      WBCLogWarning("%s(): sysctlnametomib failed: %s", __func__, strerror(errno));
      return -1;
    }
    mib[len] = pid;
    len++;
    if (sysctl(mib, (u_int)len, oldp, oldlenp, newp, newlen) == -1)  {
      WBCLogWarning("%s(): sysct failed: %s", __func__, strerror(errno));
      return -1;
    }
  }
  return noErr;
}

Boolean WBProcessIsNative(pid_t pid) {
  int ret = FALSE;
  size_t sz = sizeof(ret);

  if (sysctlbyname_with_pid("sysctl.proc_native", pid, &ret, &sz, NULL, 0) == -1) {
    if (errno == ENOENT) {
      // sysctl doesn't exist, which means that this version of Mac OS
      // pre-dates Rosetta, so the application must be native.
      return TRUE;
    }
    return -1;
  }
  return ret ? TRUE : FALSE;
}

CFStringRef WBProcessCopyNameForPID(pid_t pid) {
  /* if current process */
  if (pid == getpid()) {
    check(getprogname());
    return CFStringCreateWithCString(kCFAllocatorDefault, getprogname(), kCFStringEncodingUTF8);
  }
  /* try to use carbon process manager */
  ProcessSerialNumber psn;
  if (noErr == GetProcessForPID(pid, &psn)) {
    CFStringRef name = NULL;
    if (noErr == CopyProcessName(&psn, &name))
      return name;
  }

  CFStringRef name = NULL;
  /* fall back: use sysctl */
  size_t len = 0;
  char stackbuf[2048];
  char *buffer = stackbuf;
  int mig[] = { CTL_KERN, KERN_PROCARGS, pid };
  int err = sysctl(mig, 3, NULL, &len, NULL, 0);
  if (0 == err && len > 0) {
    if (len > 2048)
      buffer = malloc(len);
    buffer[0] = '\0';
    err = sysctl(mig, 3, buffer, &len, NULL, 0);
    if (0 == err && strlen(buffer) > 0) {
      name = CFStringCreateWithCString(kCFAllocatorDefault, buffer, kCFStringEncodingUTF8);
    }
    if (buffer != stackbuf)
      free(buffer);
  }
  return name;
}
