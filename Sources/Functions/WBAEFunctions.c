/*
 *  WBAEFunctions.c
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

#include "AESendThreadSafe.h"

#include WBHEADER(WBAEFunctions.h)
#include WBHEADER(WBProcessFunctions.h)

Boolean WBAEDebug = false;
OSType WBAEFinderSignature = 'MACS';

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
  CFStringRef str = NULL;
  OSStatus err;
  Handle handle;
  err = AEPrintDescToHandle(desc, &handle);
  if (noErr == err) {
    str = CFStringCreateWithCString(kCFAllocatorDefault, *handle, kCFStringEncodingASCII);
    DisposeHandle(handle);
  }
  return str;
}

OSStatus WBAEPrintDesc(const AEDesc *desc) {
  OSStatus err;
  Handle str;
  err = AEPrintDescToHandle(desc, &str);
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
  check(psn != NULL);
  check(target != NULL);
  
  OSStatus err = noErr;
  WBAEInitDesc(target);
  if (psn->highLongOfPSN != kNoProcess || psn->lowLongOfPSN != kNoProcess) {
    err = AECreateDesc(typeProcessSerialNumber, psn, sizeof(ProcessSerialNumber), target);
  } else {
    err = paramErr;
  }
  return err;
}

OSStatus WBAECreateTargetWithSignature(OSType sign, Boolean findProcess, AEDesc *target) {
  check(target != NULL);
  
  OSStatus err = noErr;
  WBAEInitDesc(target);
  ProcessSerialNumber psn = {kNoProcess, kNoProcess};
  if (findProcess) {
    psn = WBProcessGetProcessWithSignature(sign);
  }
  if (psn.lowLongOfPSN != kNoProcess) {
    err = WBAECreateTargetWithProcess(&psn, target);
  } else {
    err = AECreateDesc(typeApplSignature, &sign, sizeof(OSType), target);
  }
  return err;
}

OSStatus WBAECreateTargetWithBundleID(CFStringRef bundleId, Boolean findProcess, AEDesc *target) {
  check(target != NULL);
  
  OSStatus err = noErr;
  WBAEInitDesc(target);
  ProcessSerialNumber psn = {kNoProcess, kNoProcess};
  if (findProcess) {
    psn = WBProcessGetProcessWithBundleIdentifier(bundleId);
  }
  if (psn.lowLongOfPSN != kNoProcess) {
    err = WBAECreateTargetWithProcess(&psn, target);
  } else {
    char bundleStr[512];
    if (!CFStringGetCString(bundleId, bundleStr, 512, kCFStringEncodingUTF8)) {
      err = paramErr; 
    }
    if (noErr == err) {
      err = AECreateDesc(typeApplicationBundleID, bundleStr, strlen(bundleStr), target);
    }
  }
  return err;
}

OSStatus WBAECreateTargetWithKernelProcessID(pid_t pid, AEDesc *target) {
  check(target != NULL);
  return AECreateDesc(typeKernelProcessID, &pid, sizeof(pid), target);
}

OSStatus WBAECreateTargetWithMachPort(mach_port_t port, AEDesc *target) {
  check(target != NULL);
  return AECreateDesc(typeMachPort, &port, sizeof(port), target);
}

#pragma mark -
#pragma mark Create Object Specifier
OSStatus WBAECreateDescWithCFString(CFStringRef string, AEDesc *desc) {
  check(desc != NULL);
  check(string != NULL);
  
  OSStatus err;
  /* Create Unicode String */
  /* Use stack if length < 255, else use heap */
  UniChar *str = NULL;
  UniChar stackStr[255];
  
  CFIndex length = CFStringGetLength(string);
  if (!length)
    return paramErr;
  
  CFRange range = CFRangeMake(0, length);
  if (length <= 255) {
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
  check(keyData != NULL);
  check(specifier != NULL);
  
  OSStatus err;
  AEDesc appli = WBAEEmptyDesc();
  err = CreateObjSpecifier(desiredType, (container) ? container : &appli, keyForm, keyData, false, specifier);
  
  return err;
}

OSStatus WBAECreateIndexObjectSpecifier(DescType desiredType, CFIndex idx, AEDesc *container, AEDesc *specifier) {
  check(specifier != NULL);
  
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
  check(specifier != NULL);
  
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
  check(name != NULL);
  check(specifier != NULL);
  
  OSStatus err;
  AEDesc keyData = WBAEEmptyDesc();
  err = WBAECreateDescWithCFString(name, &keyData);
  if (noErr == err) {
    err = WBAECreateObjectSpecifier(desiredType, formName, &keyData, container, specifier);
    AEDisposeDesc(&keyData);
  }
  
  return err;
}

