/*
 *  WBAEFunctions.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#if !defined(__WB_AE_FUNCTIONS_H)
#define __WB_AE_FUNCTIONS_H 1

#include <WonderBox/WBBase.h>
#include <ApplicationServices/ApplicationServices.h>

typedef OSStatus *WBAEError;

#if defined(__cplusplus)

namespace wb {
  struct AEDesc : ::AEDesc {
    inline AEDesc() {
      AEInitializeDescInline(this);
    }

    inline ~AEDesc() {
      AEDisposeDesc(this);
    }

    WB_DISALLOW_COPY_ASSIGN_MOVE(AEDesc);
  };

  struct AEDescList : AEDesc {};
  struct AERecord : AEDescList {};
  struct AppleEvent : AERecord {};

  template <typename Ty, Ty ErrorValue = nullptr>
  struct AEError {
    inline AEError(WBAEError p) : ptr(p) {
      if (p) *p = noErr;
    }

    Ty operator()(OSStatus err) {
      if (ptr)
        *ptr = err;
      return ErrorValue;
    }
  private:
    OSStatus *ptr;
  };
}

#endif

__BEGIN_DECLS

/*!
 @header WBAEFunctions
 @abstract   AppleEvent Utilities.
 @discussion A set of AppleEvent Manipulation functions.
 */

WB_EXPORT
Boolean WBAEDebug;

#pragma mark -
#pragma mark AEDesc Constructor & Destructor
/**************************** AEDesc Constructor & Destructor ****************************/
/*!
 @function
 @abstract Set descriptorType to <code>typeNull</code> and dataHandle to <code>nil</code>.
 desc must not be nil.
 @param desc The descriptor you want initialize. Cannot be nil.
 */
WB_INLINE
void WBAEInitDesc(AEDesc *desc) {
  assert(desc);
  AEInitializeDescInline(desc);
}

/*!
 @function
 @result Returns a new initialized descriptor
 */
WB_INLINE
AEDesc WBAEEmptyDesc(void) {
  AEDesc desc;
  AEInitializeDescInline(&desc);
  return desc;
}

/*!
 @function
 @abstract Disposes of desc and initialises it to the null descriptor.
           desc must not be nil.
 @param    desc The descriptor you want to dispose. Cannot be nil.
 */
WB_INLINE
OSStatus WBAEDisposeDesc(AEDesc *desc) {
  assert(desc);
  return AEDisposeDesc(desc);
}

#pragma mark -
#pragma mark Print AEDesc
/**************************** Print AEDesc ****************************/
/*!
 @function
 @abstract   Print descriptor description in stdout.
 @discussion See TN2045 «AEBuild*, AEPrint* and Friends» for more informations on output format.
 @param      desc the descriptor to print.
 @result     A result code.
 */
WB_EXPORT
OSStatus WBAEPrintDesc(const AEDesc *desc);

/*!
 @function
 @abstract   Copy description of an AEDesc.
 @param      desc A descriptor.
 @result     A CFStringRef representing the desc or <i>null</i> if an error occured.
 */
WB_EXPORT
CFStringRef WBAEDescCopyDescription(const AEDesc *desc);

#pragma mark -
#pragma mark Find Target for AppleEvents
/**************************** Find Target for AppleEvents ****************************/
WB_EXPORT const AEDesc *WBAESystemTarget(void);
WB_EXPORT const AEDesc *WBAECurrentProcessTarget(void);

WB_EXPORT OSStatus WBAECreateTargetWithBundleID(CFStringRef bundleId, AEDesc *target);
WB_EXPORT OSStatus WBAECreateTargetWithProcessIdentifier(pid_t pid, AEDesc *target);
/* additional targets */
WB_EXPORT OSStatus WBAECreateTargetWithMachPort(mach_port_t port, AEDesc *target);

#pragma mark -
#pragma mark Create Complex Desc
WB_EXPORT OSStatus WBAECreateDescFromURL(CFURLRef anURL, AEDesc *desc);
WB_EXPORT OSStatus WBAECreateDescFromString(CFStringRef string, AEDesc *desc);
WB_EXPORT OSStatus WBAECreateDescFromBookmarkData(CFDataRef bookmark, AEDesc *desc);
WB_EXPORT OSStatus WBAECreateDescFromData(CFDataRef data, DescType type, AEDesc *desc);

