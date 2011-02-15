/*
 *  WBLoginItems.c
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#include <Carbon/Carbon.h>

#include WBHEADER(WBLoginItems.h)
#include WBHEADER(WBAEFunctions.h)

#pragma mark ***** Apple event utilities
enum {
  kSystemEventsCreator = 'sevs'
};

static
long sWBLoginItemTimeout = kAEDefaultTimeout;

long WBLoginItemTimeout(void) {
  return sWBLoginItemTimeout;
}
void WBLoginItemSetTimeout(long timeout) {
  sWBLoginItemTimeout = timeout;
}

CFStringRef const kWBLoginItemURL = CFSTR("URL");		// CFURL
CFStringRef const kWBLoginItemHidden = CFSTR("Hidden"); 	// CFBoolean

// Launches the "System Events" process.
static
OSStatus WBLaunchSystemEvents(ProcessSerialNumber *psnPtr) {
  OSStatus 			err;
  FSRef				appRef;

  check(psnPtr != NULL);

  // Ask Launch Services to find System Events by creator.
  err = LSFindApplicationForInfo(kSystemEventsCreator, NULL, NULL, &appRef, NULL);

  // Launch it!
  if (noErr == err) {
    LSApplicationParameters appParams;

    // Do it the easy way on 10.4 and later.
    memset(&appParams, 0, sizeof(appParams));
    appParams.version = 0;
    appParams.flags = kLSLaunchDefaults;
    appParams.application = &appRef;

    err = LSOpenApplication(&appParams, psnPtr);
  }

  return err;
}

// Finds the "System Events" process or, if it's not running, launches it.
static
OSStatus WBFindSystemEvents(ProcessSerialNumber *psnPtr) {
  OSStatus err;
  Boolean found = false;
  ProcessInfoRec info;

  check(psnPtr != NULL);

  psnPtr->lowLongOfPSN	= kNoProcess;
  psnPtr->highLongOfPSN	= kNoProcess;

  do {
    err = GetNextProcess(psnPtr);
    if (err == noErr) {
      memset(&info, 0, sizeof(info));
      err = GetProcessInformation(psnPtr, &info);
    }
    if (err == noErr) {
      found = (info.processSignature == kSystemEventsCreator);
    }
  } while ( (err == noErr) && !found );

  if (err == procNotFound) {
    err = WBLaunchSystemEvents(psnPtr);
  }
  return err;
}

/////////////////////////////////////////////////////////////////
#pragma mark ***** Constants from Login Items AppleScript Dictionary
enum {
  cLoginItem = 'logi',

  propPath   = 'ppth',
  propHidden = 'hidn'
};

// This routine's input is an AEDescList that contains replies
// from the "properties of every login item" event.  Each element
// of the list is an AERecord with two important properties,
// "path" and "hidden".  This routine creates a CFArray that
// corresponds to this list.  Each element of the CFArray
// contains two properties, kLIAEURL and
// kLIAEHidden, that are derived from the corresponding
// AERecord properties.
//
// On entry, descList must not be NULL
// On entry,  itemsPtr must not be NULL
// On entry, *itemsPtr must be NULL
// On success, *itemsPtr will be a valid CFArray
// On error, *itemsPtr will be NULL
static OSStatus CreateCFArrayFromAEDescList(const AEDescList *descList, CFArrayRef *itemsPtr) {
  OSStatus			err;
  CFMutableArrayRef	result;
  long				itemCount;
  long				itemIndex;
  AEKeyword			junkKeyword;

  check( itemsPtr != NULL);
  check(*itemsPtr == NULL);

  result = NULL;

  // Create a place for the result.
  err = noErr;
  result = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
  if (result == NULL) {
    err = coreFoundationUnknownErr;
  }

  // For each element in the descriptor list...
  if (err == noErr) {
    err = AECountItems(descList, &itemCount);
  }
  if (err == noErr) {
    for (itemIndex = 1; itemIndex <= itemCount; itemIndex++) {
      UInt8 thisPath[1024];
      Size thisPathSize;
      FSRef thisItemRef;
      CFURLRef thisItemURL;
      Boolean thisItemHidden;
      CFDictionaryRef thisItemDict;
      AERecord thisItem = WBAEEmptyDesc();

      thisItemURL = NULL;
      thisItemDict = NULL;

      // Get this element's AERecord.
      err = AEGetNthDesc(descList, itemIndex, typeAERecord, &junkKeyword, &thisItem);

      // Extract the path and create a CFURL.
      if (err == noErr) {
        err = AEGetKeyPtr(&thisItem,
                          propPath, typeUTF8Text,
                          NULL, thisPath,
                          sizeof(thisPath) - 1, 		// to ensure that we can always add null terminator
                          &thisPathSize);
      }
      if (err == noErr) {
        thisPath[thisPathSize] = 0;
        /* resolve symlink */
        err = FSPathMakeRef(thisPath, &thisItemRef, NULL);

        if (err == noErr) {
          thisItemURL = CFURLCreateFromFSRef(NULL, &thisItemRef);
        } else {
          err = noErr;			// swallow error and create an imprecise URL

          thisItemURL = CFURLCreateFromFileSystemRepresentation(NULL,
                                                                thisPath,
                                                                thisPathSize,
                                                                false);
        }
        if (thisItemURL == NULL) {
          err = coreFoundationUnknownErr;
        }
      }

      // Extract the hidden flag.
      if (err == noErr) {
        err = AEGetKeyPtr(&thisItem,
                          propHidden, typeBoolean,
                          NULL, &thisItemHidden,
                          sizeof(thisItemHidden), NULL);

        // Work around <rdar://problem/4052117> by assuming that hidden
        // is false if we can't get its value.
        if (err != noErr) {
          thisItemHidden = false;
          err = noErr;
        }
      }

      // Create the CFDictionary for this item.
      if (err == noErr) {
        CFStringRef keys[2];
        CFTypeRef values[2];

        keys[0] = kWBLoginItemURL;
        keys[1] = kWBLoginItemHidden;

        values[0] = thisItemURL;
        values[1] = (thisItemHidden ? kCFBooleanTrue : kCFBooleanFalse);

        thisItemDict = CFDictionaryCreate(kCFAllocatorDefault,
                                          (const void **) keys, values, 2,
                                          &kCFTypeDictionaryKeyCallBacks,
                                          &kCFTypeDictionaryValueCallBacks);
        if (thisItemDict == NULL) {
          err = coreFoundationUnknownErr;
        }
      }

      // Add it to the results array.
      if (err == noErr) {
        CFArrayAppendValue(result, thisItemDict);
      }

      WBAEDisposeDesc(&thisItem);
      if (thisItemURL) CFRelease(thisItemURL);
      if (thisItemDict) CFRelease(thisItemDict);

      if (err != noErr) {
        break;
      }
    }
  }

  // Clean up.
  if (err != noErr) {
    if (result) CFRelease(result);
    result = NULL;
  }
  *itemsPtr = result;
  check( (err == noErr) == (*itemsPtr != NULL) );

  return err;
}

