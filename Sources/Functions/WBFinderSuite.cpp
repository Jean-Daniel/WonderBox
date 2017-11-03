/*
 *  WBFinderSuite.c
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#include <WonderBox/WBFinderSuite.h>
#include <WonderBox/WBAEFunctions.h>

CFStringRef const kWBAEFinderBundleIdentifier = CFSTR("com.apple.finder");

OSStatus WBAEFinderGetSelection(AEDescList *items) {
  OSStatus err = noErr;
  AEDesc theEvent = WBAEEmptyDesc();

  err = WBAECreateEventWithTargetBundleID(kWBAEFinderBundleIdentifier, kAECoreSuite, kAEGetData, &theEvent);
  if (noErr == err)
    err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeAEList, pSelection, NULL);

  //  if (noErr == err)
  //    err = WBAESetStandardAttributes(&theEvent);

  if (noErr == err)
    err = WBAESendEventReturnAEDescList(&theEvent, items);

  WBAEDisposeDesc(&theEvent);
  return err;
}

CFArrayRef WBAEFinderCopySelection(void) {
  wb::AEDesc selection;
  OSStatus err = WBAEFinderGetSelection(&selection);
  if (noErr != err)
    return nullptr;

  long numDocs;
  err = AECountItems(&selection, &numDocs);
  if (noErr != err)
    return nullptr;

  if (numDocs == 0)
    return CFArrayCreate(kCFAllocatorDefault, nullptr, 0, &kCFTypeArrayCallBacks);

  CFMutableArrayRef urls = CFArrayCreateMutable(kCFAllocatorDefault, numDocs, &kCFTypeArrayCallBacks);

  for (long idx = 1; idx <= numDocs; ++idx) {
    wb::AEDesc tAEDesc;
    AEKeyword keyword;
    err = AEGetNthDesc(&selection, idx, typeWildCard, &keyword, &tAEDesc);
    if (noErr != err)
      continue;

      // Si c'est un objet, on le transforme en FSRef.
      if (typeObjectSpecifier == tAEDesc.descriptorType) {
        spx::unique_cfptr<CFURLRef> url(WBAEFinderCreateFileURLFromObject(&tAEDesc));
        if (url)
          CFArrayAppendValue(urls, url.get());
      } else {
        // Si ce n'est pas une FSRef, on coerce.
        spx::unique_cfptr<CFURLRef> url(WBAECopyFileURLFromDescriptor(&tAEDesc, &err));
        if (url) {
          CFArrayAppendValue(urls, url.get());
        }
      }
  }

  return urls;
}

CFURLRef WBAEFinderCreateFileURLFromObject(const AEDesc* pAEDesc) {
  // the descriptor pointer, alias handle is required
  if (!pAEDesc)
    return nullptr;

  if (typeObjectSpecifier != pAEDesc->descriptorType)
    return nullptr;  // this has to be an object specifier

  wb::AppleEvent theEvent;
  OSStatus err = WBAECreateEventWithTargetBundleID(kWBAEFinderBundleIdentifier, kAECoreSuite, kAEGetData, &theEvent);
  if (noErr == err)
    err = AEPutParamDesc(&theEvent, keyDirectObject, pAEDesc);

  if (noErr == err)
    err = WBAESetRequestType(&theEvent, typeFileURL);

  //  if (noErr == err)
  //    err = WBAESetStandardAttributes(&theEvent);

  if (noErr == err) {
    wb::AEDesc tAEDesc;
    err = WBAESendEventReturnAEDesc(&theEvent, typeFileURL, &tAEDesc);
    if (noErr == err)
      return WBAEFinderCreateFileURLFromObject(&tAEDesc);
  }
  return nullptr;
}

#pragma mark Current Folder
CFURLRef WBAEFinderCopyCurrentFolderURL(void) {
  wb::AppleEvent theEvent;
  OSStatus err = WBAECreateEventWithTargetBundleID(kWBAEFinderBundleIdentifier, kAECoreSuite, kAEGetData, &theEvent);
  if (noErr == err)
    err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, 'cfol', pInsertionLoc, NULL);

  //  if (noErr == err)
  //    err = WBAESetStandardAttributes(&theEvent);

  wb::AEDesc result;
  if (noErr == err)
    err = WBAESendEventReturnAEDesc(&theEvent, typeObjectSpecifier, &result);

  if (noErr == err)
    return WBAEFinderCreateFileURLFromObject(&result);

  return nullptr;
}

#pragma mark Sync
OSStatus WBAEFinderSyncItem(const AEDesc *item) {
  AppleEvent aevt = WBAEEmptyDesc();
  OSStatus err = WBAECreateEventWithTargetBundleID(kWBAEFinderBundleIdentifier,
                                                   'fndr', /* kAEFinderSuite, */
                                                   'fupd', /* kAESync, */
                                                   &aevt);
  spx_require_noerr(err, dispose);

  err = WBAEAddAEDesc(&aevt, keyDirectObject, item);
  spx_require_noerr(err, dispose);

  //  err = WBAESetStandardAttributes(&aevt);
  //  spx_require_noerr(err, dispose);

  err = WBAESendEventNoReply(&aevt);
  spx_require_noerr(err, dispose);