OSStatus WBAECreatePropertyObjectSpecifier(DescType desiredType, AEKeyword property, AEDesc *container, AEDesc *specifier) {
  check(specifier != NULL);
  
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
  check(target != NULL);  
  check(theEvent != NULL); 
  
  WBAEInitDesc(theEvent);
  return AECreateAppleEvent(eventClass, eventType,
                            target,
                            kAutoGenerateReturnID,
                            kAnyTransactionID,
                            theEvent);
}

OSStatus WBAECreateEventWithTargetProcess(ProcessSerialNumber *psn, AEEventClass eventClass, AEEventID eventType, AppleEvent *theEvent) {
  check(psn != NULL);
  check(theEvent != NULL);
  
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
  check(targetSign != 0);
  check(theEvent != NULL);
  
  OSStatus err = noErr;
  AEDesc target = WBAEEmptyDesc();
  err = WBAECreateTargetWithSignature(targetSign, false, &target);
  if (noErr == err) {
    err = WBAECreateEventWithTarget(&target, eventClass, eventType, theEvent);
    WBAEDisposeDesc(&target);
  }
  return err;
}

OSStatus WBAECreateEventWithTargetBundleID(CFStringRef targetId, AEEventClass eventClass, AEEventID eventType, AppleEvent *theEvent) {
  check(targetId != NULL);
  check(theEvent != NULL);
  
  OSStatus err = noErr;
  AEDesc target = WBAEEmptyDesc();
  err = WBAECreateTargetWithBundleID(targetId, false, &target);
  if (noErr == err) {
    err = WBAECreateEventWithTarget(&target, eventClass, eventType, theEvent);
    WBAEDisposeDesc(&target);
  }
  return err;
}

OSStatus WBAECreateEventWithTargetMachPort(mach_port_t port, AEEventClass eventClass, AEEventID eventType, AppleEvent *theEvent) {
  check(theEvent != NULL);
  check(MACH_PORT_VALID(port));
  
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
  check(theEvent != NULL);
  
  OSStatus err = noErr;
  AEDesc target = WBAEEmptyDesc();
  err = WBAECreateTargetWithKernelProcessID(pid, &target);
  if (noErr == err) {
    err = WBAECreateEventWithTarget(&target, eventClass, eventType, theEvent);
    WBAEDisposeDesc(&target);
  }
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
  
    err = AEPutParamPtr(theEvent, keyword, typeUnicodeText, chr, length * sizeof(UniChar));
  
    if (release)
      CFAllocatorDeallocate(kCFAllocatorDefault, chr);
  } else {
    err = AEPutParamPtr(theEvent, keyword, typeNull, NULL, 0);
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
    AESendMessageThreadSafeSynchronous(pAppleEvent, reply, sendMode, timeout) :
    AESendMessage(pAppleEvent, reply, sendMode, timeout);
  
  if (noErr == err) {
    err = WBAEGetHandlerError(reply);
    if (noErr != err) {
      /* Print error message with explication if supported, else print the event */
      const char *str = GetMacOSStatusErrorString(err);
      const char *comment = GetMacOSStatusCommentString(err);
      WBAEPrintDebug(reply, CFSTR("AEDesc Reply: %@ (%s, %s)\n"), str, comment);
      WBAEDisposeDesc(reply);
    } else {
      WBAEPrintDebug(reply, CFSTR("AEDesc Reply: %@\n"));
    }
  }
  if (reply != theReply)
    WBAEDisposeDesc(reply);
  
  return err;
}

OSStatus WBAESendSimpleEvent(OSType targetSign, AEEventClass eventClass, AEEventID eventType) {
  OSStatus err = noErr;
  AEDesc theEvent = WBAEEmptyDesc();
  
  err = WBAECreateEventWithTargetSignature(targetSign, eventClass, eventType, &theEvent);
  if (noErr == err) {
    WBAESetStandardAttributes(&theEvent);
    
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
    WBAESetStandardAttributes(&theEvent);
    
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
    WBAESetStandardAttributes(&theEvent);
    
    err = WBAESendEventNoReply(&theEvent);
    WBAEDisposeDesc(&theEvent);
  }
  return err;
}

