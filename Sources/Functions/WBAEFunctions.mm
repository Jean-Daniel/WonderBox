/*
 *  WBAEFunctions.c
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#include <pthread.h>

#import <memory>

#import <AppKit/AppKit.h>

#import <WonderBox/WBAEFunctions.h>

// To workaround bug in AppleEvent dispatching in 10.8
#import <WonderBox/WBProcessFunctions.h>

Boolean WBAEDebug = false;

static
OSStatus WBAESendMessageThreadSafeSynchronous(AppleEvent *event, AppleEvent *reply,
                                              AESendMode sendMode, long timeOutInTicks);

static
void _WBAEPrintDebug(const AEDesc *desc, CFStringRef format, ...) WB_CF_FORMAT(2, 3);
void _WBAEPrintDebug(const AEDesc *desc, CFStringRef format, ...) {
  va_list args;
  va_start(args, format);
  CFStringRef str = CFStringCreateWithFormatAndArguments(kCFAllocatorDefault, NULL, format, args);
  va_end(args);
  if (str) {
    CFShow(str);
    CFRelease(str);
  }
}

#define WBAEPrintDebug(desc, format, ...) do { \
  if (WBAEDebug) { \
    CFStringRef __event = WBAEDescCopyDescription(desc); \
      if (__event) { \
        _WBAEPrintDebug(desc, format, __event, ## __VA_ARGS__); \
        CFRelease(__event); \
      } \
  } \
} while(0)

struct WBAEDesc : public AEDesc {
  WBAEDesc() {
    AEInitializeDescInline(this);
  }

  ~WBAEDesc() {
    AEDisposeDesc(this);
  }
};

#pragma mark -
#pragma mark Print AEDesc
CFStringRef WBAEDescCopyDescription(const AEDesc *desc) {
  OSStatus err;
  Handle handle;
  CFStringRef str = NULL;
  err = AEPrintDescToHandle(desc, &handle);
  if (noErr == err) {
    str = CFStringCreateWithCString(kCFAllocatorDefault, *handle, kCFStringEncodingASCII);
    DisposeHandle(handle);
  }
  return str;
}

OSStatus WBAEPrintDesc(const AEDesc *desc) {
  Handle str;
  OSStatus err = AEPrintDescToHandle(desc, &str);
  if (noErr == err) {
    fprintf(stdout, "%s\n", *str);
    fflush(stdout);
    DisposeHandle(str);
  }
  return err;
}

#pragma mark -
#pragma mark Find Target for AppleEvents
OSStatus WBAECreateTargetWithProcess(ProcessSerialNumber *psn, AEDesc *target) {
  if (!psn || !target)
    return paramErr;

  OSStatus err = noErr;
  WBAEInitDesc(target);
  if (psn->highLongOfPSN != kNoProcess || psn->lowLongOfPSN != kNoProcess) {
    err = AECreateDesc(typeProcessSerialNumber, psn, sizeof(ProcessSerialNumber), target);
  } else {
    err = paramErr;
  }
  return err;
}

OSStatus WBAECreateTargetWithSignature(OSType sign, AEDesc *target) {
  if (!sign || !target) return paramErr;

  OSStatus err = noErr;
  WBAEInitDesc(target);
  err = AECreateDesc(typeApplSignature, &sign, sizeof(OSType), target);
  return err;
}

OSStatus WBAECreateTargetWithBundleID(CFStringRef bundleId, AEDesc *target) {
  if (!bundleId || !target) return paramErr;

  OSStatus err = noErr;
  WBAEInitDesc(target);
  char bundleStr[512];
  if (!CFStringGetCString(bundleId, bundleStr, 512, kCFStringEncodingUTF8))
    err = coreFoundationUnknownErr;

  if (noErr == err) {
    size_t length = strlen(bundleStr);
    if (length <= LONG_MAX)
      err = AECreateDesc(typeApplicationBundleID, bundleStr, (Size)length, target);
    else
      err = errAEIndexTooLarge;
  }

  return err;
}

OSStatus WBAECreateTargetWithProcessIdentifier(pid_t pid, AEDesc *target) {
  if (!pid || !target) return paramErr;
  return AECreateDesc(typeKernelProcessID, &pid, sizeof(pid), target);
}

OSStatus WBAECreateTargetWithMachPort(mach_port_t port, AEDesc *target) {
  if (!MACH_PORT_VALID(port) || !target) return paramErr;
  return AECreateDesc(typeMachPort, &port, sizeof(port), target);
}

#pragma mark -
#pragma mark Create Object Specifier
OSStatus WBAECreateDescFromFSRef(const FSRef *aRef, AEDesc *desc) {
  if (!aRef || !desc) return paramErr;

  AliasHandle alias;
  OSStatus err = FSNewAliasMinimal(aRef, &alias);
  if (noErr == err && alias == NULL)
    err = paramErr;

  if (noErr == err) {
    err = WBAECreateDescFromAlias(alias, desc);
    DisposeHandle((Handle)alias);
  }
  return err;
}
OSStatus WBAECreateDescFromAlias(AliasHandle alias, AEDesc *desc) {
  if (!alias || !desc) return paramErr;
  return AECreateDesc(typeAlias, *alias, GetAliasSize(alias), desc);
}
OSStatus WBAECreateDescFromString(CFStringRef string, AEDesc *desc) {
  if (!string || !desc) return paramErr;

  /* Create Unicode String */
  /* Use stack if length < 512, else use heap */

  UniChar stackStr[512];
  std::unique_ptr<UniChar[]> heapBuf;

  CFIndex length = CFStringGetLength(string);
  // Note: We need to check CFIndex overflow.
  // It should be (lenght * sizeof(UniChar) > CFINDEX_MAX), but
  // it may overflow, and CFINDEX_MAX is not defined
  if (!length || length > (CFIndexMax / (CFIndex)sizeof(UniChar)))
    return paramErr;

  UniChar *str;
  CFRange range = CFRangeMake(0, length);
  CFIndex buflen = length * (CFIndex)sizeof(UniChar);
  if (length <= 512) {
    str = stackStr;
  } else {
    heapBuf.reset(new UniChar[length]);
    str = heapBuf.get();
    if (!str)
      return memFullErr;
  }
  CFStringGetCharacters(string, range, str);
  return AECreateDesc(typeUnicodeText, str, buflen, desc);
}