dispose:
  WBAEDisposeDesc(&aevt);
  return err;
}

OSStatus WBAEFinderSyncItemAtURL(CFURLRef url) {
  assert(url);
  AEDesc item = WBAEEmptyDesc();
  OSStatus err = WBAECreateDescFromURL(url, &item);
  spx_require_noerr(err, dispose);

  err = WBAEFinderSyncItem(&item);
  spx_require_noerr(err, dispose);

dispose:
  WBAEDisposeDesc(&item);
  return err;
}

#pragma mark Reveal Item
OSStatus WBAEFinderRevealItem(const AEDesc *item, Boolean activate) {
  OSStatus err = noErr;
  AppleEvent aevt = WBAEEmptyDesc();

  if (activate) {
    err = WBAESendSimpleEventToBundle(kWBAEFinderBundleIdentifier, kAEMiscStandards, kAEActivate);
    spx_require_noerr(err, dispose);
  }

  err = WBAECreateEventWithTargetBundleID(kWBAEFinderBundleIdentifier, kAEMiscStandards, kAEMakeObjectsVisible, &aevt);
  spx_require_noerr(err, dispose);

  err = WBAEAddAEDesc(&aevt, keyDirectObject, item);
  spx_require_noerr(err, dispose);

  //  err = WBAESetStandardAttributes(&aevt);
  //  spx_require_noerr(err, dispose);

  err = WBAESendEventNoReply(&aevt);
  spx_require_noerr(err, dispose);

dispose:
  WBAEDisposeDesc(&aevt);
  return err;
}

OSStatus WBAEFinderRevealItemAtURL(CFURLRef url, Boolean activate) {
  assert(url);
  AEDesc item = WBAEEmptyDesc();
  OSStatus err = WBAECreateDescFromURL(url, &item);
  spx_require_noerr(err, dispose);

  err = WBAEFinderRevealItem(&item, activate);
  spx_require_noerr(err, dispose);

dispose:
  WBAEDisposeDesc(&item);
  return err;
}

#if 0

// MARK: Legacy Suite

OSStatus WBAEFinderGetObjectAsAlias(const AEDesc* pAEDesc, AliasHandle *alias) {
  AppleEvent theEvent = WBAEEmptyDesc();  // If you always init AEDescs, it's always safe to dispose of them.
  OSStatus err = noErr;

  // the descriptor pointer, alias handle is required
  if (NULL == pAEDesc || NULL == alias)
    return paramErr;

  if (typeObjectSpecifier != pAEDesc->descriptorType)
    return paramErr;  // this has to be an object specifier

  err = WBAECreateEventWithTargetBundleID(kWBAEFinderBundleIdentifier, kAECoreSuite, kAEGetData, &theEvent);

  if (noErr == err) {
    err = AEPutParamDesc(&theEvent, keyDirectObject, pAEDesc);
  }
  if (noErr == err) {
    err = WBAESetRequestType(&theEvent, typeAlias);
  }
  //  if (noErr == err)
  //    err = WBAESetStandardAttributes(&theEvent);

  if (noErr == err) {
    AEDesc tAEDesc;
    err = WBAESendEventReturnAEDesc(&theEvent, typeAlias, &tAEDesc);
    if (noErr == err) {
      err = WBAECopyAliasFromDescriptor(&tAEDesc, alias);
      WBAEDisposeDesc(&tAEDesc);  // always dispose of AEDescs when you are finished with them
    }
  }
  WBAEDisposeDesc(&theEvent);  // always dispose of AEDescs when you are finished with them
  return err;
}