OSStatus WBAESendEventNoReply(AppleEvent* theEvent) {
  check(theEvent != NULL);
  
  OSStatus		err = noErr;
  AppleEvent	theReply = WBAEEmptyDesc();
  
  WBAEPrintDebug(theEvent, CFSTR("Send event no Reply: %@\n"));
  err = AESendMessage(theEvent, &theReply, kAENoReply, kAEDefaultTimeout);
  WBAEDisposeDesc( &theReply );
  
  return err;
}

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
    err = AEGetParamPtr(&theReply, keyDirectObject, pDesiredType,
                        pActualType, pDataPtr, pMaximumSize, pActualSize);
    WBAEDisposeDesc(&theReply);
  }
  return err;
}

OSStatus WBAESendEventReturnBoolean(AppleEvent* pAppleEvent, Boolean* pValue) {
  check(pAppleEvent != NULL);
  
  DescType			actualType;
  Size 				actualSize;
  
  return WBAESendEventReturnData(pAppleEvent, typeBoolean,
                                 &actualType, pValue, sizeof(Boolean), &actualSize);
}

OSStatus WBAESendEventReturnSInt16(AppleEvent* pAppleEvent, SInt16* pValue) {
  check(pAppleEvent != NULL);
  
  DescType			actualType;
  Size 				actualSize;
  
  return WBAESendEventReturnData(pAppleEvent, typeSInt16,
                                 &actualType, pValue, sizeof(SInt16), &actualSize);
}

OSStatus WBAESendEventReturnSInt32(AppleEvent* pAppleEvent, SInt32* pValue) {
  check(pAppleEvent != NULL);
  
  DescType			actualType;
  Size 				actualSize;
  
  return WBAESendEventReturnData(pAppleEvent, typeSInt32,
                                 &actualType, pValue, sizeof(SInt32), &actualSize);
}

OSStatus WBAESendEventReturnUInt32(AppleEvent* pAppleEvent, UInt32* pValue) {
  check(pAppleEvent != NULL);
  
  DescType			actualType;
  Size 				actualSize;
  
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
      if (pActualSize && noErr == err) {
        *pActualSize = AEGetDescDataSize(&desc);
      }
      WBAEDisposeDesc(&desc);
    }
  } else {
    err = AEGetDescData(pAEDesc, dataPtr, maximumSize);
    if (pActualSize && noErr == err) {
      *pActualSize = AEGetDescDataSize(pAEDesc);
    }
  }
  return err;
}

OSStatus WBAECopyAliasFromDescriptor(const AEDesc* pAEDesc, AliasHandle *pAlias) {
	return WBAECopyHandleFromDescriptor(pAEDesc, typeAlias, (Handle *)pAlias);
}
OSStatus WBAECopyAliasFromAppleEvent(const AppleEvent* anEvent, AEKeyword aKey, AliasHandle *pAlias) {
	return WBAECopyHandleFromAppleEvent(anEvent, aKey, typeAlias, (Handle *)pAlias);
}
OSStatus WBAECopyNthAliasFromDescList(const AEDescList *aList, CFIndex idx, AliasHandle *pAlias) {
	return WBAECopyNthHandleFromDescList(aList, idx, typeAlias, (Handle *)pAlias);
}

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
  SInt16 handlerErr;
  Size actualSize;
  DescType actualType;
  
  if (pAEReply->descriptorType != typeNull ) {	// there's a reply, so there may be an error
    OSStatus	getErrErr = noErr;
    
    getErrErr = AEGetParamPtr(pAEReply, keyErrorNumber, typeSInt32, &actualType,
                              &handlerErr, sizeof(OSStatus), &actualSize );
    
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
#pragma mark Finder
OSStatus WBAEFinderGetSelection(AEDescList *items) {
  OSStatus err = noErr;
  AEDesc theEvent = WBAEEmptyDesc();
  
  err = WBAECreateEventWithTargetSignature(WBAEFinderSignature, kAECoreSuite, kAEGetData, &theEvent);
  if (noErr == err) {
    err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeAEList, pSelection, NULL);
  }
  if (noErr == err) {
    err = WBAESetStandardAttributes(&theEvent);
  }
  if (noErr == err) {
    err = WBAESendEventReturnAEDescList(&theEvent, items);
  }
  WBAEDisposeDesc(&theEvent);
  return err;
}