OSStatus WBAECreateObjectSpecifier(DescType desiredType, DescType keyForm, AEDesc *keyData, AEDesc *container, AEDesc *specifier) {
  if (!keyData || !specifier) return paramErr;

  OSStatus err;
  AEDesc appli = WBAEEmptyDesc();
  err = CreateObjSpecifier(desiredType, (container) ? container : &appli, keyForm, keyData, false, specifier);

  return err;
}

OSStatus WBAECreateIndexObjectSpecifier(DescType desiredType, CFIndex idx, AEDesc *container, AEDesc *specifier) {
  if (!specifier)
    return paramErr;

  OSStatus err;
  WBAEDesc keyData;

  switch (idx) {
    /* Absolute index case */
    case kAEAny:
    case kAEAll:
    case kAELast:
    case kAEFirst:
    case kAEMiddle: {
      OSType absIdx = (OSType)idx;
      err = AECreateDesc(typeAbsoluteOrdinal, &absIdx, sizeof(OSType), &keyData);
    }
      break;
      /* General case */
    default:
#if defined(__LP64__) && __LP64__
      err = AECreateDesc(typeSInt64, &idx, sizeof(SInt64), &keyData);
#else
      err = AECreateDesc(typeSInt32, &idx, sizeof(SInt32), &keyData);
#endif
  }

  if (noErr == err)
    err = WBAECreateObjectSpecifier(desiredType, formAbsolutePosition, &keyData, container, specifier);

  return err;
}

OSStatus WBAECreateUniqueIDObjectSpecifier(DescType desiredType, SInt32 uid, AEDesc *container, AEDesc *specifier) {
  if (!specifier)
    return paramErr;

  WBAEDesc keyData;
  OSStatus err = AECreateDesc(typeSInt32, &uid, sizeof(uid), &keyData);
  if (noErr == err)
    err = WBAECreateObjectSpecifier(desiredType, formUniqueID, &keyData, container, specifier);

  return err;
}

OSStatus WBAECreateNameObjectSpecifier(DescType desiredType, CFStringRef name, AEDesc *container, AEDesc *specifier) {
  if (!name || !specifier)
    return paramErr;

  WBAEDesc keyData;
  OSStatus err = WBAECreateDescFromString(name, &keyData);
  if (noErr == err)
    err = WBAECreateObjectSpecifier(desiredType, formName, &keyData, container, specifier);

  return err;
}

OSStatus WBAECreatePropertyObjectSpecifier(DescType desiredType, AEKeyword property, AEDesc *container, AEDesc *specifier) {
  if (!specifier)
    return paramErr;

  WBAEDesc keyData;
  OSStatus err = AECreateDesc(typeType, &property, sizeof(AEKeyword), &keyData);
  if (noErr == err)
    err = WBAECreateObjectSpecifier(desiredType, formPropertyID, &keyData, container, specifier);

  return err;
}

#pragma mark -
#pragma mark Create AppleEvents
OSStatus WBAECreateEventWithTarget(const AEDesc *target, AEEventClass eventClass, AEEventID eventType, AppleEvent *theEvent) {
  if (!target || !theEvent)
    return paramErr;

  WBAEInitDesc(theEvent);
  return AECreateAppleEvent(eventClass, eventType,
                            target,
                            kAutoGenerateReturnID,
                            kAnyTransactionID,
                            theEvent);
}

OSStatus WBAECreateEventWithTargetProcess(ProcessSerialNumber *psn, AEEventClass eventClass, AEEventID eventType, AppleEvent *theEvent) {
  if (!psn || !theEvent)
    return paramErr;

  WBAEDesc target;
  OSStatus err = WBAECreateTargetWithProcess(psn, &target);
  if (noErr == err)
    err = WBAECreateEventWithTarget(&target, eventClass, eventType, theEvent);
  return err;
}

static
OSStatus _WBAECreateTargetByResolvingSignature(OSType targetSign, AEDesc *target) {
  ProcessSerialNumber psn = WBProcessGetProcessWithSignature(targetSign);
  if (psn.lowLongOfPSN == kNoProcess)
    return procNotFound;

  return WBAECreateTargetWithProcess(&psn, target);
}

OSStatus WBAECreateEventWithTargetSignature(OSType targetSign, AEEventClass eventClass, AEEventID eventType, AppleEvent *theEvent) {
  if (!targetSign || !theEvent)
    return paramErr;

  OSStatus err;
  WBAEDesc target;
  // workaround bug with apple event system (http://www.openradar.me/12424662 )
  if (kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber10_7_4) {
    err = _WBAECreateTargetByResolvingSignature(targetSign, &target);
  } else {
    err = WBAECreateTargetWithSignature(targetSign, &target);
  }
  if (noErr == err)
    err = WBAECreateEventWithTarget(&target, eventClass, eventType, theEvent);
  return err;
}

static
OSStatus _WBAECreateTargetByResolvingBundleID(CFStringRef targetId, AEDesc *target) {
  pid_t pid = WBProcessGetProcessIdentifierForBundleIdentifier(targetId);
  if (pid <= 0)
    return procNotFound;

  return WBAECreateTargetWithProcessIdentifier(pid, target);
}

OSStatus WBAECreateEventWithTargetBundleID(CFStringRef targetId, AEEventClass eventClass, AEEventID eventType, AppleEvent *theEvent) {
  if (!targetId || !theEvent)
    return paramErr;

  OSStatus err;
  WBAEDesc target;
  // workaround bug with apple event system (http://www.openradar.me/12424662 )
  if (kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber10_7_4) {
    err = _WBAECreateTargetByResolvingBundleID(targetId, &target);
  } else {
    err = WBAECreateTargetWithBundleID(targetId, &target);
  }
  if (noErr == err)
    err = WBAECreateEventWithTarget(&target, eventClass, eventType, theEvent);
  return err;
}