#pragma mark Create Object Specifier
WB_EXPORT OSStatus WBAECreateObjectSpecifier(DescType desiredType, DescType keyForm, AEDesc *keyData, AEDesc *container, AEDesc *specifier);

WB_EXPORT OSStatus WBAECreateIndexObjectSpecifier(DescType desiredType, CFIndex idx, AEDesc *container, AEDesc *specifier);
WB_EXPORT OSStatus WBAECreateUniqueIDObjectSpecifier(DescType desiredType, SInt32 uid, AEDesc *container, AEDesc *specifier);
WB_EXPORT OSStatus WBAECreateNameObjectSpecifier(DescType desiredType, CFStringRef name, AEDesc *container, AEDesc *specifier);
WB_EXPORT OSStatus WBAECreatePropertyObjectSpecifier(DescType desiredType, AEKeyword property, AEDesc *container, AEDesc *specifier);

#pragma mark -
#pragma mark Create AppleEvents
/**************************** Create AppleEvents ****************************/
WB_EXPORT
OSStatus WBAECreateEventWithTarget(const AEDesc *target, AEEventClass eventClass, AEEventID eventType, AppleEvent *pAppleEvent);

/*!
 @function
 @abstract   Create an AppleEvent with target a "typeApplicationBundleID" AEDesc.
 @param      targetId The bundle identifier of target application.
 @param      eventClass The event class of the Apple event to create.
 @param      eventType The event ID of the Apple event to create.
 @param      pAppleEvent A pointer to an Apple event.
 On successful return, the new Apple event. On error, a null descriptor.
 If the function returns successfully, your application should call the <i>AEDisposeDesc</i>
 function to dispose of the resulting Apple event after it has finished using it.
 @result     A result code.
 */
WB_EXPORT
OSStatus WBAECreateEventWithTargetBundleID(CFStringRef targetId, AEEventClass eventClass, AEEventID eventType, AppleEvent *pAppleEvent);

WB_EXPORT
OSStatus WBAECreateEventWithTargetProcessIdentifier(pid_t pid, AEEventClass eventClass, AEEventID eventType, AppleEvent *theEvent);

WB_EXPORT
OSStatus WBAECreateEventWithTargetMachPort(mach_port_t port, AEEventClass eventClass, AEEventID eventType, AppleEvent *theEvent);

#pragma mark Build variants
WB_EXPORT
OSStatus WBAEBuildAppleEventWithTarget(const AEDesc *target, AEEventClass theClass, AEEventID theID, AppleEvent *outEvent,
                                       AEBuildError *outError, const char *paramsFmt, ...);

WB_EXPORT
OSStatus WBAEBuildAppleEventWithTargetBundleID(CFStringRef bundleID, AEEventClass theClass, AEEventID theID, AppleEvent *outEvent,
                                               AEBuildError *outError, const char *paramsFmt, ...);

WB_EXPORT
OSStatus WBAEBuildAppleEventWithTargetProcessIdentifier(pid_t pid, AEEventClass theClass, AEEventID theID, AppleEvent *outEvent,
                                                        AEBuildError *outError, const char *paramsFmt, ...);

#pragma mark -
#pragma mark Add Param & Attr
/**************************** Add Param & Attr ****************************/

WB_INLINE
OSStatus WBAEAddAEDesc(AppleEvent *theEvent, AEKeyword keyword, const AEDesc *desc) {
  return AEPutParamDesc(theEvent, keyword, desc);
}

WB_INLINE
OSStatus WBAEAddParameter(AppleEvent *theEvent, AEKeyword keyword, DescType typeCode, const void *dataPtr, Size dataSize) {
  return AEPutParamPtr(theEvent, keyword, typeCode, dataPtr, dataSize);
}

/*!
 @function
 @abstract Simple wrapper on <i>AEPutParamPtr</i> to add a signed short.
 @param    theEvent A pointer to the Apple event to add an attribute to.
 @param    keyword The keyword for the parameter to add.
           If the Apple event already includes an parameter with this keyword, the parameter is replaced.
 @param    value Value to set.
 @result   A result code.
 */
