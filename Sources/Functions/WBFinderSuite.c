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

OSStatus WBAEFinderSelectionToFSRefs(AEDescList *items, FSRef *selection, CFIndex maxCount, CFIndex *itemsCount) {
  OSStatus err = noErr;
  long numDocs;
  CFIndex count = 0;
  AEKeyword keyword = 0;

  err = AECountItems(items, &numDocs);

  if (noErr == err) {
    for (long idx = 1; (idx <= numDocs) && (count < maxCount); idx++) {
      AEDesc tAEDesc = WBAEEmptyDesc();

      err = AEGetNthDesc(items, idx, typeWildCard, &keyword, &tAEDesc);
      if (noErr == err) {
        // Si c'est un objet, on le transforme en FSRef.
        if (typeObjectSpecifier == tAEDesc.descriptorType) {
          err = WBAEFinderGetObjectAsFSRef(&tAEDesc, &selection[count]);
        } else {
          // Si ce n'est pas une FSRef, on coerce.
          if (typeAlias != tAEDesc.descriptorType)
            err = AECoerceDesc(&tAEDesc, typeAlias, &tAEDesc);

          if (noErr == err)
            err = WBAEGetFSRefFromDescriptor(&tAEDesc, &selection[count]);
        }
        if (noErr == err)
          count++;
        WBAEDisposeDesc(&tAEDesc);
      }
    } // End for
  }
  *itemsCount = count;
  return err;
} //end WBAEFinderSelectionToFSRefs

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

#pragma mark Current Folder
OSStatus WBAEFinderGetCurrentFolder(FSRef *folder) {
  OSStatus err = noErr;
  AEDesc theEvent = WBAEEmptyDesc();
  AEDesc result = WBAEEmptyDesc();

  err = WBAECreateEventWithTargetBundleID(kWBAEFinderBundleIdentifier, kAECoreSuite, kAEGetData, &theEvent);
  if (noErr == err)
    err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, 'cfol', pInsertionLoc, NULL);

  //  if (noErr == err)
  //    err = WBAESetStandardAttributes(&theEvent);

  if (noErr == err)
    err = WBAESendEventReturnAEDesc(&theEvent, typeObjectSpecifier, &result);

  if (noErr == err)
    err = WBAEFinderGetObjectAsFSRef(&result, folder);

  WBAEDisposeDesc(&theEvent);
  WBAEDisposeDesc(&result);
  return err;
}

CFURLRef WBAEFinderCopyCurrentFolderURL(void) {
  FSRef folder;
  CFURLRef url = NULL;
  if (noErr == WBAEFinderGetCurrentFolder(&folder)) {
    url = CFURLCreateFromFSRef(kCFAllocatorDefault, &folder);
  }
  return url;
}

CFStringRef WBAEFinderCopyCurrentFolderPath(void) {
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

OSStatus WBAEFinderSyncFSRef(const FSRef *aRef) {
  assert(aRef);
  AEDesc item = WBAEEmptyDesc();
  OSStatus err = WBAECreateDescFromFSRef(aRef, &item);
  spx_require_noerr(err, dispose);

  err = WBAEFinderSyncItem(&item);
  spx_require_noerr(err, dispose);

dispose:
  WBAEDisposeDesc(&item);
  return err;
}

OSStatus WBAEFinderSyncItemAtURL(CFURLRef url) {
  assert(url);
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

OSStatus WBAEFinderRevealFSRef(const FSRef *aRef, Boolean activate) {
  assert(aRef);
  AEDesc item = WBAEEmptyDesc();
  OSStatus err = WBAECreateDescFromFSRef(aRef, &item);
  spx_require_noerr(err, dispose);

  err = WBAEFinderRevealItem(&item, activate);
  spx_require_noerr(err, dispose);

dispose:
  WBAEDisposeDesc(&item);
  return err;
}

OSStatus WBAEFinderRevealItemAtURL(CFURLRef url, Boolean activate) {
  assert(url);
  FSRef ref;
  OSStatus err = paramErr;
  if (CFURLGetFSRef(url, &ref)) {
    err = WBAEFinderRevealFSRef(&ref, activate);
  }
  return err;
}