OSStatus WBAECreateEventWithTargetMachPort(mach_port_t port, AEEventClass eventClass, AEEventID eventType, AppleEvent *theEvent) {
  if (!MACH_PORT_VALID(port) || !theEvent)
    return paramErr;

  WBAEDesc target;
  OSStatus err = WBAECreateTargetWithMachPort(port, &target);
  if (noErr == err)
    err = WBAECreateEventWithTarget(&target, eventClass, eventType, theEvent);
  return err;
}

OSStatus WBAECreateEventWithTargetProcessIdentifier(pid_t pid, AEEventClass eventClass, AEEventID eventType, AppleEvent *theEvent) {
  if (!pid || !theEvent)
    return paramErr;

  WBAEDesc target;
  OSStatus err = WBAECreateTargetWithProcessIdentifier(pid, &target);
  if (noErr == err)
    err = WBAECreateEventWithTarget(&target, eventClass, eventType, theEvent);
  return err;
}

#pragma mark Build Events
OSStatus WBAEBuildAppleEventWithTarget(const AEDesc *target, AEEventClass theClass, AEEventID theID, AppleEvent *outEvent,
                                       AEBuildError *outError, const char *paramsFmt, ...) {
  OSStatus err = WBAECreateEventWithTarget(target, theClass, theID, outEvent);
  if (noErr == err) {
    va_list args;
    va_start(args, paramsFmt);
    err = vAEBuildParameters(outEvent, outError, paramsFmt, args);
    va_end(args);
  }
  return err;
}

OSStatus WBAEBuildAppleEventWithTargetSignature(OSType sign, AEEventClass theClass, AEEventID theID, AppleEvent *outEvent,
                                                AEBuildError *outError, const char *paramsFmt, ...) {
  va_list args;
  va_start(args, paramsFmt);
  OSStatus err = vAEBuildAppleEvent(theClass, theID, typeApplSignature, &sign, sizeof(OSType),
                                    kAutoGenerateReturnID, kAnyTransactionID, outEvent, outError, paramsFmt, args);
  va_end(args);
  return err;
}

OSStatus WBAEBuildAppleEventWithTargetProcess(ProcessSerialNumber *psn, AEEventClass theClass, AEEventID theID, AppleEvent *outEvent,
                                              AEBuildError *outError, const char *paramsFmt, ...) {
  va_list args;
  va_start(args, paramsFmt);
  OSStatus err = vAEBuildAppleEvent(theClass, theID, typeProcessSerialNumber, psn, sizeof(ProcessSerialNumber),
                                    kAutoGenerateReturnID, kAnyTransactionID, outEvent, outError, paramsFmt, args);
  va_end(args);
  return err;
}

#pragma mark -
#pragma mark Add Param & Attr
OSStatus WBAESetStandardAttributes(AppleEvent *theEvent) {
  check(theEvent != NULL);
  OSStatus err = noErr;
  //err = AEPutAttributePtr(theEvent, keySubjectAttr, typeNull, NULL, 0);
  if (noErr == err) {
    UInt32 value = 0x00010000;  // kAECaseIgnoreMask; // ignore all
    err = AEPutAttributePtr(theEvent,
                            'csig', /* enumConsidsAndIgnores, */
                            typeUInt32,
                            &value,
                            sizeof(UInt32));
  }
  return err;
}

OSStatus WBAESetEventSubject(AppleEvent *theEvent, const AEDesc *subject) {
  if (!theEvent || !subject)
    return paramErr;
  return AEPutAttributeDesc(theEvent, 'subj' /* keySubjectAttr */,
                            subject);
}
OSStatus WBAESetEventConsiderations(AppleEvent *theEvent, UInt32 flags) {
  if (!theEvent)
    return paramErr;
  // flags = kAECaseIgnoreMask; // ignore all
  return AEPutAttributePtr(theEvent, 'csig' /* enumConsidsAndIgnores */,
                           typeUInt32, &flags, sizeof(flags));
}

OSStatus WBAEAddAEDescWithData(AppleEvent *theEvent, AEKeyword theAEKeyword, DescType typeCode, const void * dataPtr, Size dataSize) {
  if (!theEvent)
    return paramErr;

  WBAEDesc aeDesc;
  OSStatus err = AECreateDesc(typeCode, dataPtr, dataSize, &aeDesc);
  if (noErr == err)
    err = AEPutParamDesc(theEvent, theAEKeyword, &aeDesc);

  return err;
}

OSStatus WBAEAddFileURL(AppleEvent *theEvent, AEKeyword keyword, CFURLRef url) {
  UInt8 buffer[4096];
  if (CFURLGetFileSystemRepresentation(url, true, buffer, 4096)) {
    return WBAEAddParameter(theEvent, keyword, typeFileURL, buffer, strlen((char *)buffer));
  }
  return coreFoundationUnknownErr;
}

OSStatus WBAEAddFSRefAsAlias(AppleEvent *theEvent, AEKeyword keyword, const FSRef *aRef) {
  if (!theEvent || !aRef)
    return paramErr;

  AliasHandle alias;
  OSStatus err = FSNewAliasMinimal(aRef, &alias);

  if (noErr == err && NULL == alias)
    err = paramErr;

  if (noErr == err) {
    err = WBAEAddAlias(theEvent, keyword, alias);
    DisposeHandle((Handle)alias);
  }
  return err;
}

OSStatus WBAEAddStringAsUnicodeText(AppleEvent *theEvent, AEKeyword keyword, CFStringRef str) {
  if (!theEvent)
    return paramErr;

  OSStatus err = noErr;
  if (str) {
    CFIndex length = CFStringGetLength(str);
    // Check CFIndex overflow
    if (length > (CFIndexMax / (CFIndex)sizeof(UniChar)))
      err = memFullErr;

    if (noErr == err) {
      UniChar buffer[2048];
      std::unique_ptr<UniChar[]> heapBuf;

      CFIndex buflen = length * (CFIndex)sizeof(UniChar);
      UniChar *chr = (UniChar *)CFStringGetCharactersPtr(str);
      if (!chr) {
        if (length < 2048) {
          chr = buffer;
        } else {
          heapBuf.reset(new UniChar[length]);
          chr = heapBuf.get();
        }
        CFStringGetCharacters(str, CFRangeMake(0, length), chr);
      }
      // typeUnicodeText: native byte ordering, optional BOM
      err = WBAEAddParameter(theEvent, keyword, typeUnicodeText, chr, buflen);
    }
  } else {
    err = WBAEAddParameter(theEvent, keyword, typeNull, NULL, 0);
  }
  return err;
}