WB_INLINE
OSStatus WBAEAddSInt16(AppleEvent *theEvent, AEKeyword keyword, SInt16 value) {
  return WBAEAddParameter(theEvent, keyword, typeSInt16, &value, sizeof(SInt16));
}
/*!
 @function
 @abstract   Simple wrapper on <i>AEPutParamPtr</i> to add a signed long.
 @param      theEvent A pointer to the Apple event to add an attribute to.
 @param      keyword The keyword for the parameter to add.
 If the Apple event already includes an parameter with this keyword, the parameter is replaced.
 @param      value Value to set.
 @result     A result code.
 */
WB_INLINE
OSStatus WBAEAddSInt32(AppleEvent *theEvent, AEKeyword keyword, SInt32 value) {
  return WBAEAddParameter(theEvent, keyword, typeSInt32, &value, sizeof(SInt32));
}

/*!
 @function
 @abstract   Simple wrapper on <i>AEPutParamPtr</i> to add an unsigned long.
 @param      theEvent A pointer to the Apple event to add an attribute to.
 @param      keyword The keyword for the parameter to add.
 If the Apple event already includes an parameter with this keyword, the parameter is replaced.
 @param      value Value to set.
 @result     A result code.
 */
WB_INLINE
OSStatus WBAEAddUInt32(AppleEvent *theEvent, AEKeyword keyword, UInt32 value) {
  return WBAEAddParameter(theEvent, keyword, typeUInt32, &value, sizeof(UInt32));
}

WB_INLINE
OSStatus WBAEAddSInt64(AppleEvent *theEvent, AEKeyword keyword, SInt64 value) {
  return WBAEAddParameter(theEvent, keyword, typeSInt64, &value, sizeof(SInt64));
}

WB_INLINE
OSStatus WBAEAddUInt64(AppleEvent *theEvent, AEKeyword keyword, UInt64 value) {
  return WBAEAddParameter(theEvent, keyword, typeUInt64, &value, sizeof(UInt64));
}

/*!
 @function
 @abstract   Simple wrapper on <i>AEPutParamPtr</i> to add a Boolean.
 @param      theEvent A pointer to the Apple event to add an attribute to.
 @param      keyword The keyword for the parameter to add.
 If the Apple event already includes an parameter with this keyword, the parameter is replaced.
 @param      flag Boolean to set.
 @result     A result code.
 */
WB_INLINE
OSStatus WBAEAddBoolean(AppleEvent *theEvent, AEKeyword keyword, Boolean flag) {
  UInt8 value = flag ? 1 : 0;
  return WBAEAddParameter(theEvent, keyword, typeBoolean, &value, sizeof(UInt8));
}

WB_INLINE
OSStatus WBAEAddCFData(AppleEvent *theEvent, AEKeyword keyword, DescType type, CFDataRef data) {
  if (data)
    return WBAEAddParameter(theEvent, keyword, type ? : typeData, CFDataGetBytePtr(data), CFDataGetLength(data));
  else
    return WBAEAddParameter(theEvent, keyword, typeNull, NULL, 0);
}

WB_EXPORT
OSStatus WBAEAddFileURL(AppleEvent *theEvent, AEKeyword keyword, CFURLRef url);

WB_INLINE
OSStatus WBAEAddBookmarkData(AppleEvent *theEvent, AEKeyword keyword, CFDataRef data) {
  return WBAEAddCFData(theEvent, keyword, typeBookmarkData, data);
}

/*!
 @function
 @discussion This function add an <code>typeUnicodeText</code> parameter that contains CFString characters.
 @param    theEvent A pointer to the Apple event to add an attribute to.
 @param      keyword The keyword for the parameter to add.
 @param      str The string to set.
 @result     A result code.
 */
WB_EXPORT
OSStatus WBAEAddStringAsUnicodeText(AppleEvent *theEvent, AEKeyword keyword, CFStringRef str);

WB_EXPORT
OSStatus WBAEAddIndexObjectSpecifier(AppleEvent *theEvent, AEKeyword keyword, DescType desiredType, CFIndex idx, AEDesc *container);

WB_EXPORT
OSStatus WBAEAddUniqueIDObjectSpecifier(AppleEvent *theEvent, AEKeyword keyword, DescType desiredType, SInt32 uid, AEDesc *container);

