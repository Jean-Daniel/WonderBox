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

Boolean WBAEDebug = false;

static
OSStatus WBAESendMessageThreadSafeSynchronous(AppleEvent *event, AppleEvent *reply,
                                              AESendMode sendMode, long timeOutInTicks);

static
void _WBAEPrintDebug(const AEDesc *desc, CFStringRef format, ...) WB_CF_FORMAT(2, 3);
void _WBAEPrintDebug(const AEDesc *desc, CFStringRef format, ...) {
  va_list args;
  va_start(args, format);
  spx::unique_cfptr<CFStringRef> str(CFStringCreateWithFormatAndArguments(kCFAllocatorDefault, nullptr, format, args));
  va_end(args);
  if (str)
    CFShow(str.get());
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

#pragma mark -
#pragma mark Print AEDesc
CFStringRef WBAEDescCopyDescription(const AEDesc *desc) {
  // FIXME: should use aeDescToCFTypeCopy()
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
const AEDesc *WBAESystemTarget() {
  static AEDesc system;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    static ProcessSerialNumber psn = { 0, kSystemProcess };
    AECreateDesc(typeProcessSerialNumber, &psn, sizeof(psn), &system);
  });
  return &system;
}

const AEDesc *WBAECurrentProcessTarget() {
  static AEDesc current;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    static ProcessSerialNumber psn = { 0, kCurrentProcess };
    AECreateDesc(typeProcessSerialNumber, &psn, sizeof(psn), &current);
  });
  return &current;
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
  if (!pid || !target)
    return paramErr;
  return AECreateDesc(typeKernelProcessID, &pid, sizeof(pid), target);
}

OSStatus WBAECreateTargetWithMachPort(mach_port_t port, AEDesc *target) {
  if (!MACH_PORT_VALID(port) || !target) return paramErr;
  return AECreateDesc(typeMachPort, &port, sizeof(port), target);
}

#pragma mark -
#pragma mark Create Object Specifier
OSStatus WBAECreateDescFromURL(CFURLRef anURL, AEDesc *desc) {
  if (!anURL || ! desc) return paramErr;

  spx::unique_cfptr<CFURLRef> absUrl(CFURLCopyAbsoluteURL(anURL));
  if (CFURLIsFileReferenceURL(absUrl.get())) {
    absUrl.reset(CFURLCreateFilePathURL(kCFAllocatorDefault, absUrl.get(), nullptr));
    if (!absUrl)
      return paramErr;
  }
  // TODO: check if this is a file URL

  CFStringRef string = CFURLGetString(absUrl.get());

  char stackStr[512];
  const char *cstr = CFStringGetCStringPtr(string, kCFStringEncodingUTF8);
  if (!cstr && CFStringGetCString(string, stackStr, 512, kCFStringEncodingUTF8))
    cstr = stackStr;

  if (cstr)
    return AECreateDesc(typeFileURL, cstr, strlen(cstr), desc);

  // Fallback to slow path
  CFIndex length = 0;
  std::unique_ptr<uint8_t[]> buffer;
  CFRange range = CFRangeMake(0, CFStringGetLength(string));
  if (CFStringGetBytes(string, range, kCFStringEncodingUTF8, 0, false, nullptr, 0, &length) <= 0)
    return coreFoundationUnknownErr;

  buffer.reset(new uint8_t[length]);
  assert(buffer);

  if (CFStringGetBytes(string, range, kCFStringEncodingUTF8, 0, false, buffer.get(), length, &length) <= 0)
    return coreFoundationUnknownErr;

  return AECreateDesc(typeFileURL, buffer.get(), length, desc);
}

OSStatus WBAECreateDescFromString(CFStringRef string, AEDesc *desc) {
  if (!string || !desc) return paramErr;

  CFIndex length = CFStringGetLength(string);
  // Note: We need to check Size (aka long) overflow.
  // It should be (lenght * sizeof(UniChar) > LONG_MAX), but it may overflow
  if (!length || length > (LONG_MAX / (Size)sizeof(UniChar)))
    return paramErr;

  /* Create Unicode String */
  /* Use stack if length < 512, else use heap */
  UniChar stackStr[512];
  std::unique_ptr<UniChar[]> buffer;

  const UniChar *chars = CFStringGetCharactersPtr(string);
  if (!chars) {
    if (length <= 512) {
      chars = stackStr;
    } else {
      buffer.reset(new UniChar[length]);
      chars = buffer.get();
    }
    CFStringGetCharacters(string, CFRangeMake(0, length), const_cast<UniChar *>(chars));
  }

  return AECreateDesc(typeUnicodeText, chars, length * sizeof(*chars), desc);
}