OSStatus WBAEFinderSelectionToFSRefs(AEDescList *items, FSRef *selection, CFIndex maxCount, CFIndex *itemsCount) {
  OSStatus err = noErr;
  long numDocs;
  CFIndex count = 0;
  AEKeyword	keyword = 0;
  
  err = AECountItems(items, &numDocs);
  
  if (noErr == err) {
    for (long idx = 1; (idx <= numDocs) && (count < maxCount); idx++) {
      AEDesc tAEDesc = WBAEEmptyDesc();
      
      err = AEGetNthDesc(items, idx, typeWildCard, &keyword, &tAEDesc);
      if (noErr == err) {
        // Si c'est un objet, on le transforme en FSRef.
        if (typeObjectSpecifier == tAEDesc.descriptorType) {
          err = WBAEFinderGetObjectAsFSRef(&tAEDesc, &selection[count]);
        }
        else {
          // Si ce n'est pas une FSRef, on coerce.
          if (typeFSRef != tAEDesc.descriptorType) {
            err = AECoerceDesc(&tAEDesc, typeFSRef, &tAEDesc);
          } 
          if (noErr == err) {
            err = AEGetDescData(&tAEDesc, &selection[count], sizeof(FSRef));
          }
        }
        if (noErr == err) {
          count++;
        }
        WBAEDisposeDesc(&tAEDesc);
      }
    } // End for
  }
  *itemsCount = count;
  return err;
} //end WBAEFinderSelectionToFSRefs

OSStatus WBAEFinderGetObjectAsAlias(const AEDesc* pAEDesc, AliasHandle *alias) {
  AppleEvent theEvent = WBAEEmptyDesc();	//	If you always init AEDescs, it's always safe to dispose of them.
  OSStatus err = noErr;
  
  // the descriptor pointer, alias handle is required
  if (NULL == pAEDesc || NULL == alias)
    return paramErr;
  
  if (typeObjectSpecifier != pAEDesc->descriptorType)
    return paramErr;	// this has to be an object specifier
  
  err = WBAECreateEventWithTargetSignature(WBAEFinderSignature, kAECoreSuite, kAEGetData, &theEvent);
  
  if (noErr == err) {
    err = AEPutParamDesc(&theEvent, keyDirectObject, pAEDesc);
  }
  if (noErr == err) {
    err = WBAESetRequestType(&theEvent, typeAlias);
  }
  if (noErr == err)
    err = WBAESetStandardAttributes(&theEvent);
  
  if (noErr == err) {
    AEDesc tAEDesc;
    err = WBAESendEventReturnAEDesc(&theEvent, typeAlias, &tAEDesc);
    if (noErr == err) {
      err = WBAECopyAliasFromDescriptor(&tAEDesc, alias);
      WBAEDisposeDesc(&tAEDesc);	// always dispose of AEDescs when you are finished with them
    }
  }
  WBAEDisposeDesc(&theEvent);	// always dispose of AEDescs when you are finished with them
  return err;
}

OSStatus WBAEFinderGetObjectAsFSRef(const AEDesc* pAEDesc, FSRef *file) {
  AppleEvent theEvent = WBAEEmptyDesc();	//	If you always init AEDescs, it's always safe to dispose of them.
  OSStatus err = noErr;
  
  // the descriptor pointer, alias handle is required
  if (NULL == pAEDesc || NULL == file)
    return paramErr;
  
  if (typeObjectSpecifier != pAEDesc->descriptorType)
    return paramErr;	// this has to be an object specifier
  
  err = WBAECreateEventWithTargetSignature(WBAEFinderSignature, kAECoreSuite, kAEGetData, &theEvent);
  
  if (noErr == err) {
    err = AEPutParamDesc(&theEvent, keyDirectObject, pAEDesc);
  }
  if (noErr == err) {
    err = WBAESetRequestType(&theEvent, typeFSRef);
  }
  if (noErr == err)
    err = WBAESetStandardAttributes(&theEvent);
  
  if (noErr == err) {
    AEDesc tAEDesc;
    err = WBAESendEventReturnAEDesc(&theEvent, typeFSRef, &tAEDesc);
    if (noErr == err) {
      // Si ce n'est pas une FSRef, on coerce.
      if (typeFSRef != tAEDesc.descriptorType) {
        err = AECoerceDesc(&tAEDesc, typeFSRef, &tAEDesc);
      } 
      if (noErr == err) {
        err = AEGetDescData(&tAEDesc, file, sizeof(FSRef));
      }
    }
    WBAEDisposeDesc(&tAEDesc);	// always dispose of AEDescs when you are finished with them
  }
  WBAEDisposeDesc(&theEvent);	// always dispose of AEDescs when you are finished with them
  return err;
}

