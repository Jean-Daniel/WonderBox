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

#include WBHEADER(WBAEFunctions.h)

Boolean WBAEDebug = false;
OSType WBAEFinderSignature = 'MACS';

static
OSStatus WBAESendMessageThreadSafeSynchronous(AppleEvent *event, AppleEvent *reply,
                                              AESendMode sendMode, long timeOutInTicks);

static 
void _WBAEPrintDebug(const AEDesc *desc, CFStringRef format, ...)	{
  va_list args;
  va_start(args, format);
  CFStringRef str = CFStringCreateWithFormatAndArguments(kCFAllocatorDefault, NULL, format, args);
  va_end(args);
  if (str) {
    CFShow(str);
    CFRelease(str);
  }
}

#define WBAEPrintDebug(desc, format, args...)	({ \
  if (WBAEDebug) { \
    CFStringRef __event = WBAEDescCopyDescription(desc); \
      if (__event) { \
        _WBAEPrintDebug(desc, format, __event, ## args); \
          CFRelease(__event); \
      } \
  } \
})

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
  if (!psn || !target) return paramErr;
  
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
  
  if (noErr == err)
    err = AECreateDesc(typeApplicationBundleID, bundleStr, strlen(bundleStr), target);
  return err;
}

OSStatus WBAECreateTargetWithKernelProcessID(pid_t pid, AEDesc *target) {
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
OSStatus WBAECreateDescFromCFString(CFStringRef string, AEDesc *desc) {
  if (!string || !desc) return paramErr;
  
  OSStatus err;
  /* Create Unicode String */
  /* Use stack if length < 512, else use heap */
  UniChar *str = NULL;
  UniChar stackStr[512];
  
  CFIndex length = CFStringGetLength(string);
  if (!length)
    return paramErr;
  
  CFRange range = CFRangeMake(0, length);
  if (length <= 512) {
    str = stackStr;
  } else {
    str = CFAllocatorAllocate(kCFAllocatorDefault, length * sizeof(UniChar), 0);
    if (!str)
      return memFullErr;
  }
  CFStringGetCharacters(string, range, str);
  err = AECreateDesc(typeUnicodeText, str, length * sizeof(UniChar), desc);
  if (str != stackStr) CFAllocatorDeallocate(kCFAllocatorDefault, str);
  
  return err;
}

OSStatus WBAECreateObjectSpecifier(DescType desiredType, DescType keyForm, AEDesc *keyData, AEDesc *container, AEDesc *specifier) {
  if (!keyData || !specifier) return paramErr;
  
  OSStatus err;
  AEDesc appli = WBAEEmptyDesc();
  err = CreateObjSpecifier(desiredType, (container) ? container : &appli, keyForm, keyData, false, specifier);
  
  return err;
}

OSStatus WBAECreateIndexObjectSpecifier(DescType desiredType, CFIndex idx, AEDesc *container, AEDesc *specifier) {
  if (!specifier) return paramErr;
  
  OSStatus err;
  AEDesc keyData = WBAEEmptyDesc();
  
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
#if __LP64__
      err = AECreateDesc(typeSInt64, &idx, sizeof(SInt64), &keyData);
#else
      err = AECreateDesc(typeSInt32, &idx, sizeof(SInt32), &keyData);
#endif
  }

  if (noErr == err) {
    err = WBAECreateObjectSpecifier(desiredType, formAbsolutePosition, &keyData, container, specifier);
    AEDisposeDesc(&keyData);
  }
  
  return err;
}

OSStatus WBAECreateUniqueIDObjectSpecifier(DescType desiredType, SInt32 uid, AEDesc *container, AEDesc *specifier) {
  if (!specifier) return paramErr;
  
  OSStatus err;
  AEDesc keyData = WBAEEmptyDesc();
  err = AECreateDesc(typeSInt32, &uid, sizeof(uid), &keyData);
  if (noErr == err) {
    err = WBAECreateObjectSpecifier(desiredType, formUniqueID, &keyData, container, specifier);
    AEDisposeDesc(&keyData);
  }
  
  return err;
}

OSStatus WBAECreateNameObjectSpecifier(DescType desiredType, CFStringRef name, AEDesc *container, AEDesc *specifier) {
  if (!name || !specifier) return paramErr;
  
  OSStatus err;
  AEDesc keyData = WBAEEmptyDesc();
  err = WBAECreateDescFromCFString(name, &keyData);
  if (noErr == err) {
    err = WBAECreateObjectSpecifier(desiredType, formName, &keyData, container, specifier);
    AEDisposeDesc(&keyData);
  }
  
  return err;
}