WB_EXPORT
OSStatus WBAEAddNameObjectSpecifier(AppleEvent *theEvent, AEKeyword keyword, DescType desiredType, CFStringRef name, AEDesc *container);

WB_EXPORT
OSStatus WBAEAddPropertyObjectSpecifier(AppleEvent *theEvent, AEKeyword keyword, DescType desiredType, AEKeyword property, AEDesc *container);

/*!
 @function
 @abstract   Create and Add an AEDesc to an AppleEvent.
 @param      theEvent A pointer to the Apple event to add an attribute to.
 @param      theAEKeyword The keyword specifying the parameter to add.
 If the Apple event already has a parameter with this keyword, the parameter is replaced.
 @param      typeCode The descriptor type for the new descriptor record.
 @param      dataPtr A pointer to the data for the new descriptor record.
 This data is copied into a newly-allocated block of memory for the descriptor record that is created.
 @param      dataSize The length, in bytes, of the data for the new descriptor record.
 @result     A result code.
 */
WB_EXPORT
OSStatus WBAEAddAEDescWithData(AppleEvent *theEvent, AEKeyword theAEKeyword, DescType typeCode, const void * dataPtr, Size dataSize);

/*!
 @function
 @abstract   Add Subjet attribute with value <i>nil</i> and set <i>enumConsidsAndIgnores</i> to ignore all.
 @param      theEvent A pointer to the Apple event to add an attribute to.
 @result     A result code.
 */
WB_EXPORT
OSStatus WBAESetEventSubject(AppleEvent *theEvent, const AEDesc *subject);
WB_EXPORT
OSStatus WBAESetEventConsiderations(AppleEvent *theEvent, UInt32 flags);

WB_INLINE
OSStatus WBAESetReplyPort(AppleEvent *theEvent, mach_port_t port) {
  if (!MACH_PORT_VALID(port)) return paramErr;
  return AEPutAttributePtr(theEvent, keyReplyPortAttr, typeMachPort, &port, sizeof(port));
}
/*!
 @function
 @abstract   Simple wrapper on <i>AEPutParamPtr</i> to add a rtype.
 @param      theEvent A pointer to the Apple event to add an attribute to.
 @param      requestType type you resquest in result.
 @result     A result code.
 */
WB_INLINE
OSStatus WBAESetRequestType(AppleEvent *theEvent, DescType requestType) {
  return WBAEAddParameter(theEvent, keyAERequestedType, typeType, &requestType, sizeof(DescType));
}

#pragma mark -
#pragma mark Send AppleEvents
/**************************** Send AppleEvents ****************************/

/*!
 @abstract   Send an AppleEvent. Check in reply if it contains an error code and return this code.
 @param     pAppleEvent A pointer to the Apple event to be sent.
 @param     theReply On return, contains the result descriptor if function returns noErr or {typeNull, NULL}.

 @result    A result code. If reply contains an error code, returns this code.
 */
WB_EXPORT
OSStatus WBAESendEvent(AppleEvent *pAppleEvent, AESendMode sendMode, SInt64 timeoutms, AppleEvent *theReply);

/*!
 @function
 @abstract   Send an AppleEvent and ignore return value.
 @param      pAppleEvent A pointer to the Apple event to be sent.
 @result     A result code.
 */
WB_EXPORT
OSStatus WBAESendEventNoReply(const AppleEvent* pAppleEvent);

/*!
 @function
 @abstract   Send the provided AppleEvent.
 @discussion Return the direct object as a AEDesc of pAEDescType.
 @param      pAppleEvent ==> The event to be sent.
 @param      pDescType ==> The type of value returned by the event.
 @param      pAEDesc <== The value returned by the event.
 @result     noErr and any other error that can be returned by AESendMessage
 or the handler in the application that gets the event.
 */
WB_EXPORT
OSStatus WBAESendEventReturnAEDesc(AppleEvent *pAppleEvent, const DescType pDescType, AEDesc *pAEDesc);

/*!
 @function
 @abstract   Send the provided AppleEvent.
 @discussion Return the direct object as a AEDescList.
 @param      pAppleEvent The event to be sent.
 @param      pAEDescList The value returned by the event.
 @result     noErr and any other error that can be returned by AESendMessage
 or the handler in the application that gets the event.
 */