// Creates an Apple event and sends it to the System Events
// process.  theClass and theEvent are the event class and ID,
// respectively.  If reply is not NULL, the caller gets a copy
// of the reply.  Following reply is a variable number of Apple event
// parameters.  Each AE parameter is made up of two C parameters,
// the first being the AEKeyword, the second being a pointer to
// the AEDesc for that parameter.  This list is terminated by an
// AEKeyword of value 0.
//
// You typically call this as:
//
// err = SendEventToSystemEventsWithParameters(
//     kClass,
//     kEvent,
//     NULL,
//     param1_keyword, param1_desc_ptr,
//     param2_keyword, param2_desc_ptr,
//     0
// );
//
// On entry, reply must be NULL or *reply must be the null AEDesc.
// On success, if reply is not NULL, *reply will be the AE reply
// (that is, not a null desc).
// On error, if reply is not NULL, *reply will be the null AEDesc.
static OSStatus SendEventToSystemEventsWithParameters(AEEventClass theClass, AEEventID theEvent, AppleEvent *reply, ...) WB_REQUIRES_NIL_TERMINATION;
static OSStatus SendEventToSystemEventsWithParameters(AEEventClass theClass, AEEventID theEvent, AppleEvent *reply, ...) {
  OSStatus err;
  ProcessSerialNumber psn;
  AppleEvent event = WBAEEmptyDesc();
  AppleEvent target = WBAEEmptyDesc();
  AppleEvent localReply = WBAEEmptyDesc();

  check( (reply == NULL) || (reply->descriptorType == typeNull) );

  // Create Apple event.
  err = WBFindSystemEvents(&psn);
  if (err == noErr) {
    err = WBAECreateEventWithTargetProcess(&psn, theClass, theEvent, &event);
  }

//  if (noErr == err)
//    err = WBAESetStandardAttributes(&event);

  // Handle varargs parameters.
  if (err == noErr) {
    va_list 		ap;
    AEKeyword		thisKeyword;
    const AEDesc *	thisDesc;

    va_start(ap, reply);
    do {
      thisKeyword = va_arg(ap, AEKeyword);
      if (thisKeyword != 0) {
        thisDesc = va_arg(ap, const AEDesc *);
        check(thisDesc != NULL);
        err = AEPutParamDesc(&event, thisKeyword, thisDesc);
      }
    } while ( (err == noErr) && (thisKeyword != 0) );
    va_end(ap);
  }

  // Send event and get reply.
  if (err == noErr) {
    err = WBAESendEvent(&event, kAEWaitReply, WBLoginItemTimeout(), &localReply);
  }

  // Clean up.
  if ( (reply == NULL) || (err != noErr)) {
    // *reply is already null because of our precondition
    WBAEDisposeDesc(&localReply);
  } else {
    *reply = localReply;
  }
  WBAEDisposeDesc(&event);
  WBAEDisposeDesc(&target);
  check( (reply == NULL) || ((err == noErr) == (reply->descriptorType != typeNull)) );

  return err;
}