OSStatus WBAECreateDescFromData(CFDataRef data, DescType type, AEDesc *desc) {
  if (data)
    return AECreateDesc(type, CFDataGetBytePtr(data), CFDataGetLength(data), desc);
  return AECreateDesc(typeNull, nullptr, 0, desc);
}

OSStatus WBAECreateDescFromBookmarkData(CFDataRef bookmark, AEDesc *desc) {
  return WBAECreateDescFromData(bookmark, typeBookmarkData, desc);
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
  wb::AEDesc keyData;

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

  wb::AEDesc keyData;
  OSStatus err = AECreateDesc(typeSInt32, &uid, sizeof(uid), &keyData);
  if (noErr == err)
    err = WBAECreateObjectSpecifier(desiredType, formUniqueID, &keyData, container, specifier);

  return err;
}

OSStatus WBAECreateNameObjectSpecifier(DescType desiredType, CFStringRef name, AEDesc *container, AEDesc *specifier) {
  if (!name || !specifier)
    return paramErr;

  wb::AEDesc keyData;
  OSStatus err = WBAECreateDescFromString(name, &keyData);
  if (noErr == err)
    err = WBAECreateObjectSpecifier(desiredType, formName, &keyData, container, specifier);

  return err;
}

OSStatus WBAECreatePropertyObjectSpecifier(DescType desiredType, AEKeyword property, AEDesc *container, AEDesc *specifier) {
  if (!specifier)
    return paramErr;

  wb::AEDesc keyData;
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

OSStatus WBAECreateEventWithTargetBundleID(CFStringRef targetId, AEEventClass eventClass, AEEventID eventType, AppleEvent *theEvent) {
  if (!targetId || !theEvent)
    return paramErr;

  wb::AEDesc target;
  OSStatus err = WBAECreateTargetWithBundleID(targetId, &target);
  if (noErr == err)
    err = WBAECreateEventWithTarget(&target, eventClass, eventType, theEvent);
  return err;
}

OSStatus WBAECreateEventWithTargetMachPort(mach_port_t port, AEEventClass eventClass, AEEventID eventType, AppleEvent *theEvent) {
  if (!MACH_PORT_VALID(port) || !theEvent)
    return paramErr;

  wb::AEDesc target;
  OSStatus err = WBAECreateTargetWithMachPort(port, &target);
  if (noErr == err)
    err = WBAECreateEventWithTarget(&target, eventClass, eventType, theEvent);
  return err;
}

OSStatus WBAECreateEventWithTargetProcessIdentifier(pid_t pid, AEEventClass eventClass, AEEventID eventType, AppleEvent *theEvent) {
  if (!pid || !theEvent)
    return paramErr;

  wb::AEDesc target;
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

OSStatus WBAEBuildAppleEventWithTargetBundleID(CFStringRef bundleID, AEEventClass theClass, AEEventID theID, AppleEvent *outEvent,
                                               AEBuildError *outError, const char *paramsFmt, ...) {
  va_list args;
  va_start(args, paramsFmt);
  pid_t pid = [NSRunningApplication runningApplicationsWithBundleIdentifier:SPXCFToNSString(bundleID)].firstObject.processIdentifier;
  OSStatus err = vAEBuildAppleEvent(theClass, theID, typeKernelProcessID, &pid, sizeof(pid),
                                    kAutoGenerateReturnID, kAnyTransactionID, outEvent, outError, paramsFmt, args);
  va_end(args);
  return err;
}

#pragma mark -
#pragma mark Add Param & Attr
OSStatus WBAESetStandardAttributes(AppleEvent *theEvent) {
  assert(theEvent != NULL);
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

  wb::AEDesc aeDesc;
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

  wb::AEDesc specifier;
  OSStatus err = WBAECreateIndexObjectSpecifier(desiredType, idx, container, &specifier);
  if (noErr == err)
    err = AEPutParamDesc(theEvent, keyword, &specifier);

  return err;
}

OSStatus WBAEAddUniqueIDObjectSpecifier(AppleEvent *theEvent, AEKeyword keyword, DescType desiredType, SInt32 uid, AEDesc *container) {
  if (!theEvent)
    return paramErr;

  wb::AEDesc specifier;
  OSStatus err = WBAECreateUniqueIDObjectSpecifier(desiredType, uid, container, &specifier);
  if (noErr == err)
    err = AEPutParamDesc(theEvent, keyword, &specifier);

  return err;
}

OSStatus WBAEAddNameObjectSpecifier(AppleEvent *theEvent, AEKeyword keyword, DescType desiredType, CFStringRef name, AEDesc *container) {
  if (!theEvent)
    return paramErr;

  wb::AEDesc specifier;
  OSStatus err = WBAECreateNameObjectSpecifier(desiredType, name, container, &specifier);
  if (noErr == err)
    err = AEPutParamDesc(theEvent, keyword, &specifier);

  return err;
}

OSStatus WBAEAddPropertyObjectSpecifier(AppleEvent *theEvent, AEKeyword keyword, DescType desiredType, AEKeyword property, AEDesc *container) {
  if (!theEvent)
    return paramErr;

  wb::AEDesc specifier;
  OSStatus err = WBAECreatePropertyObjectSpecifier(desiredType, property, container, &specifier);
  if (noErr == err)
    err = AEPutParamDesc(theEvent, keyword, &specifier);

  return err;
}

#pragma mark -
#pragma mark Send AppleEvents
OSStatus WBAESendEventNoReply(const AppleEvent* theEvent) {
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

  wb::AEDesc stackReply;
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
extern "C" void GDBPrintAEDesc(const AEDesc *);
extern "C" CFStringRef aeDescToCFTypeCopy(const AEDesc *);

template<class Ty, OSStatus(*CreateEvent)(Ty, AEEventClass, AEEventID, AppleEvent *)>
static inline OSStatus _WBAESendSimpleEvent(Ty target, AEEventClass eventClass, AEEventID eventType) {
  wb::AppleEvent theEvent;
  OSStatus err = CreateEvent(target, eventClass, eventType, &theEvent);
  if (noErr == err) {
    //WBAESetStandardAttributes(&theEvent);
    err = WBAESendEventNoReply(&theEvent);
  }
  return err;
}

OSStatus WBAESendSimpleEventTo(pid_t pid, AEEventClass eventClass, AEEventID eventType) {
  return _WBAESendSimpleEvent<pid_t, WBAECreateEventWithTargetProcessIdentifier>(pid, eventClass, eventType);
}

OSStatus WBAESendSimpleEventToBundle(CFStringRef bundleID, AEEventClass eventClass, AEEventID eventType) {
  return _WBAESendSimpleEvent<CFStringRef, WBAECreateEventWithTargetBundleID>(bundleID, eventClass, eventType);
}

OSStatus WBAESendSimpleEventToTarget(const AEDesc *target, AEEventClass eventClass, AEEventID eventType) {
  return _WBAESendSimpleEvent<const AEDesc *, WBAECreateEventWithTarget>(target, eventClass, eventType);
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

  wb::AEDesc theReply;
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

  wb::AEDesc theReply;
  OSStatus err = WBAESendEvent(pAppleEvent, kAEWaitReply, kAEDefaultTimeout, &theReply);
  if (noErr == err && theReply.descriptorType != typeNull)
    err = AEGetParamDesc(&theReply, keyDirectObject, pDescType, pAEDesc);

  return err;
}

OSStatus WBAESendEventReturnAEDescList(AppleEvent* pAppleEvent, AEDescList* pAEDescList) {
  if (!pAppleEvent || !pAEDescList)
    return paramErr;

  wb::AEDesc theReply;
  OSStatus err = WBAESendEvent(pAppleEvent, kAEWaitReply, kAEDefaultTimeout, &theReply);
  if (noErr == err) {
    if (theReply.descriptorType != typeNull)
      err = AEGetParamDesc(&theReply, keyDirectObject, typeAEList, pAEDescList);
    else
      WBAEInitDesc(pAEDescList);
  }

  return err;
}

CFStringRef WBAESendEventReturnString(AppleEvent* pAppleEvent, WBAEError pError) {
  wb::AEError<CFStringRef> res(pError);
  if (!pAppleEvent)
    return res(paramErr);

  wb::AEDesc theReply;
  OSStatus err = WBAESendEvent(pAppleEvent, kAEWaitReply, kAEDefaultTimeout, &theReply);
  if (noErr != err)
    return res(err);

  if (theReply.descriptorType != typeNull)
    return WBAECopyStringFromAppleEvent(&theReply, keyDirectObject, pError);
  else
    return res(noErr);
}

CFDataRef WBAESendEventReturnCFData(AppleEvent *pAppleEvent, DescType resultType, DescType *actualType, WBAEError pError) {
  wb::AEError<CFDataRef> res(pError);
  if (!pAppleEvent)
    return res(paramErr);

  if (!resultType)
    resultType = typeData;

  wb::AEDesc theReply;
  OSStatus err = WBAESendEvent(pAppleEvent, kAEWaitReply, kAEDefaultTimeout, &theReply);
  if (noErr != err)
    return res(err);

    if (theReply.descriptorType != typeNull)
      return WBAECopyCFDataFromAppleEvent(&theReply, keyDirectObject, resultType, actualType, pError);
    else
      return res(noErr);
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
    wb::AEDesc desc;
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

#pragma mark CFStringRef
CFStringRef WBAECopyStringFromDescriptor(const AEDesc* pAEDesc, WBAEError pError) {
  wb::AEError<CFStringRef> res(pError);
  if (!pAEDesc)
    return res(paramErr);

  if (typeNull == pAEDesc->descriptorType)
    return res(noErr);

  wb::AEDesc uniAEDesc;
  OSStatus err = AECoerceDesc(pAEDesc, typeUnicodeText, &uniAEDesc);
  if (noErr != err)
    return res(err);

  if (typeUnicodeText != uniAEDesc.descriptorType)
    return res(errAETypeError);

  Size bufSize = AEGetDescDataSize(&uniAEDesc);
  if (bufSize <= 0)
    return CFSTR("");

  CFIndex length = bufSize / sizeof(UniChar);
  std::unique_ptr<UniChar[]> characters(new UniChar[length]);
  err = AEGetDescData(&uniAEDesc, characters.get(), length * sizeof(UniChar));
  if (noErr != err)
    return res(err);

  CFStringRef aString = CFStringCreateWithCharactersNoCopy(kCFAllocatorDefault, characters.get(), length, kCFAllocatorDefault);
  if (!aString)
    return res(coreFoundationUnknownErr);

  characters.release();
  return aString;
}

CFStringRef WBAECopyStringFromAppleEvent(const AppleEvent* anEvent, AEKeyword aKey, WBAEError pError) {
  wb::AEError<CFStringRef> res(pError);
  if (!anEvent)
    return res(paramErr);

  wb::AEDesc strDesc;
  OSStatus err = AEGetParamDesc(anEvent, aKey, typeWildCard, &strDesc);
  if (noErr == err)
    return WBAECopyStringFromDescriptor(&strDesc, pError);

  return res(err);
}

CFStringRef WBAECopyNthStringFromDescList(const AEDescList *aList, CFIndex idx, WBAEError pError) {
  wb::AEError<CFStringRef> res(pError);
  if (!aList)
    return res(paramErr);

  wb::AEDesc nthItem;
  OSStatus err = AEGetNthDesc(aList, idx, typeWildCard, NULL, &nthItem);
  if (noErr == err)
    return WBAECopyStringFromDescriptor(&nthItem, pError);

  return res(err);
}

#pragma mark CFURLRef
CFURLRef WBAECopyFileURLFromDescriptor(const AEDesc* pAEDesc, WBAEError pError) {
  wb::AEError<CFURLRef> res(pError);
  if (!pAEDesc)
    return res(paramErr);

  if (typeNull == pAEDesc->descriptorType)
    return res(noErr);

  wb::AEDesc uniAEDesc;
  OSStatus err = AECoerceDesc(pAEDesc, typeFileURL, &uniAEDesc);
  if (noErr != err)
    return res(err);

  if (typeFileURL != uniAEDesc.descriptorType)
    return res(errAETypeError);

  CFIndex bufSize = AEGetDescDataSize(&uniAEDesc);
  if (bufSize <= 0)
    return res(noErr);

  std::unique_ptr<uint8_t[]> characters(new uint8_t[bufSize]);
  if (!characters)
    return res(memFullErr);

  err = AEGetDescData(&uniAEDesc, characters.get(), bufSize);
  if (noErr != err)
    return res(err);

  CFURLRef url = CFURLCreateWithBytes(kCFAllocatorDefault, characters.get(), bufSize, kCFStringEncodingUTF8, nullptr);
  return url ?: res(coreFoundationUnknownErr);
}

CFURLRef WBAECopyFileURLFromAppleEvent(const AppleEvent* anEvent, AEKeyword aKey, WBAEError pError) {
  wb::AEError<CFURLRef> res(pError);
  if (!anEvent)
    return res(paramErr);

  wb::AEDesc strDesc;
  OSStatus err = AEGetParamDesc(anEvent, aKey, typeWildCard, &strDesc);
  if (noErr == err)
    return WBAECopyFileURLFromDescriptor(&strDesc, pError);

  return res(err);
}

CFURLRef WBAECopyNthFileURLFromDescList(const AEDescList *aList, CFIndex idx, WBAEError pError) {
  wb::AEError<CFURLRef> res(pError);
  if (!aList)
    return res(paramErr);

  wb::AEDesc nthItem;
  OSStatus err = AEGetNthDesc(aList, idx, typeWildCard, nullptr, &nthItem);
  if (noErr == err)
    return WBAECopyFileURLFromDescriptor(&nthItem, pError);

  return res(err);
}

#pragma mark CFDataRef
CFDataRef WBAECopyCFDataFromDescriptor(const AEDesc* aDesc, WBAEError pError) {
  wb::AEError<CFDataRef> res(pError);
  if (!aDesc)
    return res(paramErr);

  if (typeNull == aDesc->descriptorType)
    return res(noErr);

  OSStatus err = noErr;
  Size bufSize = AEGetDescDataSize(aDesc);
  if (bufSize <= 0)
    return CFDataCreate(kCFAllocatorDefault, nullptr, 0);

  std::unique_ptr<uint8_t[]> buffer(new uint8_t[bufSize]);
  assert(buffer);
  err = AEGetDescData(aDesc, buffer.get(), bufSize);
  if (noErr != err)
    return res(err);

  CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, buffer.get(), bufSize, kCFAllocatorDefault);
  if (!data)
    return res(coreFoundationUnknownErr);

  buffer.release();
  return data;
}

CFDataRef WBAECopyCFDataFromAppleEvent(const AppleEvent *anEvent, AEKeyword aKey, DescType aType, DescType *actualType, WBAEError pError) {
  wb::AEError<CFDataRef> res(pError);
  if (!anEvent)
    return res(paramErr);

  wb::AEDesc dataDesc;
  OSStatus err = AEGetParamDesc(anEvent, aKey, aType, &dataDesc);
  if (noErr == err) {
    if (actualType)
      *actualType = dataDesc.descriptorType;
    return WBAECopyCFDataFromDescriptor(&dataDesc, pError);
  }
  return res(err);
}

CFDataRef WBAECopyNthCFDataFromDescList(const AEDescList *aList, CFIndex idx, DescType aType, DescType *actualType, WBAEError pError) {
  wb::AEError<CFDataRef> res(pError);
  if (!aList)
    return res(paramErr);

  wb::AEDesc nthItem;
  OSStatus err = AEGetNthDesc(aList, idx, aType, NULL, &nthItem);
  if (noErr == err) {
    if (actualType)
      *actualType = nthItem.descriptorType;
    return WBAECopyCFDataFromDescriptor(&nthItem, pError);
  }
  return res(err);
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

CFStringRef WBAECopyErrorStringFromReply(const AppleEvent *reply, WBAEError pError) {
  return WBAECopyStringFromAppleEvent(reply, keyErrorString, pError);
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
    assert(err == noErr);
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
      assert(*replyPortPtr == MACH_PORT_NULL);
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
  assert(event != NULL);
  assert(reply != NULL);
  assert(sendMode & kAEWaitReply);

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