WB_EXPORT
OSStatus WBAESendEventReturnAEDescList(AppleEvent* pAppleEvent, AEDescList* pAEDescList);

/*!
 @function
 @abstract   Send the provided AppleEvent.
 @discussion Return the direct object as a AEDescList.
 @param      pAppleEvent The event to be sent.
 @param   desiredType The desired descriptor type for the copied data.<br /><br />
           If the descriptor record specified by the theAEKeyword parameter is not of the desired type,
           AEGetParamPtr attempts to coerce the data to this type. However, if the desired type is typeWildCard,
           no coercion is performed.<br /><br />
           On return, you can determine the actual descriptor type by examining the <i>typeCode</i> parameter.
 @param   typeCode A pointer to a descriptor type. On return, specifies the descriptor type of the data
           pointed to by <i>dataPtr</i>. The returned type is either the same as the type specified by the <i>desiredType</i>
           parameter or, if the desired type was type wildcard, the true type of the descriptor.
           Specify NULL if you do not care about this return value.
 @param   dataPtr A pointer to a buffer, local variable, or other storage location created and disposed of by your application.
           The size in bytes must be at least as large as the value you pass in the <i>maximumSize</i> parameter.
           On return, contains the parameter data. Specify NULL if you do not care about this return value.
 @param   maximumSize The maximum length, in bytes, of the expected Apple event parameter data.
 @param   pActualSize A pointer to a variable of type Size. On return, the length, in bytes, of the
           data for the specified Apple event parameter. If this value is larger than the value you
           passed in the <i>maximumSize</i> parameter, the buffer pointed to by dataPtr was not large enough to contain
           all of the data for the parameter, though AEGetParamPtr does not write beyond the end of the buffer.
           If the buffer was too small, you can resize it and call AEGetParamPtr again.
           Specify NULL if you do not care about this return value.
 @result  noErr and any other error that can be returned by AESendMessage
           or the handler in the application that gets the event.
 */
WB_EXPORT
OSStatus WBAESendEventReturnData(AppleEvent *pAppleEvent, DescType desiredType, DescType* typeCode, void* dataPtr, Size maximumSize, Size *pActualSize);

/*!
 @function
 @abstract   Send the provided AppleEvent.
 @discussion Return the direct object as a Boolean.
 @param      pAppleEvent The event to be sent.
 @param      value On return, contains the Boolean extract from the event response.
 @result     noErr and any other error that can be returned by AESendMessage
              or the handler in the application that gets the event.
 */
WB_EXPORT
OSStatus WBAESendEventReturnBoolean(AppleEvent* pAppleEvent, Boolean* value);


/*!
 @function
 @abstract   Send the provided AppleEvent.
 @discussion Return the direct object as a SInt16.
 @param      pAppleEvent The event to be sent.
 @param      value On return, contains the SInt16 extract from the event response.
 @result     noErr and any other error that can be returned by AESendMessage
 or the handler in the application that gets the event.
 */
WB_EXPORT
OSStatus WBAESendEventReturnSInt16(AppleEvent* pAppleEvent, SInt16* value);

/*!
 @function
 @abstract   Send the provided AppleEvent.
 @discussion Return the direct object as a SInt32.
 @param      pAppleEvent The event to be sent.
 @param      pValue On return, contains the SInt32 extract from the event response.
 @result     noErr and any other error that can be returned by AESendMessage
 or the handler in the application that gets the event.
 */
WB_EXPORT
OSStatus WBAESendEventReturnSInt32(AppleEvent* pAppleEvent, SInt32* pValue);

/*!
 @function
 @abstract   Send the provided AppleEvent.
 @discussion Return the direct object as a UInt32.
 @param      pAppleEvent The event to be sent.
 @param      pValue On return, contains the UInt32 extract from the event response.
 @result     noErr and any other error that can be returned by AESendMessage
 or the handler in the application that gets the event.
 */
WB_EXPORT
OSStatus WBAESendEventReturnUInt32(AppleEvent* pAppleEvent, UInt32* pValue);

WB_EXPORT
OSStatus WBAESendEventReturnSInt64(AppleEvent* pAppleEvent, SInt64* pValue);

WB_EXPORT
OSStatus WBAESendEventReturnUInt64(AppleEvent* pAppleEvent, UInt64* pValue);