OSStatus WBAEAddIndexObjectSpecifier(AppleEvent *theEvent, AEKeyword keyword, DescType desiredType, CFIndex idx, AEDesc *container) {
  if (!theEvent)
    return paramErr;

  WBAEDesc specifier;
  OSStatus err = WBAECreateIndexObjectSpecifier(desiredType, idx, container, &specifier);
  if (noErr == err)
    err = AEPutParamDesc(theEvent, keyword, &specifier);

  return err;
}

OSStatus WBAEAddUniqueIDObjectSpecifier(AppleEvent *theEvent, AEKeyword keyword, DescType desiredType, SInt32 uid, AEDesc *container) {
  if (!theEvent || !container)
    return paramErr;

  WBAEDesc specifier;
  OSStatus err = WBAECreateUniqueIDObjectSpecifier(desiredType, uid, container, &specifier);
  if (noErr == err)
    err = AEPutParamDesc(theEvent, keyword, &specifier);

  return err;
}

OSStatus WBAEAddNameObjectSpecifier(AppleEvent *theEvent, AEKeyword keyword, DescType desiredType, CFStringRef name, AEDesc *container) {
  if (!theEvent || !container)
    return paramErr;

  WBAEDesc specifier;
  OSStatus err = WBAECreateNameObjectSpecifier(desiredType, name, container, &specifier);
  if (noErr == err)
    err = AEPutParamDesc(theEvent, keyword, &specifier);

  return err;
}

OSStatus WBAEAddPropertyObjectSpecifier(AppleEvent *theEvent, AEKeyword keyword, DescType desiredType, AEKeyword property, AEDesc *container) {
  if (!theEvent || !container)
    return paramErr;

  WBAEDesc specifier;
  OSStatus err = WBAECreatePropertyObjectSpecifier(desiredType, property, container, &specifier);
  if (noErr == err)
    err = AEPutParamDesc(theEvent, keyword, &specifier);

  return err;
}

#pragma mark -
#pragma mark Send AppleEvents
OSStatus WBAESendEventNoReply(AppleEvent* theEvent) {
  if (!theEvent)
    return paramErr;

  OSStatus err = noErr;
  AppleEvent theReply = WBAEEmptyDesc();

  WBAEPrintDebug(theEvent, CFSTR("Send event no Reply: %@\n"));
  err = AESendMessage(theEvent, &theReply, kAENoReply, kAEDefaultTimeout);
  WBAEDisposeDesc(&theReply);

  return err;
}

OSStatus WBAESendEvent(AppleEvent *pAppleEvent, AESendMode sendMode, SInt64 timeoutms, AppleEvent *theReply) {
  if (!pAppleEvent)
    return paramErr;

  if (theReply)
    WBAEInitDesc(theReply);

  WBAEPrintDebug(pAppleEvent, CFSTR("Send event: %@\n"));

  WBAEDesc stackReply;
  AppleEvent *reply = theReply ? : &stackReply;

  /* Convert timeout ms into timeout ticks */
  long timeout = 0;
  if (timeoutms <= 0)
    timeout = (long)timeoutms;
  else
    timeout = lround(timeoutms * (60.0 / 1e3));

  OSStatus err = (sendMode & kAEWaitReply) ?
    WBAESendMessageThreadSafeSynchronous(pAppleEvent, reply, sendMode, timeout) :
    AESendMessage(pAppleEvent, reply, sendMode, timeout);

  if (noErr == err) {
    err = WBAEGetHandlerError(reply);
    if (noErr != err) {
      /* Print error message with explication, else print the event */
      if (WBAEDebug) {
        const char *str = GetMacOSStatusErrorString(err);
        const char *comment = GetMacOSStatusCommentString(err);
        WBAEPrintDebug(reply, CFSTR("AEDesc Reply: %@ (%s: %s)\n"), str, comment);
      }
      WBAEDisposeDesc(reply);
    } else {
      WBAEPrintDebug(reply, CFSTR("AEDesc Reply: %@\n"));
    }
  }

  return err;
}

#pragma mark Simple Events
OSStatus WBAESendSimpleEvent(OSType targetSign, AEEventClass eventClass, AEEventID eventType) {
  WBAEDesc theEvent;
  OSStatus err = WBAECreateEventWithTargetSignature(targetSign, eventClass, eventType, &theEvent);
  if (noErr == err) {
    //WBAESetStandardAttributes(&theEvent);
    err = WBAESendEventNoReply(&theEvent);
  }
  return err;
}

OSStatus WBAESendSimpleEventToBundle(CFStringRef bundleID, AEEventClass eventClass, AEEventID eventType) {
  WBAEDesc theEvent;
  OSStatus err = WBAECreateEventWithTargetBundleID(bundleID, eventClass, eventType, &theEvent);
  if (noErr == err) {
    //WBAESetStandardAttributes(&theEvent);
    err = WBAESendEventNoReply(&theEvent);
  }
  return err;
}

OSStatus WBAESendSimpleEventToProcess(ProcessSerialNumber *psn, AEEventClass eventClass, AEEventID eventType) {
  if (!psn)
    return paramErr;

  WBAEDesc theEvent;
  OSStatus err = WBAECreateEventWithTargetProcess(psn, eventClass, eventType, &theEvent);
  if (noErr == err) {
    //WBAESetStandardAttributes(&theEvent);
    err = WBAESendEventNoReply(&theEvent);
  }
  return err;
}

#pragma mark Primitive Reply

OSStatus WBAESendEventReturnData(AppleEvent *pAppleEvent,
                                 DescType    pDesiredType,
                                 DescType   *pActualType,
                                 void       *pDataPtr,
                                 Size       pMaximumSize,
                                 Size       *pActualSize) {
  if (!pAppleEvent)
    return paramErr;

  WBAEDesc theReply;
  OSStatus err = WBAESendEvent(pAppleEvent, kAEWaitReply, kAEDefaultTimeout, &theReply);
  if (noErr == err && theReply.descriptorType != typeNull) {
    err = WBAEGetDataFromAppleEvent(&theReply, keyDirectObject, pDesiredType,
                                    pActualType, pDataPtr, pMaximumSize, pActualSize);
  }
  return err;
}

