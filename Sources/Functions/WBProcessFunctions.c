/*
 *  WBProcessFunction.c
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#include <WonderBox/WBProcessFunctions.h>

#include <unistd.h>
#include <sys/sysctl.h>
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
  CFDictionaryRef infos = ProcessInformationCopyDictionary(psn, (UInt32)kProcessDictionaryIncludeAllInformationMask);
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
    CFDictionaryRef info = ProcessInformationCopyDictionary(&serialNumber, (UInt32)kProcessDictionaryIncludeAllInformationMask);
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
      spx_log_warning("%s(0): sysctlbyname failed: %s", __func__, strerror(errno));
      return -1;
    }
  } else {
    int mib[CTL_MAXNAME];
    size_t len = CTL_MAXNAME;
    if (sysctlnametomib(name, mib, &len) == -1) {
      spx_log_warning("%s(): sysctlnametomib failed: %s", __func__, strerror(errno));
      return -1;
    }
    mib[len] = pid;
    len++;
    if (sysctl(mib, (u_int)len, oldp, oldlenp, newp, newlen) == -1)  {
      spx_log_warning("%s(): sysct failed: %s", __func__, strerror(errno));
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
    return FALSE;
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
      name = CFStringCreateWithCString(kCFAllocatorDefault, basename(buffer), kCFStringEncodingUTF8);
    }
    if (buffer != stackbuf)
      free(buffer);
  }
  return name;
}

int WBProcessIterate(bool (*callback)(struct kinfo_proc *info, void *ctxt), void *ctxt) {
  // --- Checking input arguments for validity --- //
  if (!callback)
    return EINVAL;

  //--- Getting list of process information for all processes --- //

  /* Setting up the mib (Management Information Base) which is an array of integers where each
   * integer specifies how the data will be gathered.  Here we are setting the MIB
   * block to lookup the information on all the BSD processes on the system.  Also note that
   * every regular application has a recognized BSD process accociated with it.  We pass
   * CTL_KERN, KERN_PROC, KERN_PROC_ALL to sysctl as the MIB to get back a BSD structure with
   * all BSD process information for all processes in it (including BSD process names)
   */
  int mib[6] = {0,0,0,0,0,0}; //used for sysctl call.
  mib[0] = CTL_KERN;
  mib[1] = KERN_PROC;
  mib[2] = KERN_PROC_ALL;

  /* Here we have a loop set up where we keep calling sysctl until we finally get an unrecoverable error
   * (and we return) or we finally get a succesful result.  Note with how dynamic the process list can
   * be you can expect to have a failure here and there since the process list can change between
   * getting the size of buffer required and the actually filling that buffer.
   */
  size_t sizeOfBufferRequired = 0;
  bool SuccessfullyGotProcessInformation = false;
  struct kinfo_proc *BSDProcessInformationStructure = NULL;
  while (!SuccessfullyGotProcessInformation) {
    /* Now that we have the MIB for looking up process information we will pass it to sysctl to get the
     * information we want on BSD processes.  However, before we do this we must know the size of the buffer to
     * allocate to accomidate the return value.  We can get the size of the data to allocate also using the
     * sysctl command.  In this case we call sysctl with the proper arguments but specify no return buffer
     * specified (null buffer).  This is a special case which causes sysctl to return the size of buffer required.
     *
     * First Argument: The MIB which is really just an array of integers.  Each integer is a constant
     *     representing what information to gather from the system.  Check out the man page to know what
     *     constants sysctl will work with.  Here of course we pass our MIB block which was passed to us.
     * Second Argument: The number of constants in the MIB (array of integers).  In this case there are three.
     * Third Argument: The output buffer where the return value from sysctl will be stored.  In this case
     *     we don't want anything return yet since we don't yet know the size of buffer needed.  Thus we will
     *     pass null for the buffer to begin with.
     * Forth Argument: The size of the output buffer required.  Since the buffer itself is null we can just
     *     get the buffer size needed back from this call.
     * Fifth Argument: The new value we want the system data to have.  Here we don't want to set any system
     *     information we only want to gather it.  Thus, we pass null as the buffer so sysctl knows that
     *     we have no desire to set the value.
     * Sixth Argument: The length of the buffer containing new information (argument five).  In this case
     *     argument five was null since we didn't want to set the system value.  Thus, the size of the buffer
     *     is zero or NULL.
     * Return Value: a return value indicating success or failure.  Actually, sysctl will either return
     *     zero on no error and -1 on error.  The errno UNIX variable will be set on error.
     */
    int error = sysctl(mib, 3, NULL, &sizeOfBufferRequired, NULL, 0);

    /* If an error occurred then return the accociated error.  The error itself actually is stored in the UNIX
     * errno variable.  We can access the errno value using the errno global variable.  We will return the
     * errno value as the sysctlError return value from this function.
     */
    if (error != 0)
      return errno;

    /* Now we successful obtained the size of the buffer required for the sysctl call.  This is stored in the
     * SizeOfBufferRequired variable.  We will malloc a buffer of that size to hold the sysctl result.
     */
    BSDProcessInformationStructure = (struct kinfo_proc *)malloc(sizeOfBufferRequired);
    if (!BSDProcessInformationStructure)
      return ENOMEM;

    /* Now we have the buffer of the correct size to hold the result we can now call sysctl
     * and get the process information.
     *
     * First Argument: The MIB for gathering information on running BSD processes.  The MIB is really
     *     just an array of integers.  Each integer is a constant representing what information to
     *     gather from the system.  Check out the man page to know what constants sysctl will work with.
     * Second Argument: The number of constants in the MIB (array of integers).  In this case there are three.
     * Third Argument: The output buffer where the return value from sysctl will be stored.  This is the buffer
     *     which we allocated specifically for this purpose.
     * Forth Argument: The size of the output buffer (argument three).  In this case its the size of the
     *     buffer we already allocated.
     * Fifth Argument: The buffer containing the value to set the system value to.  In this case we don't
     *     want to set any system information we only want to gather it.  Thus, we pass null as the buffer
     *     so sysctl knows that we have no desire to set the value.
     * Sixth Argument: The length of the buffer containing new information (argument five).  In this case
     *     argument five was null since we didn't want to set the system value.  Thus, the size of the buffer
     *     is zero or NULL.
     * Return Value: a return value indicating success or failure.  Actually, sysctl will either return
     *     zero on no error and -1 on error.  The errno UNIX variable will be set on error.
     */
    error = sysctl(mib, 3, BSDProcessInformationStructure, &sizeOfBufferRequired, NULL, 0);

    //Here we successfully got the process information.  Thus set the variable to end this sysctl calling loop
    if (error == 0) {
      SuccessfullyGotProcessInformation = TRUE;
    } else  {
      /* failed getting process information we will try again next time around the loop.  Note this is caused
       * by the fact the process list changed between getting the size of the buffer and actually filling
       * the buffer (something which will happen from time to time since the process list is dynamic).
       * Anyways, the attempted sysctl call failed.  We will now begin again by freeing up the allocated
       * buffer and starting again at the beginning of the loop.
       */
      free(BSDProcessInformationStructure);
      BSDProcessInformationStructure = NULL;
    }
  } //end while loop

  // --- Going through process list looking for processes with matching names --- //
  /* Now that we have the BSD structure describing the running processes we will parse it for the desired
   * process name.  First we will the number of running processes.  We can determine
   * the number of processes running because there is a kinfo_proc structure for each process.
   */
  size_t NumberOfRunningProcesses = sizeOfBufferRequired / sizeof(struct kinfo_proc);

  /* Now we will go through each process description checking to see if the process name matches that
   * passed to us.  The BSDProcessInformationStructure has an array of kinfo_procs.  Each kinfo_proc has
   * an extern_proc accociated with it in the kp_proc attribute.  Each extern_proc (kp_proc) has the process name
   * of the process accociated with it in the p_comm attribute and the PID of that process in the p_pid attibute.
   * We test the process name by compairing the process name passed to us with the value in the p_comm value.
   * Note we limit the compairison to MAXCOMLEN which is the maximum length of a BSD process name which is used
   * by the system.
   */
  for (size_t idx = 0; idx < NumberOfRunningProcesses ; ++idx) {
    if (!callback(&BSDProcessInformationStructure[idx], ctxt))
      break;
  }
  free(BSDProcessInformationStructure); //done with allocated buffer so release.

  return 0;
}