OSStatus WBAEFinderGetObjectAsFSRef(const AEDesc* pAEDesc, FSRef *file) {
  AppleEvent theEvent = WBAEEmptyDesc();  // If you always init AEDescs, it's always safe to dispose of them.
  OSStatus err = noErr;

  // the descriptor pointer, alias handle is required
  if (NULL == pAEDesc || NULL == file)
    return paramErr;

  if (typeObjectSpecifier != pAEDesc->descriptorType)
    return paramErr;  // this has to be an object specifier

  err = WBAECreateEventWithTargetBundleID(kWBAEFinderBundleIdentifier, kAECoreSuite, kAEGetData, &theEvent);

  if (noErr == err)
    err = WBAEAddAEDesc(&theEvent, keyDirectObject, pAEDesc);

  if (noErr == err)
    err = WBAESetRequestType(&theEvent, typeAlias);

  //  if (noErr == err)
  //    err = WBAESetStandardAttributes(&theEvent);

  if (noErr == err) {
    AEDesc tAEDesc;
    err = WBAESendEventReturnAEDesc(&theEvent, typeAlias, &tAEDesc);
    if (noErr == err) {
      // Si ce n'est pas une FSRef, on coerce.
      if (typeAlias != tAEDesc.descriptorType)
        err = AECoerceDesc(&tAEDesc, typeAlias, &tAEDesc);

      if (noErr == err)
        err = WBAEGetFSRefFromDescriptor(&tAEDesc, file);
    }
    WBAEDisposeDesc(&tAEDesc);  // always dispose of AEDescs when you are finished with them
  }
  WBAEDisposeDesc(&theEvent);  // always dispose of AEDescs when you are finished with them
  return err;
}

//*******************************************************************************
// This routine creates a new handle and puts the contents of the desc
// in that handle.  Carbon's opaque AEDesc's means that we need this
// functionality a lot.
static OSStatus WBAECopyHandleFromDescriptor(const AEDesc* pDesc, DescType desiredType, Handle* descData) {
  if (!pDesc || !descData)
    return paramErr;

  wb::AEDesc stackdesc;
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

static OSStatus WBAECopyHandleFromAppleEvent(const AppleEvent* anEvent, AEKeyword aKey, DescType desiredType, Handle *aHandle) {
  if (!anEvent || !aHandle)
    return paramErr;

  wb::AEDesc desc;
  OSStatus err = AEGetParamDesc(anEvent, aKey, desiredType, &desc);
  if (noErr == err)
    err = WBAECopyHandleFromDescriptor(anEvent, desiredType, aHandle);
  return err;
}

static OSStatus WBAECopyNthHandleFromDescList(const AEDescList *aList, CFIndex idx, DescType aType, Handle *pHandle) {
  if (!aList || !pHandle)
    return paramErr;

  wb::AEDesc nthItem;
  OSStatus err = AEGetNthDesc(aList, idx, aType, NULL, &nthItem);
  if (noErr == err)
    err = WBAECopyHandleFromDescriptor(&nthItem, aType, pHandle);
  return err;
}

// MARK: -
OSStatus WBAECreateDescFromAlias(AliasHandle alias, AEDesc *desc) {
  if (!alias || !desc) return paramErr;
  return AECreateDesc(typeAlias, *alias, GetAliasSize(alias), desc);
}

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

// MARK: FSRef
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

// MARK: Alias
OSStatus WBAECopyAliasFromDescriptor(const AEDesc* pAEDesc, AliasHandle *pAlias) {
  return WBAECopyHandleFromDescriptor(pAEDesc, typeAlias, (Handle *)pAlias);
}
OSStatus WBAECopyAliasFromAppleEvent(const AppleEvent* anEvent, AEKeyword aKey, AliasHandle *pAlias) {
  return WBAECopyHandleFromAppleEvent(anEvent, aKey, typeAlias, (Handle *)pAlias);
}
OSStatus WBAECopyNthAliasFromDescList(const AEDescList *aList, CFIndex idx, AliasHandle *pAlias) {
  return WBAECopyNthHandleFromDescList(aList, idx, typeAlias, (Handle *)pAlias);
}

OSStatus WBAEAddAlias(AppleEvent *theEvent, AEKeyword keyword, AliasHandle alias) {
  if (alias) {
    return WBAEAddParameter(theEvent, keyword, typeAlias, *alias, GetAliasSize(alias));
  } else {
    return WBAEAddParameter(theEvent, keyword, typeNull, NULL, 0);
  }
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

#endif