OSStatus WBAESendEventReturnBoolean(AppleEvent* pAppleEvent, Boolean* pValue) {
  if (!pAppleEvent)
    return paramErr;
  Size actualSize;
  DescType actualType;
  return WBAESendEventReturnData(pAppleEvent, typeBoolean,
                                 &actualType, pValue, sizeof(Boolean), &actualSize);
}

OSStatus WBAESendEventReturnSInt16(AppleEvent* pAppleEvent, SInt16* pValue) {
  if (!pAppleEvent)
    return paramErr;
  Size actualSize;
  DescType actualType;
  return WBAESendEventReturnData(pAppleEvent, typeSInt16,
                                 &actualType, pValue, sizeof(SInt16), &actualSize);
}

OSStatus WBAESendEventReturnSInt32(AppleEvent* pAppleEvent, SInt32* pValue) {
  if (!pAppleEvent)
    return paramErr;
  Size actualSize;
  DescType actualType;
  return WBAESendEventReturnData(pAppleEvent, typeSInt32,
                                 &actualType, pValue, sizeof(SInt32), &actualSize);
}

OSStatus WBAESendEventReturnUInt32(AppleEvent* pAppleEvent, UInt32* pValue) {
  if (!pAppleEvent)
    return paramErr;
  Size actualSize;
  DescType actualType;
  return WBAESendEventReturnData(pAppleEvent, typeUInt32,
                                 &actualType, pValue, sizeof(UInt32), &actualSize);
}

OSStatus WBAESendEventReturnSInt64(AppleEvent* pAppleEvent, SInt64* pValue) {
  if (!pAppleEvent)
    return paramErr;
  Size actualSize;
  DescType actualType;
  return WBAESendEventReturnData(pAppleEvent, typeSInt64,
                                 &actualType, pValue, sizeof(SInt64), &actualSize);
}

OSStatus WBAESendEventReturnUInt64(AppleEvent* pAppleEvent, UInt64* pValue) {
  if (!pAppleEvent)
    return paramErr;
  Size actualSize;
  DescType actualType;
  return WBAESendEventReturnData(pAppleEvent, typeUInt64,
                                 &actualType, pValue, sizeof(UInt64), &actualSize);
}

#pragma mark Object Reply
OSStatus WBAESendEventReturnAEDesc(AppleEvent *pAppleEvent, const DescType pDescType, AEDesc *pAEDesc) {
  if (!pAppleEvent)
    return paramErr;

  WBAEDesc theReply;
  OSStatus err = WBAESendEvent(pAppleEvent, kAEWaitReply, kAEDefaultTimeout, &theReply);
  if (noErr == err && theReply.descriptorType != typeNull)
    err = AEGetParamDesc(&theReply, keyDirectObject, pDescType, pAEDesc);

  return err;
}

OSStatus WBAESendEventReturnAEDescList(AppleEvent* pAppleEvent, AEDescList* pAEDescList) {
  if (!pAppleEvent || !pAEDescList)
    return paramErr;

  WBAEDesc theReply;
  OSStatus err = WBAESendEvent(pAppleEvent, kAEWaitReply, kAEDefaultTimeout, &theReply);
  if (noErr == err) {
    if (theReply.descriptorType != typeNull)
      err = AEGetParamDesc(&theReply, keyDirectObject, typeAEList, pAEDescList);
    else
      WBAEInitDesc(pAEDescList);
  }

  return err;
}

OSStatus WBAESendEventReturnString(AppleEvent* pAppleEvent, CFStringRef* string) {
  if (!pAppleEvent)
    return paramErr;
  if (!string || *string)
    return paramErr;

  WBAEDesc theReply;
  OSStatus err = WBAESendEvent(pAppleEvent, kAEWaitReply, kAEDefaultTimeout, &theReply);
  if (noErr == err) {
    if (theReply.descriptorType != typeNull)
      err = WBAECopyStringFromAppleEvent(&theReply, keyDirectObject, string);
    else
      *string = nullptr;
  }
  return err;
}

OSStatus WBAESendEventReturnCFData(AppleEvent *pAppleEvent, DescType resultType, DescType *actualType, CFDataRef *data) {
  if (!pAppleEvent)
    return paramErr;
  if (!data || *data)
    return paramErr;

  if (!resultType)
    resultType = typeData;

  WBAEDesc theReply;
  OSStatus err = WBAESendEvent(pAppleEvent, kAEWaitReply, kAEDefaultTimeout, &theReply);
  if (noErr == err) {
    if (theReply.descriptorType != typeNull)
      err = WBAECopyCFDataFromAppleEvent(&theReply, keyDirectObject, resultType, actualType, data);
    else
      *data = nullptr;
  }
  return err;
}

#pragma mark -
#pragma mark Retreive AEDesc Data
OSStatus WBAEGetDataFromDescriptor(const AEDesc* pAEDesc, DescType desiredType, DescType* typeCode, void *dataPtr, Size maximumSize, Size *pActualSize) {
  if (!pAEDesc || !dataPtr)
    return paramErr;

  OSStatus err = noErr;
  if (pActualSize)
    *pActualSize = 0;
  if (typeCode)
    *typeCode = pAEDesc->descriptorType;
  /* Coerce if needed */
  if (desiredType != typeWildCard && desiredType != pAEDesc->descriptorType) {
    WBAEDesc desc;
    err = AECoerceDesc(pAEDesc, desiredType, &desc);
    if (noErr == err) {
      err = AEGetDescData(&desc, dataPtr, maximumSize);
      if (pActualSize && noErr == err)
        *pActualSize = AEGetDescDataSize(&desc);
    }
  } else {
    err = AEGetDescData(pAEDesc, dataPtr, maximumSize);
    if (pActualSize && noErr == err)
      *pActualSize = AEGetDescDataSize(pAEDesc);
  }
  return err;
}