#pragma mark -
#pragma mark Logins Item API
// See comment in header.
//
// This routine creates an Apple event that corresponds to the
// AppleScript:
//
//     get properties of every login item
//
// and sends it to System Events.  It then processes the reply
// into a CFArray in the format that's documented in the header
// comments.
CFArrayRef WBLoginItemCopyItems(void) {
  OSStatus err;
  CFArrayRef items = NULL;

  AppleEvent reply = WBAEEmptyDesc();
  AEDescList results = WBAEEmptyDesc();
  AEDesc propertiesOfEveryLoginItem = WBAEEmptyDesc();

  // Build object specifier for "properties of every login item".
  {
    AEDesc	everyLoginItem = WBAEEmptyDesc();

    err = WBAECreateIndexObjectSpecifier(cLoginItem, kAEAll, NULL, &everyLoginItem);
    if (err == noErr) {
      err = WBAECreatePropertyObjectSpecifier(typeProperty, pProperties, &everyLoginItem, &propertiesOfEveryLoginItem);
    }
  }

  // Send event and get reply.
  if (err == noErr) {
    err = SendEventToSystemEventsWithParameters(kAECoreSuite,
                                                kAEGetData,
                                                &reply,
                                                keyDirectObject, &propertiesOfEveryLoginItem, NULL);
  }

  // Process reply.
  if (err == noErr) {
    err = AEGetParamDesc(&reply, keyDirectObject, typeAEList, &results);
  }
  if (err == noErr) {
    err = CreateCFArrayFromAEDescList(&results, &items);
  }

  // Clean up.
  WBAEDisposeDesc(&reply);
  WBAEDisposeDesc(&results);
  WBAEDisposeDesc(&propertiesOfEveryLoginItem);

  check_noerr_string(err, "Error while copying items");
  return items;
}

// See comment in header.
//
// This is implemented as a wrapper around LIAEAddRef.
// I chose to do it this way because an URL can reference a
// file that doesn't except, whereas an FSRef can't, so by
// having the URL routine call the FSRef routine, I naturally
// ensure that the item exists on disk.
extern OSStatus WBLoginItemAppendItemURL(CFURLRef item, Boolean hideIt) {
  OSStatus 	err;
  Boolean success;
  FSRef ref;

  check(item != NULL);

  err = noErr;
  success = CFURLGetFSRef(item, &ref);
  if (!success) {
    // I have no idea what went wrong (thanks CF!).  Normally I'd
    // return coreFoundationUnknownErr here, but in this case I'm
    // going to go out on a limb and say that we have a file not found.
    err = fnfErr;
  }

  if (err == noErr) {
    err = WBLoginItemAppendItemFileRef(&ref, hideIt);
  }

  return err;
}