/*!
 @function
 @abstract   Send the provided AppleEvent.
 @discussion Return the direct object as a CFDataRef. Caller must release data.
 @param      pAppleEvent The event to be sent.
 @param    resultType The type of result you request. If you don't want a specific type, pass <code>typeWildCard</code>.
 @param      pError On return, contains the CFDataRef extract from the event response. Caller must release data.
 @result     noErr and any other error that can be returned by AESendMessage
 or the handler in the application that gets the event.
 */
WB_EXPORT CF_RETURNS_RETAINED
CFDataRef WBAESendEventReturnCFData(AppleEvent *pAppleEvent, DescType resultType, DescType *actualType, WBAEError pError);

/*!
 @function
 @abstract  Send the provided AppleEvent
 @discussion Return the direct object as a CFStringRef. Caller must release string.
 @param      pAppleEvent The event to be sent.
 @result     noErr and any other error that can be returned by AESendMessage
 or the handler in the application that gets the event.
 */
WB_EXPORT CF_RETURNS_RETAINED
CFStringRef WBAESendEventReturnString(AppleEvent* pAppleEvent, WBAEError pError);

/*!
 @function
 @abstract   Send a simple AppleEvent to an application.
 @discussion This methode is a convenient methode to send an AppleEvent to an Application, without param nor return value.
 It is very usefull to send a simple command action.
 @param      pid The Target Application pid.
 @param      eventClass Class of the event.
 @param      eventType Type of Event.
 @result     A result code.
 */
WB_EXPORT OSStatus WBAESendSimpleEventTo(pid_t pid, AEEventClass eventClass, AEEventID eventType);
WB_EXPORT OSStatus WBAESendSimpleEventToBundle(CFStringRef bundleID, AEEventClass eventClass, AEEventID eventType);
WB_EXPORT OSStatus WBAESendSimpleEventToTarget(const AEDesc *target, AEEventClass eventClass, AEEventID eventType);

#pragma mark -
#pragma mark Retreive AEDesc Data
WB_EXPORT
OSStatus WBAEGetDataFromDescriptor(const AEDesc* pAEDesc,
                                   DescType desiredType, DescType* typeCode,
                                   void* dataPtr, Size maximumSize, Size *pActualSize);

WB_INLINE
OSStatus WBAEGetDataFromAppleEvent(const AppleEvent* anEvent, AEKeyword aKey,
                                   DescType desiredType, DescType* typeCode,
                                   void* dataPtr, Size maximumSize, Size *pActualSize) {
  return AEGetParamPtr(anEvent, aKey, desiredType, typeCode, dataPtr, maximumSize, pActualSize);
}

WB_INLINE
OSStatus WBAEGetNthDataFromDescList(const AEDescList *aList, CFIndex idx,
                                    DescType desiredType, AEKeyword *theAEKeyword, DescType* typeCode,
                                    void* dataPtr, Size maximumSize, Size *pActualSize) {
  return AEGetNthPtr(aList, idx, desiredType, theAEKeyword, typeCode, dataPtr, maximumSize, pActualSize);
}
/* Boolean */
WB_INLINE
OSStatus WBAEGetBooleanFromDescriptor(const AEDesc* pAEDesc, Boolean *value) {
  return WBAEGetDataFromDescriptor(pAEDesc, typeBoolean, NULL, value, sizeof(Boolean), NULL);
}
WB_INLINE
OSStatus WBAEGetBooleanFromAppleEvent(const AppleEvent* anEvent, AEKeyword aKey, Boolean *value) {
  return WBAEGetDataFromAppleEvent(anEvent, aKey, typeBoolean, NULL, value, sizeof(Boolean), NULL);
}
WB_INLINE
OSStatus WBAEGetNthBooleanFromDescList(const AEDescList *aList, CFIndex idx, Boolean *value) {
  return WBAEGetNthDataFromDescList(aList, idx, typeBoolean, NULL, NULL, value, sizeof(Boolean), NULL);
}