OSStatus WBAECreatePropertyObjectSpecifier(DescType desiredType, AEKeyword property, AEDesc *container, AEDesc *specifier) {
  if (!specifier) return paramErr;
  
  OSStatus err;
  AEDesc keyData = WBAEEmptyDesc();  
  err = AECreateDesc(typeType, &property, sizeof(AEKeyword), &keyData);
  if (noErr == err) {
    err = WBAECreateObjectSpecifier(desiredType, formPropertyID, &keyData, container, specifier);
    AEDisposeDesc(&keyData);
  }
  
  return err;
}

#pragma mark -
#pragma mark Create AppleEvents
OSStatus WBAECreateEventWithTarget(const AEDesc *target, AEEventClass eventClass, AEEventID eventType, AppleEvent *theEvent) {
  if (!target || !theEvent) return paramErr;
  
  WBAEInitDesc(theEvent);
  return AECreateAppleEvent(eventClass, eventType,
                            target,
                            kAutoGenerateReturnID,
                            kAnyTransactionID,
                            theEvent);
}

OSStatus WBAECreateEventWithTargetProcess(ProcessSerialNumber *psn, AEEventClass eventClass, AEEventID eventType, AppleEvent *theEvent) {
  if (!psn || !theEvent) return paramErr;
  
  OSStatus err = noErr;
  AEDesc target = WBAEEmptyDesc();
  err = WBAECreateTargetWithProcess(psn, &target);
  if (noErr == err) {
    err = WBAECreateEventWithTarget(&target, eventClass, eventType, theEvent);
    WBAEDisposeDesc(&target);
  }
  return err;
}

OSStatus WBAECreateEventWithTargetSignature(OSType targetSign, AEEventClass eventClass, AEEventID eventType, AppleEvent *theEvent) {
  if (!targetSign || !theEvent) return paramErr;
  
  OSStatus err = noErr;
  AEDesc target = WBAEEmptyDesc();
  err = WBAECreateTargetWithSignature(targetSign, &target);
  if (noErr == err) {
    err = WBAECreateEventWithTarget(&target, eventClass, eventType, theEvent);
    WBAEDisposeDesc(&target);
  }
  return err;
}

OSStatus WBAECreateEventWithTargetBundleID(CFStringRef targetId, AEEventClass eventClass, AEEventID eventType, AppleEvent *theEvent) {
  if (!targetId || !theEvent) return paramErr;
  
  OSStatus err = noErr;
  AEDesc target = WBAEEmptyDesc();
  err = WBAECreateTargetWithBundleID(targetId, &target);
  if (noErr == err) {
    err = WBAECreateEventWithTarget(&target, eventClass, eventType, theEvent);
    WBAEDisposeDesc(&target);
  }
  return err;
}

OSStatus WBAECreateEventWithTargetMachPort(mach_port_t port, AEEventClass eventClass, AEEventID eventType, AppleEvent *theEvent) {
  if (!MACH_PORT_VALID(port) || !theEvent) return paramErr;
  
  OSStatus err = noErr;
  AEDesc target = WBAEEmptyDesc();
  err = WBAECreateTargetWithMachPort(port, &target);
  if (noErr == err) {
    err = WBAECreateEventWithTarget(&target, eventClass, eventType, theEvent);
    WBAEDisposeDesc(&target);
  }
  return err;
}

OSStatus WBAECreateEventWithTargetKernelProcessID(pid_t pid, AEEventClass eventClass, AEEventID eventType, AppleEvent *theEvent) {
  if (!pid || !theEvent) return paramErr;
  
  OSStatus err = noErr;
  AEDesc target = WBAEEmptyDesc();
  err = WBAECreateTargetWithKernelProcessID(pid, &target);
  if (noErr == err) {
    err = WBAECreateEventWithTarget(&target, eventClass, eventType, theEvent);
    WBAEDisposeDesc(&target);
  }
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
  check(theEvent != NULL);
  return AEPutAttributeDesc(theEvent, 'subj' /* keySubjectAttr */,
                            subject);
}
OSStatus WBAESetEventConsiderations(AppleEvent *theEvent, UInt32 flags) {
  check(theEvent != NULL);
  // flags = kAECaseIgnoreMask; // ignore all
  return AEPutAttributePtr(theEvent, 'csig' /* enumConsidsAndIgnores */,
                           typeUInt32, &flags, sizeof(flags));
}

OSStatus WBAEAddAEDescWithData(AppleEvent *theEvent, AEKeyword theAEKeyword, DescType typeCode, const void * dataPtr, Size dataSize) {
  check(theEvent != NULL);
  
  OSStatus err = noErr;
  AEDesc aeDesc = WBAEEmptyDesc();
  
  err = AECreateDesc(typeCode, dataPtr, dataSize, &aeDesc);
  require_noerr(err, Bail);
  
  err = AEPutParamDesc(theEvent, theAEKeyword, &aeDesc);
  require_noerr(err, Bail);
  
Bail:
    AEDisposeDesc(&aeDesc);
  return err;
}