// See comment in header.
//
// This routine creates an Apple event that corresponds to the
// AppleScript:
//
//     make new login item
// 	       with properties {
//			   path:<path of item>,
//			   hidden:hideIt
//		   }
//         at end
//
// and sends it to System Events.
extern OSStatus WBLoginItemAppendItemFileRef(const FSRef *item, Boolean hideIt) {
  check(item != NULL);

  OSStatus err;
  AERecord endLoc = WBAEEmptyDesc();
  AEDesc newLoginItem = WBAEEmptyDesc();
  AERecord properties = WBAEEmptyDesc();

  static const DescType cLoginItemLocal = cLoginItem;

  // Create "new login item" parameter.
  err = AECreateDesc(typeType, &cLoginItemLocal, sizeof(cLoginItemLocal), &newLoginItem);

  // Create "with properties" parameter.
  if (err == noErr) {
    char		path[1024];
    AEDesc		pathDesc = WBAEEmptyDesc();

    err = AECreateList(NULL, 0, true, &properties);
    if (err == noErr) {
      err = FSRefMakePath(item, (UInt8 *) path, (UInt32)sizeof(path));
    }

    // System Events complains if you pass it typeUTF8Text directly, so
    // we do the conversion from typeUTF8Text to typeUnicodeText on our
    // side of the world.
    if (err == noErr) {
      err = AECoercePtr(typeUTF8Text, path, (Size) strlen(path), typeUnicodeText, &pathDesc);
    }
    if (err == noErr) {
      err = AEPutKeyDesc(&properties, propPath, &pathDesc);
    }
    if (err == noErr) {
      err = AEPutKeyPtr(&properties, propHidden, typeBoolean, &hideIt, sizeof(hideIt));
    }

    WBAEDisposeDesc(&pathDesc);
  }

  // Create "at end" parameter.
  if (err == noErr) {
    AERecord end = WBAEEmptyDesc();
    static const DescType kAEEndLocal = kAEEnd;

    err = AECreateList(NULL, 0, true, &end);
    if (err == noErr) {
      err = AEPutKeyPtr(&end, keyAEObject, typeNull, NULL, 0);
    }
    if (err == noErr) {
      err = AEPutKeyPtr(&end, keyAEPosition, typeEnumerated, &kAEEndLocal, (Size) sizeof(kAEEndLocal));
    }
    if (err == noErr) {
      err = AECoerceDesc(&end, cInsertionLoc, &endLoc);
    }

    WBAEDisposeDesc(&end);
  }

  // Send the event.
  if (err == noErr) {
    err = SendEventToSystemEventsWithParameters(kAECoreSuite,
                                                kAECreateElement,
                                                NULL,
                                                keyAEObjectClass, 	&newLoginItem,
                                                keyAEPropData, 		&properties,
                                                keyAEInsertHere, 	&endLoc,
                                                NULL);
  }

  // Clean up.
  WBAEDisposeDesc(&newLoginItem);
  WBAEDisposeDesc(&properties);
  WBAEDisposeDesc(&endLoc);

  return err;
}

// See comment in header.
//
// This routine creates an Apple event that corresponds to the
// AppleScript:
//
//     delete login item itemIndex
//
// and sends it to System Events.
extern OSStatus WBLoginItemRemoveItemAtIndex(CFIndex itemIndex) {
  OSStatus	err;
  AEDesc loginItemAtIndex = WBAEEmptyDesc();

  check(itemIndex >= 0);

  // Build object specifier for "login item X".
  // AppleScript is one-based, CF is zero-based
  err = WBAECreateIndexObjectSpecifier(cLoginItem, (UInt32)itemIndex + 1, NULL, &loginItemAtIndex);

  // Send the event.
  if (err == noErr) {
    err = SendEventToSystemEventsWithParameters(kAECoreSuite,
                                                kAEDelete,
                                                NULL,
                                                keyDirectObject, &loginItemAtIndex,
                                                NULL);
  }

  // Clean up.
  WBAEDisposeDesc(&loginItemAtIndex);

  return err;
}

#pragma mark Leopard Way
//LSSharedFileListRef