/* SInt 16 */
WB_INLINE
OSStatus WBAEGetSInt16FromDescriptor(const AEDesc* pAEDesc, SInt16 *value) {
  return WBAEGetDataFromDescriptor(pAEDesc, typeSInt16, NULL, value, sizeof(SInt16), NULL);
}
WB_INLINE
OSStatus WBAEGetSInt16FromAppleEvent(const AppleEvent* anEvent, AEKeyword aKey, SInt16 *value) {
  return WBAEGetDataFromAppleEvent(anEvent, aKey, typeSInt16, NULL, value, sizeof(SInt16), NULL);
}
WB_INLINE
OSStatus WBAEGetNthSInt16FromDescList(const AEDescList *aList, CFIndex idx, SInt16 *value) {
  return WBAEGetNthDataFromDescList(aList, idx, typeSInt16, NULL, NULL, value, sizeof(SInt16), NULL);
}

/* SInt32 */
WB_INLINE
OSStatus WBAEGetSInt32FromDescriptor(const AEDesc* pAEDesc, SInt32 *value) {
  return WBAEGetDataFromDescriptor(pAEDesc, typeSInt32, NULL, value, sizeof(SInt32), NULL);
}
WB_INLINE
OSStatus WBAEGetSInt32FromAppleEvent(const AppleEvent* anEvent, AEKeyword aKey, SInt32 *value) {
  return WBAEGetDataFromAppleEvent(anEvent, aKey, typeSInt32, NULL, value, sizeof(SInt32), NULL);
}
WB_INLINE
OSStatus WBAEGetNthSInt32FromDescList(const AEDescList *aList, CFIndex idx, SInt32 *value) {
  return WBAEGetNthDataFromDescList(aList, idx, typeSInt32, NULL, NULL, value, sizeof(SInt32), NULL);
}

/* UInt32 */
WB_INLINE
OSStatus WBAEGetUInt32FromDescriptor(const AEDesc* pAEDesc, UInt32 *value) {
  return WBAEGetDataFromDescriptor(pAEDesc, typeUInt32, NULL, value, sizeof(UInt32), NULL);
}
WB_INLINE
OSStatus WBAEGetUInt32FromAppleEvent(const AppleEvent* anEvent, AEKeyword aKey, UInt32 *value) {
  return WBAEGetDataFromAppleEvent(anEvent, aKey, typeUInt32, NULL, value, sizeof(UInt32), NULL);
}
WB_INLINE
OSStatus WBAEGetNthUInt32FromDescList(const AEDescList *aList, CFIndex idx, UInt32 *value) {
  return WBAEGetNthDataFromDescList(aList, idx, typeUInt32, NULL, NULL, value, sizeof(UInt32), NULL);
}

/* SInt64 */
WB_INLINE
OSStatus WBAEGetSInt64FromDescriptor(const AEDesc* pAEDesc, SInt64 *value) {
  return WBAEGetDataFromDescriptor(pAEDesc, typeSInt64, NULL, value, sizeof(SInt64), NULL);
}
WB_INLINE
OSStatus WBAEGetSInt64FromAppleEvent(const AppleEvent* anEvent, AEKeyword aKey, SInt64 *value) {
  return WBAEGetDataFromAppleEvent(anEvent, aKey, typeSInt64, NULL, value, sizeof(SInt64), NULL);
}
WB_INLINE
OSStatus WBAEGetNthSInt64FromDescList(const AEDescList *aList, CFIndex idx, SInt64 *value) {
  return WBAEGetNthDataFromDescList(aList, idx, typeSInt64, NULL, NULL, value, sizeof(SInt64), NULL);
}

/* UInt64 */
WB_INLINE
OSStatus WBAEGetUInt64FromDescriptor(const AEDesc* pAEDesc, UInt64 *value) {
  return WBAEGetDataFromDescriptor(pAEDesc, typeUInt64, NULL, value, sizeof(UInt64), NULL);
}
WB_INLINE
OSStatus WBAEGetUInt64FromAppleEvent(const AppleEvent* anEvent, AEKeyword aKey, UInt64 *value) {
  return WBAEGetDataFromAppleEvent(anEvent, aKey, typeUInt64, NULL, value, sizeof(UInt64), NULL);
}
WB_INLINE
OSStatus WBAEGetNthUInt64FromDescList(const AEDescList *aList, CFIndex idx, UInt64 *value) {
  return WBAEGetNthDataFromDescList(aList, idx, typeUInt64, NULL, NULL, value, sizeof(UInt64), NULL);
}