#pragma mark Current Folder
OSStatus WBAEFinderGetCurrentFolder(FSRef *folder) {
  OSStatus err = noErr;
  AEDesc theEvent = WBAEEmptyDesc();
  AEDesc result = WBAEEmptyDesc();
  
  err = WBAECreateEventWithTargetSignature(WBAEFinderSignature, kAECoreSuite, kAEGetData, &theEvent);
  if (noErr == err) {
    err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, 'cfol', pInsertionLoc, NULL);
  }
  if (noErr == err) {
    err = WBAESetStandardAttributes(&theEvent);
  }
  if (noErr == err) {
    err = WBAESendEventReturnAEDesc(&theEvent, typeObjectSpecifier, &result);
  }
  if (noErr == err) {
    err = WBAEFinderGetObjectAsFSRef(&result, folder);
  }
  
  WBAEDisposeDesc(&theEvent);
  WBAEDisposeDesc(&result);
  return err;
}

CFURLRef WBAEFinderCopyCurrentFolderURL() {
  FSRef folder;
  CFURLRef url = NULL;
  if (noErr == WBAEFinderGetCurrentFolder(&folder)) {
    url = CFURLCreateFromFSRef(kCFAllocatorDefault, &folder);
  }
  return url;
}

CFStringRef WBAEFinderCopyCurrentFolderPath() {
  CFStringRef path = NULL;
  CFURLRef url = WBAEFinderCopyCurrentFolderURL();
  if (url) {
    path = CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
    CFRelease(url);
  }
  return path;
  
}

#pragma mark Sync
OSStatus WBAEFinderSyncItem(const AEDesc *item) {
  AppleEvent aevt = WBAEEmptyDesc();
  OSStatus err = WBAECreateEventWithTargetSignature(WBAEFinderSignature,
                                                    'fndr', /* kAEFinderSuite, */ 
                                                    'fupd', /* kAESync, */
                                                    &aevt);
  require_noerr(err, dispose);
  
  err = WBAEAddAEDesc(&aevt, keyDirectObject, item);
  require_noerr(err, dispose);
  
  err = WBAESetStandardAttributes(&aevt);
  require_noerr(err, dispose);
  
  err = WBAESendEventNoReply(&aevt);
  require_noerr(err, dispose);
  
dispose:
    WBAEDisposeDesc(&aevt);
  return err;
}

OSStatus WBAEFinderSyncFSRef(const FSRef *aRef) {
  check(aRef);
  AEDesc item = WBAEEmptyDesc();
  OSStatus err = AECreateDesc(typeFSRef, aRef, sizeof(FSRef), &item);
  require_noerr(err, dispose);
  
  err = WBAEFinderSyncItem(&item);
  require_noerr(err, dispose);
  
dispose:
    WBAEDisposeDesc(&item);
  return err;
}

OSStatus WBAEFinderSyncItemAtURL(CFURLRef url) {
  check(url);
  FSRef ref;
  OSStatus err = paramErr;
  if (CFURLGetFSRef(url, &ref)) {
    err = WBAEFinderSyncFSRef(&ref);
  }
  return err;
}

#pragma mark Reveal Item
OSStatus WBAEFinderRevealItem(const AEDesc *item, Boolean activate) {
  OSStatus err = noErr;
  AppleEvent aevt = WBAEEmptyDesc();
  
  if (activate) {
    err = WBAESendSimpleEvent(WBAEFinderSignature, kAEMiscStandards, kAEActivate);
    require_noerr(err, dispose);
  }
  
  err = WBAECreateEventWithTargetSignature(WBAEFinderSignature, kAEMiscStandards, kAEMakeObjectsVisible, &aevt);
  require_noerr(err, dispose);
  
  err = WBAEAddAEDesc(&aevt, keyDirectObject, item);
  require_noerr(err, dispose);
  
  err = WBAESetStandardAttributes(&aevt);
  require_noerr(err, dispose);
  
  err = WBAESendEventNoReply(&aevt);
  require_noerr(err, dispose);
  
dispose:
    WBAEDisposeDesc(&aevt);
  return err;
}

OSStatus WBAEFinderRevealFSRef(const FSRef *aRef, Boolean activate) {
  check(aRef);
  AEDesc item = WBAEEmptyDesc();
  OSStatus err = AECreateDesc(typeFSRef, aRef, sizeof(FSRef), &item);
  require_noerr(err, dispose);
  
  err = WBAEFinderRevealItem(&item, activate);
  require_noerr(err, dispose);
  
dispose:
    WBAEDisposeDesc(&item);
  return err;
}

OSStatus WBAEFinderRevealItemAtURL(CFURLRef url, Boolean activate) {
  check(url);
  FSRef ref;
  OSStatus err = paramErr;
  if (CFURLGetFSRef(url, &ref)) {
    err = WBAEFinderRevealFSRef(&ref, activate);
  }
  return err;
}

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