OSStatus WBAEAddFSRefAsAlias(AppleEvent *theEvent, AEKeyword keyword, const FSRef *aRef) {
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

OSStatus WBAEAddCFStringAsUnicodeText(AppleEvent *theEvent, AEKeyword keyword, CFStringRef str) {
  check(theEvent != NULL);
  
  OSStatus err = noErr;
  if (str) {
    UniChar buffer[2048];
    Boolean release = false;
    CFIndex length = CFStringGetLength(str);
    UniChar *chr = (UniChar *)CFStringGetCharactersPtr(str);
    if (!chr) {
      if (length < 2048) {
        chr = buffer;
      } else {
        release = true;
        chr = CFAllocatorAllocate(kCFAllocatorDefault, length * sizeof(UniChar), 0);
      }
      CFStringGetCharacters(str, CFRangeMake(0, length), chr);
    }
    // typeUnicodeText: native byte ordering, optional BOM
    err = WBAEAddParameter(theEvent, keyword, typeUnicodeText, chr, length * sizeof(UniChar));
  
    if (release)
      CFAllocatorDeallocate(kCFAllocatorDefault, chr);
  } else {
    err = WBAEAddParameter(theEvent, keyword, typeNull, NULL, 0);
  }
  return err;
}

OSStatus WBAEAddIndexObjectSpecifier(AppleEvent *theEvent, AEKeyword keyword, DescType desiredType, CFIndex idx, AEDesc *container) {
  check(theEvent != NULL);
  
  OSStatus err;
  AEDesc specifier = WBAEEmptyDesc();
  err = WBAECreateIndexObjectSpecifier(desiredType, idx, container, &specifier);
  if (noErr == err) {
    err = AEPutParamDesc(theEvent, keyword, &specifier);
  }
  AEDisposeDesc(&specifier);
  
  return err;
}

OSStatus WBAEAddUniqueIDObjectSpecifier(AppleEvent *theEvent, AEKeyword keyword, DescType desiredType, SInt32 uid, AEDesc *container) {
  check(theEvent != NULL);
  
  OSStatus err;
  AEDesc specifier = WBAEEmptyDesc();
  err = WBAECreateUniqueIDObjectSpecifier(desiredType, uid, container, &specifier);
  if (noErr == err) {
    err = AEPutParamDesc(theEvent, keyword, &specifier);
  }
  AEDisposeDesc(&specifier);
  
  return err;
}

OSStatus WBAEAddNameObjectSpecifier(AppleEvent *theEvent, AEKeyword keyword, DescType desiredType, CFStringRef name, AEDesc *container) {
  check(theEvent != NULL);
  
  OSStatus err;
  AEDesc specifier = WBAEEmptyDesc();
  err = WBAECreateNameObjectSpecifier(desiredType, name, container, &specifier);
  if (noErr == err) {
    err = AEPutParamDesc(theEvent, keyword, &specifier);
  }
  AEDisposeDesc(&specifier);
  
  return err;
}

OSStatus WBAEAddPropertyObjectSpecifier(AppleEvent *theEvent, AEKeyword keyword, DescType desiredType, AEKeyword property, AEDesc *container) {
  check(theEvent != NULL);
  
  OSStatus err;
  AEDesc specifier = WBAEEmptyDesc();
  err = WBAECreatePropertyObjectSpecifier(desiredType, property, container, &specifier);
  if (noErr == err) {
    err = AEPutParamDesc(theEvent, keyword, &specifier);
  }
  AEDisposeDesc(&specifier);
  
  return err;
}

#pragma mark -
#pragma mark Send AppleEvents
OSStatus WBAESendEventNoReply(AppleEvent* theEvent) {
  check(theEvent != NULL);
  
  OSStatus		err = noErr;
  AppleEvent	theReply = WBAEEmptyDesc();
  
  WBAEPrintDebug(theEvent, CFSTR("Send event no Reply: %@\n"));
  err = AESendMessage(theEvent, &theReply, kAENoReply, kAEDefaultTimeout);
  WBAEDisposeDesc( &theReply );
  
  return err;
}

OSStatus WBAESendEvent(AppleEvent	*pAppleEvent, AESendMode sendMode, SInt64 timeoutms, AppleEvent *theReply) {
  check(pAppleEvent != NULL);
  
  if (theReply)
    WBAEInitDesc(theReply);
  
  WBAEPrintDebug(pAppleEvent, CFSTR("Send event: %@\n"));
  
  AEDesc stackReply = WBAEEmptyDesc();
  AppleEvent *reply = theReply ? : &stackReply;
  
  /* Convert timeout ms into timeout ticks */
  long timeout = 0;
  if (timeoutms <= 0)
    timeout = (long)timeoutms;
  else
    timeout = lround(timeoutms * (60 / 1e3F));
  
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
  if (reply != theReply)
    WBAEDisposeDesc(reply);
  
  return err;
}

#pragma mark Simple Events
OSStatus WBAESendSimpleEvent(OSType targetSign, AEEventClass eventClass, AEEventID eventType) {
  OSStatus err = noErr;
  AEDesc theEvent = WBAEEmptyDesc();
  
  err = WBAECreateEventWithTargetSignature(targetSign, eventClass, eventType, &theEvent);
  if (noErr == err) {
    //WBAESetStandardAttributes(&theEvent);
    
    err = WBAESendEventNoReply(&theEvent);
    WBAEDisposeDesc(&theEvent);
  }
  return err;
}

OSStatus WBAESendSimpleEventToBundle(CFStringRef bundleID, AEEventClass eventClass, AEEventID eventType) {
  OSStatus err = noErr;
  AEDesc theEvent = WBAEEmptyDesc();
  
  err = WBAECreateEventWithTargetBundleID(bundleID, eventClass, eventType, &theEvent);
  if (noErr == err) {
    //WBAESetStandardAttributes(&theEvent);
    
    err = WBAESendEventNoReply(&theEvent);
    WBAEDisposeDesc(&theEvent);
  }
  return err;
}

OSStatus WBAESendSimpleEventToProcess(ProcessSerialNumber *psn, AEEventClass eventClass, AEEventID eventType) {
  check(psn != NULL);
  
  OSStatus err = noErr;
  AEDesc theEvent = WBAEEmptyDesc();
  
  err = WBAECreateEventWithTargetProcess(psn, eventClass, eventType, &theEvent);
  if (noErr == err) {
    //WBAESetStandardAttributes(&theEvent);
    
    err = WBAESendEventNoReply(&theEvent);
    WBAEDisposeDesc(&theEvent);
  }
  return err;
}

#pragma mark Primitive Reply

OSStatus WBAESendEventReturnData(AppleEvent	*pAppleEvent,
                                 DescType			pDesiredType,
                                 DescType*			pActualType,
                                 void*		 		pDataPtr,
                                 Size				pMaximumSize,
                                 Size 				*pActualSize) {
  check(pAppleEvent != NULL);
  
  OSStatus err = noErr;
  AppleEvent theReply = WBAEEmptyDesc();
  err = WBAESendEvent(pAppleEvent, kAEWaitReply, kAEDefaultTimeout, &theReply);
  if (noErr == err && theReply.descriptorType != typeNull) {
    err = WBAEGetDataFromAppleEvent(&theReply, keyDirectObject, pDesiredType, 
                                    pActualType, pDataPtr, pMaximumSize, pActualSize);
    WBAEDisposeDesc(&theReply);
  }
  return err;
}

OSStatus WBAESendEventReturnBoolean(AppleEvent* pAppleEvent, Boolean* pValue) {
  check(pAppleEvent != NULL);
  Size actualSize;
  DescType actualType;
  return WBAESendEventReturnData(pAppleEvent, typeBoolean,
                                 &actualType, pValue, sizeof(Boolean), &actualSize);
}

OSStatus WBAESendEventReturnSInt16(AppleEvent* pAppleEvent, SInt16* pValue) {
  check(pAppleEvent != NULL);
  Size actualSize;
  DescType actualType;
  return WBAESendEventReturnData(pAppleEvent, typeSInt16,
                                 &actualType, pValue, sizeof(SInt16), &actualSize);
}

OSStatus WBAESendEventReturnSInt32(AppleEvent* pAppleEvent, SInt32* pValue) {
  check(pAppleEvent != NULL);
  Size actualSize;
  DescType actualType;
  return WBAESendEventReturnData(pAppleEvent, typeSInt32,
                                 &actualType, pValue, sizeof(SInt32), &actualSize);
}

OSStatus WBAESendEventReturnUInt32(AppleEvent* pAppleEvent, UInt32* pValue) {
  check(pAppleEvent != NULL);
  Size actualSize;
  DescType actualType;
  return WBAESendEventReturnData(pAppleEvent, typeUInt32,
                                 &actualType, pValue, sizeof(UInt32), &actualSize);
}

OSStatus WBAESendEventReturnSInt64(AppleEvent* pAppleEvent, SInt64* pValue) {
  check(pAppleEvent != NULL);
  Size actualSize;
  DescType actualType;
  return WBAESendEventReturnData(pAppleEvent, typeSInt64,
                                 &actualType, pValue, sizeof(SInt64), &actualSize);
}

OSStatus WBAESendEventReturnUInt64(AppleEvent* pAppleEvent, UInt64* pValue) {
	check(pAppleEvent != NULL);
  Size actualSize;
  DescType actualType;
  return WBAESendEventReturnData(pAppleEvent, typeUInt64,
                                 &actualType, pValue, sizeof(UInt64), &actualSize);
}

#pragma mark Object Reply
OSStatus WBAESendEventReturnAEDesc(AppleEvent *pAppleEvent, const DescType pDescType, AEDesc *pAEDesc) {
  check(pAppleEvent != NULL);
  
  OSStatus err = noErr;
  AppleEvent theReply = WBAEEmptyDesc();
  err = WBAESendEvent(pAppleEvent, kAEWaitReply, kAEDefaultTimeout, &theReply);
  if (noErr == err && theReply.descriptorType != typeNull) {
    err = AEGetParamDesc(&theReply, keyDirectObject, pDescType, pAEDesc);
    WBAEDisposeDesc(&theReply);
  }
  
  return err;
}

OSStatus WBAESendEventReturnAEDescList(AppleEvent* pAppleEvent, AEDescList* pAEDescList) {
  check(pAppleEvent != NULL);
  
  OSStatus err = noErr;
  AppleEvent theReply = WBAEEmptyDesc();
  err = WBAESendEvent(pAppleEvent, kAEWaitReply, kAEDefaultTimeout, &theReply);
  if (noErr == err && theReply.descriptorType != typeNull) {
    err = AEGetParamDesc(&theReply, keyDirectObject, typeAEList, pAEDescList);
    WBAEDisposeDesc(&theReply);
  }
  return err;
}

OSStatus WBAESendEventReturnCFString(AppleEvent* pAppleEvent, CFStringRef* string) {
  check(string != NULL);
  check(*string == NULL);
  check(pAppleEvent != NULL);
  
  AppleEvent theReply = WBAEEmptyDesc();  
  OSStatus err = WBAESendEvent(pAppleEvent, kAEWaitReply, kAEDefaultTimeout, &theReply);
  if (noErr == err && theReply.descriptorType != typeNull) {
    err = WBAECopyCFStringFromAppleEvent(&theReply, keyDirectObject, string);
    WBAEDisposeDesc(&theReply);
  }
  return err;
}

OSStatus WBAESendEventReturnCFData(AppleEvent	*pAppleEvent, DescType resultType, DescType *actualType, CFDataRef *data) {
  check(data != NULL);
  check(*data == NULL);
  check(pAppleEvent != NULL);
  
  OSStatus err = noErr;
  *data = NULL;
  
  AppleEvent theReply = WBAEEmptyDesc();
  if (!resultType) resultType = typeData;
  
  err = WBAESendEvent(pAppleEvent, kAEWaitReply, kAEDefaultTimeout, &theReply);
  if (noErr == err && theReply.descriptorType != typeNull) {
    err = WBAECopyCFDataFromAppleEvent(&theReply, keyDirectObject, resultType, actualType, data);
    WBAEDisposeDesc(&theReply);
  }
  return err;
}

#pragma mark -
#pragma mark Retreive AEDesc Data
OSStatus WBAEGetDataFromDescriptor(const AEDesc* pAEDesc, DescType desiredType, DescType* typeCode, void *dataPtr, Size maximumSize, Size *pActualSize) {
  check(pAEDesc);
  check(dataPtr);
  
  OSStatus err = noErr;
  if (pActualSize) *pActualSize = 0;
  if (typeCode) *typeCode = pAEDesc->descriptorType;
  /* Coerce if needed */
  if (desiredType != typeWildCard && desiredType != pAEDesc->descriptorType) { 
    AEDesc desc = WBAEEmptyDesc();
    err = AECoerceDesc(pAEDesc, desiredType, &desc);
    if (noErr == err) {
      err = AEGetDescData(&desc, dataPtr, maximumSize);
      if (pActualSize && noErr == err)
        *pActualSize = AEGetDescDataSize(&desc);
      
      WBAEDisposeDesc(&desc);
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
OSStatus WBAECopyCFStringFromDescriptor(const AEDesc* pAEDesc, CFStringRef* aString) {
  check(pAEDesc != NULL);
  check(aString != NULL);
  check(*aString == NULL);
  
  if (typeNull == pAEDesc->descriptorType) {
    return noErr;
  } else {
    AEDesc uniAEDesc = WBAEEmptyDesc();
    OSStatus err = AECoerceDesc(pAEDesc, typeUnicodeText, &uniAEDesc);
    if (noErr == err) {
      if (typeUnicodeText == uniAEDesc.descriptorType) {
        Size bufSize = AEGetDescDataSize(&uniAEDesc);
        if (bufSize > 0) {
          UniChar *characters = CFAllocatorAllocate(kCFAllocatorDefault, bufSize, 0);
          if (NULL != characters) {
            err = AEGetDescData(&uniAEDesc, characters, bufSize);
            if (noErr == err) {
              *aString = CFStringCreateWithCharactersNoCopy(kCFAllocatorDefault, characters, bufSize / sizeof(UniChar), kCFAllocatorDefault);
              if (!*aString) {
                err = coreFoundationUnknownErr;
                CFAllocatorDeallocate(kCFAllocatorDefault, characters);
              }
            }
          } else {
            err = memFullErr;
          }
        } else { /* bufSize <= 0 */
          *aString = CFSTR("");
        }
      }
      WBAEDisposeDesc(&uniAEDesc);
    }
    return err;
  }
}

OSStatus WBAECopyCFStringFromAppleEvent(const AppleEvent* anEvent, AEKeyword aKey, CFStringRef* aString) {
  check(anEvent != NULL);
  check(aString != NULL);
  check(*aString == NULL);

  AEDesc strDesc = WBAEEmptyDesc();
  OSStatus err = AEGetParamDesc(anEvent, aKey, typeWildCard, &strDesc);
  
  if (noErr == err) {
    err = WBAECopyCFStringFromDescriptor(&strDesc, aString);
  }
  
  WBAEDisposeDesc(&strDesc);
  return err;
}

OSStatus WBAECopyNthCFStringFromDescList(const AEDescList *aList, CFIndex idx, CFStringRef *aString) {
  check(aList != NULL);
  check(aString != NULL);
  check(*aString == NULL);
  
  AEDesc nthItem = WBAEEmptyDesc();
  
  OSStatus err = AEGetNthDesc(aList, idx, typeWildCard, NULL, &nthItem);
  if (noErr == err) {
    err = WBAECopyCFStringFromDescriptor(&nthItem, aString);
  }
  
  WBAEDisposeDesc(&nthItem);
  return err;
}

#pragma mark CFDataRef
OSStatus WBAECopyCFDataFromDescriptor(const AEDesc* aDesc, CFDataRef *data) {
  check(aDesc != NULL);
  check(data != NULL);
  check(*data == NULL);
  
  OSStatus err = noErr;
  if (typeNull == aDesc->descriptorType) {
    return noErr;
  } else {
    Size bufSize = AEGetDescDataSize(aDesc);
    if (bufSize > 0) {
      UInt8 *buffer = CFAllocatorAllocate(kCFAllocatorDefault, bufSize, 0);
      if (NULL != buffer) {
        err = AEGetDescData(aDesc, buffer, bufSize);
        if (noErr == err)
          *data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, buffer, bufSize, kCFAllocatorDefault);
        
        if (!*data) {
          err = coreFoundationUnknownErr;
          CFAllocatorDeallocate(kCFAllocatorDefault, buffer);
        }
      } else {
        err = memFullErr;
      }
    } else { // bufSize <= 0
      /* return empty data */
      *data = CFDataCreate(kCFAllocatorDefault, NULL, 0);
    }
  }
  return err;
}

OSStatus WBAECopyCFDataFromAppleEvent(const AppleEvent *anEvent, AEKeyword aKey, DescType aType, DescType *actualType, CFDataRef *data) {
  check(anEvent != NULL);
  check(data != NULL);
  check(*data == NULL);
  
  AEDesc dataDesc = WBAEEmptyDesc();
  OSStatus err = AEGetParamDesc(anEvent, aKey, aType, &dataDesc);
  
  if (noErr == err) {
		if (actualType) *actualType = dataDesc.descriptorType;
    err = WBAECopyCFDataFromDescriptor(&dataDesc, data);
  }
  
  WBAEDisposeDesc(&dataDesc);
  return err;
}

OSStatus WBAECopyNthCFDataFromDescList(const AEDescList *aList, CFIndex idx, DescType aType, DescType *actualType, CFDataRef *data) {
  check(aList != NULL);
  check(data != NULL);
  check(*data == NULL);
  
  AEDesc nthItem = WBAEEmptyDesc();
  OSStatus err = AEGetNthDesc(aList, idx, aType, NULL, &nthItem);
  if (noErr == err) {
		if (actualType) *actualType = nthItem.descriptorType;
    err = WBAECopyCFDataFromDescriptor(&nthItem, data);
  }
  
  WBAEDisposeDesc(&nthItem);
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
  if (!list) return paramErr;
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
  if (!list) return paramErr;
  const AEDesc *desc;
  OSStatus err = noErr;
  while (noErr == err && (desc = va_arg(args, const AEDesc *))) {
    err = AEPutDesc(list, 0, desc);
  }
  return err;
}

OSStatus WBAEDescListGetCount(const AEDescList *list, CFIndex *count) {
	check(count);
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
  if (!list) return paramErr;
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
  if (!list) return paramErr;
  AEKeyword key;
  const AEDesc *desc;
  OSStatus err = noErr;
  while (noErr == err && (key = va_arg(args, AEKeyword))) {
    desc = va_arg(args, const AEDesc *);
    check(desc);
    err = AEPutParamDesc(list, key, desc);
  }
  return err;
}

#pragma mark Errors
OSStatus WBAEGetHandlerError(const AppleEvent* pAEReply) {
  check(pAEReply != NULL);
  
  OSStatus err = noErr;
  if (pAEReply->descriptorType != typeNull ) {	// there's a reply, so there may be an error
    SInt32 handlerErr;
    OSStatus getErrErr = noErr;
    getErrErr = WBAEGetSInt32FromAppleEvent(pAEReply, keyErrorNumber, &handlerErr);
    
    if (getErrErr != errAEDescNotFound) {	// found an errorNumber parameter
      err = handlerErr;					// so return it's value
    }
  }
  return err;
}

OSStatus WBAECopyErrorStringFromReply(const AppleEvent *reply, CFStringRef *str) {
  return WBAECopyCFStringFromAppleEvent(reply, keyErrorString, str);
}

#pragma mark -
#pragma mark Internal
//*******************************************************************************
// This routine creates a new handle and puts the contents of the desc
// in that handle.  Carbon's opaque AEDesc's means that we need this
// functionality a lot.
OSStatus WBAECopyHandleFromDescriptor(const AEDesc* pDesc, DescType desiredType, Handle* descData) {
  check(pDesc != NULL);
  check(descData != NULL);
	
  OSStatus err = noErr;
	const AEDesc *desc = pDesc;
	AEDesc stackdesc = WBAEEmptyDesc();
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
	}
	WBAEDisposeDesc(&stackdesc);
	
	return err;
}

OSStatus WBAECopyHandleFromAppleEvent(const AppleEvent* anEvent, AEKeyword aKey, DescType desiredType, Handle *aHandle) {
	check(anEvent != NULL);
	check(aHandle != NULL);
	
	AEDesc desc = WBAEEmptyDesc();
	OSStatus err = AEGetParamDesc(anEvent, aKey, desiredType, &desc);
	if (noErr == err) {
		err = WBAECopyHandleFromDescriptor(anEvent, desiredType, aHandle);
		WBAEDisposeDesc(&desc);
	}
  return err;
}

OSStatus WBAECopyNthHandleFromDescList(const AEDescList *aList, CFIndex idx, DescType aType, Handle *pHandle) {
  check(aList != NULL);
  check(pHandle != NULL);
  
  AEDesc nthItem = WBAEEmptyDesc();
  OSStatus err = AEGetNthDesc(aList, idx, aType, NULL, &nthItem);
  if (noErr == err)
    err = WBAECopyHandleFromDescriptor(&nthItem, aType, pHandle);
  
  WBAEDisposeDesc(&nthItem);
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

enum {
  kPerThreadStorageMagic = 'PTSm'
};

struct PerThreadStorage {
  OSType          magic;          // must be kPerThreadStorageMagic
  mach_port_t     port;
};
typedef struct PerThreadStorage PerThreadStorage;

// The following static variables manage the per-thread storage key 
// (sPerThreadStorageKey) and the pool of Mach ports (wrapped in 
// PerThreadStorage structures) that are not currently attached to a thread.
static pthread_once_t       sInited = PTHREAD_ONCE_INIT;    // covers initialisation of all of the following static variables

static OSStatus             sPerThreadStorageKeyInitErrNum; // latches result of initialisation

static pthread_key_t        sPerThreadStorageKey = 0;       // key for our per-thread storage

#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_5
static pthread_mutex_t      sPoolMutex;                     // protects sPool
static CFMutableArrayRef    sPool;                          // array of (PerThreadStorage *), holds the ports that aren't currently bound to a thread
#endif

static void PerThreadStorageDestructor(void *keyValue);     // forward declaration

static void InitRoutine(void)
// Call once (via pthread_once) to initialise various static variables.
{
  OSStatus    err;
  
  // Create the per-thread storage key.  Note that we assign a destructor to this key; 
  // pthreads call the destructor to clean up that item of per-thread storage whenever 
  // a thread terminates.
  
  err = (OSStatus) pthread_key_create(&sPerThreadStorageKey, PerThreadStorageDestructor);
  
#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_5
  // Create the pool of Mach ports that aren't bound to any thread, and its associated 
  // lock.  The pool starts out empty.
  if (err == noErr) {
    err = (OSStatus) pthread_mutex_init(&sPoolMutex, NULL);
  }
  if (err == noErr) {
    sPool = CFArrayCreateMutable(NULL, 0, NULL);
    if (sPool == NULL) {
      err = coreFoundationUnknownErr;
    }
  }
#endif
  check(err == noErr);
  
  sPerThreadStorageKeyInitErrNum = err;
}

// Grab a Mach port from sPool; if sPool is empty, create one.
static
OSStatus _AllocatePortFromPool(PerThreadStorage **storagePtr) {
  OSStatus err = noErr;
  PerThreadStorage *storage = NULL;
  
  check(storagePtr != NULL);
  check(*storagePtr == NULL);
  
#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_5
  // First try to get an entry from pool.  We try to grab the last one because 
  // that minimises the amount of copying that CFArrayRemoveValueAtIndex has to 
  // do.
  
  err = (OSStatus) pthread_mutex_lock(&sPoolMutex);
  if (err == noErr) {
    OSStatus junk;
    CFIndex poolCount;
    
    poolCount = CFArrayGetCount(sPool);
    if (poolCount > 0) {
      storage = (PerThreadStorage *) CFArrayGetValueAtIndex(sPool, poolCount - 1);
      CFArrayRemoveValueAtIndex(sPool, poolCount - 1);
    }
    
    junk = (OSStatus) pthread_mutex_unlock(&sPoolMutex);
    check(junk == noErr);
  }
#endif
  // If we failed to find an entry in the pool, create a new one.
  
  if ( (err == noErr) && (storage == NULL) ) {
    storage = (PerThreadStorage *) malloc(sizeof(*storage));
    if (storage == NULL) {
      err = memFullErr;
    } else {
      storage->magic = kPerThreadStorageMagic;
      storage->port  = MACH_PORT_NULL;
      
      err = (OSStatus) mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &storage->port);
      if (err != noErr) {
        check(storage->port == MACH_PORT_NULL);
        free(storage);
        storage = NULL;
      }
    }
  }
  if (err == noErr) {
    *storagePtr = storage;
  }
  
  check( (err == noErr) == (*storagePtr != NULL) );
  check( (*storagePtr == NULL) || ((*storagePtr)->magic == kPerThreadStorageMagic) );
  check( (*storagePtr == NULL) || ((*storagePtr)->port  != MACH_PORT_NULL) );
  
  return err;
}

// Returns a port to sPool.
static 
void _ReturnPortToPool(PerThreadStorage * storage) {
  OSStatus err;
  
  check(storage != NULL);
  check(storage->magic == kPerThreadStorageMagic);
  check(storage->port  != MACH_PORT_NULL);
#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_5
  err = (OSStatus) pthread_mutex_lock(&sPoolMutex);
  if (err == noErr) {
    CFArrayAppendValue(sPool, storage);
    
    err = (OSStatus) pthread_mutex_unlock(&sPoolMutex);
  }
#else
  err = (OSStatus) mach_port_destroy(mach_task_self(), storage->port);
  free(storage);
#endif
  check(err == noErr);
}


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
  OSStatus err;
  
  check( replyPortPtr != NULL);
  check(*replyPortPtr == MACH_PORT_NULL);
  
  // Initialise ourselves the first time that we're called.
  
  err = (OSStatus) pthread_once(&sInited, InitRoutine);
  
  // If something went wrong, return the latched error.
  
  if ( (noErr == err) && (sPerThreadStorageKeyInitErrNum != noErr) ) {
    err = sPerThreadStorageKeyInitErrNum;
  }
  
  // Now do the real work.
  if (noErr == err) {
    if ( pthread_main_np() ) {
      // This is the main thread, so do nothing; leave *replyPortPtr set 
      // to MACH_PORT_NULL.
      check(*replyPortPtr == MACH_PORT_NULL);
    } else {
      PerThreadStorage *  storage;
      
      // Get the per-thread storage for this thread.
      storage = (PerThreadStorage *) pthread_getspecific(sPerThreadStorageKey);
      if (storage == NULL) {
        
        // The per-thread storage hasn't been allocated yet for this specific 
        // thread.  Let's go allocate it and attach it to this thread.
        err = _AllocatePortFromPool(&storage);
        if (err == noErr) {
          err = (OSStatus) pthread_setspecific(sPerThreadStorageKey, (void *) storage);
          if (err != noErr) {
            _ReturnPortToPool(storage);
            storage = NULL;
          }
        }
      }
      check( (err == noErr) == (storage != NULL) );
      
      // If all went well, copy the port out to our client.
      
      if (err == noErr) {
        check(storage->magic == kPerThreadStorageMagic);
        check(storage->port  != MACH_PORT_NULL);
        *replyPortPtr = storage->port;
      }
    }
  }
  
  // no error + MACH_PORT_NULL is a valid response if we're on the main 
  // thread.
  //
  // check( (err == noErr) == (*replyPortPtr != MACH_PORT_NULL) );
  check( (*replyPortPtr == MACH_PORT_NULL) || (err == noErr) );
  return err;
}

// Called by pthreads when a thread dies and it has a non-null value for our 
// per-thread storage key.  We use this callback to return the thread's 
// Apple event reply port to the pool.
static
void PerThreadStorageDestructor(void *keyValue) {
  PerThreadStorage *  storage;
  
  storage = (PerThreadStorage *) keyValue;
  check(storage != NULL);                    // pthread won't call us if it's NULL
  check(storage->magic == kPerThreadStorageMagic);
  check(storage->port  != MACH_PORT_NULL);
  
  // Return the port associated with this thread to the pool.
  _ReturnPortToPool(storage);
  
  // pthreads has already set this thread's per-thread storage for our key to 
  // NULL before calling us. So we don't need to do anything to remove it.
  check( pthread_getspecific(sPerThreadStorageKey) == NULL );
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