#pragma mark FSRef
WB_INLINE
OSStatus __WBAEResolveAlias(AliasHandle alias, FSRef *outRef) {
  Boolean changed;
  return FSResolveAliasWithMountFlags(NULL, alias, outRef, &changed, kResolveAliasFileNoUI);
}

OSStatus WBAEGetFSRefFromDescriptor(const AEDesc* pAEDesc, FSRef *pRef) {
  AliasHandle alias;
  OSStatus err = WBAECopyAliasFromDescriptor(pAEDesc, &alias);
  if (noErr == err) {
    err = __WBAEResolveAlias(alias, pRef);
    DisposeHandle((Handle)alias);
  }
  return err;
}
OSStatus WBAEGetFSRefFromAppleEvent(const AppleEvent* anEvent, AEKeyword aKey, FSRef *pRef) {
  AliasHandle alias;
  OSStatus err = WBAECopyHandleFromAppleEvent(anEvent, aKey, typeAlias, (Handle *)&alias);
  if (noErr == err) {
    err = __WBAEResolveAlias(alias, pRef);
    DisposeHandle((Handle)alias);
  }
  return err;
}
OSStatus WBAEGetNthFSRefFromDescList(const AEDescList *aList, CFIndex idx, FSRef *pRef) {
  AliasHandle alias;
  OSStatus err = WBAECopyNthHandleFromDescList(aList, idx, typeAlias, (Handle *)&alias);
  if (noErr == err) {
    err = __WBAEResolveAlias(alias, pRef);
    DisposeHandle((Handle)alias);
  }
  return err;
}

#pragma mark Alias
OSStatus WBAECopyAliasFromDescriptor(const AEDesc* pAEDesc, AliasHandle *pAlias) {
  return WBAECopyHandleFromDescriptor(pAEDesc, typeAlias, (Handle *)pAlias);
}
OSStatus WBAECopyAliasFromAppleEvent(const AppleEvent* anEvent, AEKeyword aKey, AliasHandle *pAlias) {
  return WBAECopyHandleFromAppleEvent(anEvent, aKey, typeAlias, (Handle *)pAlias);
}
OSStatus WBAECopyNthAliasFromDescList(const AEDescList *aList, CFIndex idx, AliasHandle *pAlias) {
  return WBAECopyNthHandleFromDescList(aList, idx, typeAlias, (Handle *)pAlias);
}

#pragma mark CFStringRef
OSStatus WBAECopyStringFromDescriptor(const AEDesc* pAEDesc, CFStringRef* aString) {
  if (!pAEDesc)
    return paramErr;
  if (!aString || *aString)
    return paramErr;

  if (typeNull == pAEDesc->descriptorType) {
    return noErr;
  } else {
    WBAEDesc uniAEDesc;
    OSStatus err = AECoerceDesc(pAEDesc, typeUnicodeText, &uniAEDesc);
    if (noErr == err) {
      if (typeUnicodeText == uniAEDesc.descriptorType) {
        Size bufSize = AEGetDescDataSize(&uniAEDesc);
        if (bufSize > 0) {
          CFIndex length = bufSize / sizeof(UniChar);
          std::unique_ptr<UniChar[]> characters(new UniChar[length]);
          if (characters) {
            err = AEGetDescData(&uniAEDesc, characters.get(), length * sizeof(UniChar));
            if (noErr == err) {
              *aString = CFStringCreateWithCharactersNoCopy(kCFAllocatorDefault, characters.get(), length, kCFAllocatorDefault);
              if (*aString) {
                characters.release();
              } else {
                err = coreFoundationUnknownErr;
              }
            }
          } else {
            err = memFullErr;
          }
        } else { /* bufSize <= 0 */
          *aString = CFSTR("");
        }
      }
    }
    return err;
  }
}

OSStatus WBAECopyStringFromAppleEvent(const AppleEvent* anEvent, AEKeyword aKey, CFStringRef* aString) {
  if (!anEvent)
    return paramErr;
  if (!aString || *aString)
    return paramErr;

  WBAEDesc strDesc;
  OSStatus err = AEGetParamDesc(anEvent, aKey, typeWildCard, &strDesc);
  if (noErr == err)
    err = WBAECopyStringFromDescriptor(&strDesc, aString);

  return err;
}

OSStatus WBAECopyNthStringFromDescList(const AEDescList *aList, CFIndex idx, CFStringRef *aString) {
  if (!aList)
    return paramErr;
  if (!aString || *aString)
    return paramErr;

  WBAEDesc nthItem;
  OSStatus err = AEGetNthDesc(aList, idx, typeWildCard, NULL, &nthItem);
  if (noErr == err)
    err = WBAECopyStringFromDescriptor(&nthItem, aString);

  return err;
}

#pragma mark CFDataRef
OSStatus WBAECopyCFDataFromDescriptor(const AEDesc* aDesc, CFDataRef *data) {
  if (!aDesc)
    return paramErr;
  if (!data || *data)
    return paramErr;

  if (typeNull == aDesc->descriptorType)
    return noErr;

  OSStatus err = noErr;
  Size bufSize = AEGetDescDataSize(aDesc);
  if (bufSize > 0) {
    std::unique_ptr<uint8_t[]> buffer(new uint8_t[bufSize]);
    if (buffer) {
      err = AEGetDescData(aDesc, buffer.get(), bufSize);
      if (noErr == err)
        *data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, buffer.get(), bufSize, kCFAllocatorDefault);
      if (*data) {
        buffer.release();
      } else {
        err = coreFoundationUnknownErr;
      }
    } else {
      err = memFullErr;
    }
  } else { // bufSize <= 0
    /* return empty data */
    *data = CFDataCreate(kCFAllocatorDefault, NULL, 0);
  }

  return err;
}

OSStatus WBAECopyCFDataFromAppleEvent(const AppleEvent *anEvent, AEKeyword aKey, DescType aType, DescType *actualType, CFDataRef *data) {
  if (!anEvent)
    return paramErr;
  if (!data || *data)
    return paramErr;

  WBAEDesc dataDesc;
  OSStatus err = AEGetParamDesc(anEvent, aKey, aType, &dataDesc);
  if (noErr == err) {
    if (actualType)
      *actualType = dataDesc.descriptorType;
    err = WBAECopyCFDataFromDescriptor(&dataDesc, data);
  }
  return err;
}