/* CF Types */
WB_EXPORT CFURLRef WBAECopyFileURLFromDescriptor(const AEDesc* pAEDesc, WBAEError pError);
WB_EXPORT CFURLRef WBAECopyFileURLFromAppleEvent(const AppleEvent* anEvent, AEKeyword aKey, WBAEError pError);
WB_EXPORT CFURLRef WBAECopyNthFileURLFromDescList(const AEDescList *aList, CFIndex idx, WBAEError pError);

WB_EXPORT CFStringRef WBAECopyStringFromDescriptor(const AEDesc* pAEDesc, WBAEError pError);
WB_EXPORT CFStringRef WBAECopyStringFromAppleEvent(const AppleEvent* anEvent, AEKeyword aKey, WBAEError pError);
WB_EXPORT CFStringRef WBAECopyNthStringFromDescList(const AEDescList *aList, CFIndex idx, WBAEError pError);

WB_EXPORT CFDataRef WBAECopyCFDataFromDescriptor(const AEDesc* aDesc, WBAEError pError);
WB_EXPORT CFDataRef WBAECopyCFDataFromAppleEvent(const AppleEvent *anEvent, AEKeyword aKey, DescType aType, DescType *actualType, WBAEError pError);
WB_EXPORT CFDataRef WBAECopyNthCFDataFromDescList(const AEDescList *aList, CFIndex idx, DescType aType, DescType *actualType, WBAEError pError);

#pragma mark -
#pragma mark Misc. AE utility functions
/**************************** Misc. AE utility functions ****************************/
/*! @function
 @abstract   Takes a reply event checks it for any errors that may have been returned.
 @discussion Takes a reply event checks it for any errors that may have been returned
 by the event handler. A simple function, in that it only returns the error
 number. You can often also extract an error string and three other error
 parameters from a reply event.
 @param      pAEReply ==> The reply event to be checked.
 @result     noErr or any other error, depending on what the event handler returns for it's errors.
 */
WB_EXPORT
OSStatus WBAEGetHandlerError(const AppleEvent* pAEReply);

WB_EXPORT
CFStringRef WBAECopyErrorStringFromReply(const AppleEvent *reply, WBAEError pError);

#pragma mark List
/* ... => list of 'AEDesc *' */
WB_EXPORT
OSStatus WBAEDescListCreate(AEDescList *list, ...) WB_REQUIRES_NIL_TERMINATION;
WB_EXPORT
OSStatus WBAEDescListCreateWithArguments(AEDescList *list, va_list args);

/* ... => list of 'AEDesc *' */
WB_EXPORT
OSStatus WBAEDescListAppend(AEDescList *list, ...) WB_REQUIRES_NIL_TERMINATION;
WB_EXPORT
OSStatus WBAEDescListAppendWithArguments(AEDescList *list, va_list args);

WB_EXPORT
OSStatus WBAEDescListGetCount(const AEDescList *list, CFIndex *count);

#pragma mark Record
/* ... => list of 'AEKeyword, const AEDesc *' */
WB_EXPORT
OSStatus WBAERecordCreate(AERecord *list, ...) WB_REQUIRES_NIL_TERMINATION;
WB_EXPORT
OSStatus WBAERecordCreateWithArguments(AERecord *list, va_list args);

/* ... => list of 'AEKeyword, const AEDesc *' */
WB_EXPORT
OSStatus WBAERecordAppend(AERecord *list, ...) WB_REQUIRES_NIL_TERMINATION;
WB_EXPORT
OSStatus WBAERecordAppendWithArguments(AERecord *list, va_list args);

#pragma mark -
#pragma mark Internal

// MARK: Deprecated Functions
WB_EXPORT
OSStatus WBAESetStandardAttributes(AppleEvent *theEvent) WB_DEPRECATED("Add subject and consideration explicitly instead");

WB_EXPORT
OSStatus WBAESendSimpleEvent(OSType targetSign, AEEventClass eventClass, AEEventID eventType) WB_DEPRECATED("Use Bundle Identifier");

WB_EXPORT
OSStatus WBAESendSimpleEventToProcess(ProcessSerialNumber *psn, AEEventClass eventClass, AEEventID eventType) WB_DEPRECATED("Use Process Identifier");

__END_DECLS

#endif /* __WB_AEF_UNCTIONS_H */