OSStatus WBAECopyNthCFDataFromDescList(const AEDescList *aList, CFIndex idx, DescType aType, DescType *actualType, CFDataRef *data) {
  if (!aList)
    return paramErr;
  if (!data || *data)
    return paramErr;

  WBAEDesc nthItem;
  OSStatus err = AEGetNthDesc(aList, idx, aType, NULL, &nthItem);
  if (noErr == err) {
    if (actualType)
      *actualType = nthItem.descriptorType;
    err = WBAECopyCFDataFromDescriptor(&nthItem, data);
  }
  return err;
}

#pragma mark -
#pragma mark Misc. AE utility functions
#pragma mark List
OSStatus WBAEDescListCreate(AEDescList *list, ...) {
  va_list args;
  va_start(args, list);
  OSStatus err = WBAEDescListCreateWithArguments(list, args);
  va_end(args);
  return err;
}
OSStatus WBAEDescListCreateWithArguments(AEDescList *list, va_list args) {
  if (!list)
    return paramErr;
  OSStatus err = AECreateList(NULL, 0, FALSE, list);
  if (noErr == err) {
    err = WBAEDescListAppendWithArguments(list, args);
    if (noErr != err)
      WBAEDisposeDesc(list);
  }
  return err;
}

OSStatus WBAEDescListAppend(AEDescList *list, ...) {
  va_list args;
  va_start(args, list);
  OSStatus err = WBAEDescListAppendWithArguments(list, args);
  va_end(args);
  return err;
}
OSStatus WBAEDescListAppendWithArguments(AEDescList *list, va_list args) {
  if (!list)
    return paramErr;
  const AEDesc *desc;
  OSStatus err = noErr;
  while (noErr == err && (desc = va_arg(args, const AEDesc *))) {
    err = AEPutDesc(list, 0, desc);
  }
  return err;
}

OSStatus WBAEDescListGetCount(const AEDescList *list, CFIndex *count) {
  if (!count)
    return paramErr;

  long cnt = 0;
  OSStatus err = AECountItems(list, &cnt);
  if (noErr == err)
    *count = cnt;
  return err;
}

#pragma mark Record
OSStatus WBAERecordCreate(AERecord *list, ...) {
  va_list args;
  va_start(args, list);
  OSStatus err = WBAERecordCreateWithArguments(list, args);
  va_end(args);
  return err;
}
OSStatus WBAERecordCreateWithArguments(AERecord *list, va_list args) {
  if (!list)
    return paramErr;
  OSStatus err = AECreateList(NULL, 0, FALSE, list);
  if (noErr == err) {
    err = WBAEDescListAppendWithArguments(list, args);
    if (noErr != err)
      WBAEDisposeDesc(list);
  }
  return err;
}

OSStatus WBAERecordAppend(AERecord *list, ...) {
  va_list args;
  va_start(args, list);
  OSStatus err = WBAERecordAppendWithArguments(list, args);
  va_end(args);
  return err;
}
OSStatus WBAERecordAppendWithArguments(AERecord *list, va_list args) {
  if (!list)
    return paramErr;
  AEKeyword key;
  const AEDesc *desc;
  OSStatus err = noErr;
  while (noErr == err && (key = va_arg(args, AEKeyword))) {
    desc = va_arg(args, const AEDesc *);
    err = AEPutParamDesc(list, key, desc);
  }
  return err;
}

#pragma mark Errors
OSStatus WBAEGetHandlerError(const AppleEvent* pAEReply) {
  if (!pAEReply)
    return paramErr;

  OSStatus err = noErr;
  if (pAEReply->descriptorType != typeNull ) { // there's a reply, so there may be an error
    SInt32 handlerErr;
    OSStatus getErrErr = noErr;
    getErrErr = WBAEGetSInt32FromAppleEvent(pAEReply, keyErrorNumber, &handlerErr);

    if (getErrErr != errAEDescNotFound) {  // found an errorNumber parameter
      err = handlerErr;                    // so return it's value
    }
  }
  return err;
}

OSStatus WBAECopyErrorStringFromReply(const AppleEvent *reply, CFStringRef *str) {
  return WBAECopyStringFromAppleEvent(reply, keyErrorString, str);
}

#pragma mark -
#pragma mark Internal
//*******************************************************************************
// This routine creates a new handle and puts the contents of the desc
// in that handle.  Carbon's opaque AEDesc's means that we need this
// functionality a lot.
OSStatus WBAECopyHandleFromDescriptor(const AEDesc* pDesc, DescType desiredType, Handle* descData) {
  if (!pDesc || !descData)
    return paramErr;

  WBAEDesc stackdesc;
  OSStatus err = noErr;
  const AEDesc *desc = pDesc;
  if (pDesc->descriptorType != desiredType && desiredType != typeWildCard) {
    desc = &stackdesc;
    err = AECoerceDesc(pDesc, desiredType, &stackdesc);
  }

  if (noErr == err) {
    Size size = AEGetDescDataSize(desc);
    *descData = NewHandle(size);
    err = MemError();
    if (noErr == err)
      err = AEGetDescData(desc, **descData, size);
  };

  return err;
}

OSStatus WBAECopyHandleFromAppleEvent(const AppleEvent* anEvent, AEKeyword aKey, DescType desiredType, Handle *aHandle) {
  if (!anEvent || !aHandle)
    return paramErr;

  WBAEDesc desc;
  OSStatus err = AEGetParamDesc(anEvent, aKey, desiredType, &desc);
  if (noErr == err)
    err = WBAECopyHandleFromDescriptor(anEvent, desiredType, aHandle);
  return err;
}

OSStatus WBAECopyNthHandleFromDescList(const AEDescList *aList, CFIndex idx, DescType aType, Handle *pHandle) {
  if (!aList || !pHandle)
    return paramErr;

  WBAEDesc nthItem;
  OSStatus err = AEGetNthDesc(aList, idx, aType, NULL, &nthItem);
  if (noErr == err)
    err = WBAECopyHandleFromDescriptor(&nthItem, aType, pHandle);
  return err;
}

#pragma mark -
#pragma mark Thread safe Apple Event
// WonderBox note: If min target version is 10.5, do not use the pool as the bug is solved

/////////////////////////////////////////////////////////////////

/*
 How It Works
 ------------
 The basic idea behind this module is that it uses per-thread storage to keep
 track of an Apple event reply for any given thread.  The first time that the
 thread calls AESendMessageThreadSafeSynchronous, the per-thread storage will
 not be initialised and the code will grab an Apple event reply port and
 assign it to the per-thread storage.  Subsequent calls to AESendMessageThreadSafeSynchronous
 will continue to use that port.  When the thread dies, pthreads will automatically
 call the destructor for the per-thread storage, and that will clean up the port.

 Because we can't dispose of the reply port (without triggering the Apple
 Event Manager bug that's the reason we wrote this code in the first place),
 the destructor doesn't actually dispose of the port.  Rather, it adds the
 port to a pool of ports that are available for reuse.  The next time a thread
 needs to allocate a port, it will grab it from the pool rather than allocating
 it from scratch.

 This technique means that the code still 'leaks' Apple event reply ports, but
 the size of the leak is limited to the maximum number of threads that you run
 simultaneously.  This isn't a problem in practice.
 */

/////////////////////////////////////////////////////////////////

// The PerThreadStorage structure is a trivial wrapper around the Mach port.
// I added this because I need to attach this structure a thread using
// per-thread storage.  The API for that (<x-man-page://3/pthread_setspecific>)
// is pointer based.  I could've just cast the Mach port to a (void *), but
// that's ugly because of a) pointer size issues (are pointers always bigger than
// ints?), and b) because it implies an equivalent between NULL and MACH_PORT_NULL.
// Given this, I simply decided to create a structure to wrap the Mach port.

#import <dispatch/dispatch.h>

struct PerThreadStorage {
  mach_port_t     port;

  PerThreadStorage() : port(MACH_PORT_NULL) {
    mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &port);
  }
  ~PerThreadStorage() {
    mach_port_destroy(mach_task_self(), port);
  }
};

// The following static variables manage the per-thread storage key
// (sPerThreadStorageKey) and the pool of Mach ports (wrapped in
// PerThreadStorage structures) that are not currently attached to a thread.

static OSStatus             sPerThreadStorageKeyInitErrNum; // latches result of initialisation

static pthread_key_t        sPerThreadStorageKey = 0;       // key for our per-thread storage

static void PerThreadStorageDestructor(void *keyValue);     // forward declaration

// Main Thread Notes
// -----------------
// There are two reasons why we don't assign a reply port to the main thread.
// First, the main thread already has a reply port created for it by Apple
// Event Manager.  Thus, we don't need a specific reply port.  Also, the
// destructor for per-thread storage isn't called for the main thread, so
// we wouldn't get a chance to clean up (although that's not really a problem
// in practice).

// Get a reply port for this thread, remembering that we've done this
// in per-thread storage.
//
// On success, *replyPortPtr is the port to use for this thread's reply
// port.  It will be MACH_PORT_NULL if you call it from the main thread.
static
OSStatus _BindReplyMachPortToThread(mach_port_t *replyPortPtr) {
  if (!replyPortPtr || *replyPortPtr != MACH_PORT_NULL) return paramErr;

  // Initialise ourselves the first time that we're called.

  static dispatch_once_t sInited;
  dispatch_once(&sInited, ^{
    // Create the per-thread storage key.  Note that we assign a destructor to this key;
    // pthreads call the destructor to clean up that item of per-thread storage whenever
    // a thread terminates.
    OSStatus err = (OSStatus) pthread_key_create(&sPerThreadStorageKey, PerThreadStorageDestructor);
    check(err == noErr);
    sPerThreadStorageKeyInitErrNum = err;
  });

  // If something went wrong, return the latched error.

  OSStatus err = noErr;
  if (sPerThreadStorageKeyInitErrNum != noErr) {
    err = sPerThreadStorageKeyInitErrNum;
  }

  // Now do the real work.
  if (noErr == err) {
    if ( pthread_main_np() ) {
      // This is the main thread, so do nothing; leave *replyPortPtr set
      // to MACH_PORT_NULL.
      check(*replyPortPtr == MACH_PORT_NULL);
    } else {
      PerThreadStorage *storage = (PerThreadStorage *) pthread_getspecific(sPerThreadStorageKey);
      if (!storage) {
        std::unique_ptr<PerThreadStorage> pts(new PerThreadStorage());
        // The per-thread storage hasn't been allocated yet for this specific
        // thread.  Let's go allocate it and attach it to this thread.
        if (pts && pts->port != MACH_PORT_NULL) {
          err = pthread_setspecific(sPerThreadStorageKey, pts.get());
          if (err == 0)
            storage = pts.release();
          else
            err += kPOSIXErrorBase;
        }
      }

      // If all went well, copy the port out to our client.
      if (storage)
        *replyPortPtr = storage->port;
    }
  }
  return err;
}

// Called by pthreads when a thread dies and it has a non-null value for our
// per-thread storage key.  We use this callback to return the thread's
// Apple event reply port to the pool.
static
void PerThreadStorageDestructor(void *keyValue) {
  PerThreadStorage *storage = static_cast<PerThreadStorage *>(keyValue);

  if (storage)
    delete storage;
}

OSStatus WBAESendMessageThreadSafeSynchronous(AppleEvent *event,
                                              AppleEvent *reply,                /* can be NULL */
                                              AESendMode sendMode, long timeOutInTicks) {
  OSStatus err;
  mach_port_t replyPort;
  check(event != NULL);
  check(reply != NULL);
  check(sendMode & kAEWaitReply);

  replyPort = MACH_PORT_NULL;

  // Set up the reply port if necessary.
  err = _BindReplyMachPortToThread(&replyPort);
  if ( (noErr == err) && (MACH_PORT_NULL != replyPort) )
    err = AEPutAttributePtr(event, keyReplyPortAttr, typeMachPort, &replyPort, sizeof(replyPort));

  // Call through to AESendMessage.
  if (noErr == err)
    err = AESendMessage(event, reply, sendMode, timeOutInTicks);

  return err;
}

