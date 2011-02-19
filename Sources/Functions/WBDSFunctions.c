/*
 *  WBDSFunctions.c
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#include WBHEADER(WBDSFunctions.h)

#include <pwd.h>
#include <grp.h>

CFStringRef WBDSCopyUserNameForUID(uid_t uid) {
  CFStringRef name = NULL;
  struct passwd *user = getpwuid(uid);
  if (user && user->pw_name) {
    name = CFStringCreateWithCString(kCFAllocatorDefault, user->pw_name, kCFStringEncodingUTF8);
  }
  return name;
}
CFStringRef WBDSCopyGroupNameForGID(gid_t gid) {
  CFStringRef name = NULL;
  struct group *gpr = getgrgid(gid);
  if (gpr && gpr->gr_name) {
    name = CFStringCreateWithCString(kCFAllocatorDefault, gpr->gr_name, kCFStringEncodingUTF8);
  }
  return name;
}

uid_t WBDSGetUIDForUserName(CFStringRef user) {
  uid_t uid = -1;
  char stack[256];
  const char *name = CFStringGetCStringPtr(user, kCFStringEncodingUTF8);
  if (!name && CFStringGetCString(user, stack, 256, kCFStringEncodingUTF8)) {
    name = stack;
  }
  if (name) {
    struct passwd *passwd = getpwnam(name);
    if (passwd) {
      uid = passwd->pw_uid;
    }
  }
  return uid;
}
gid_t WBDSGetGIDForGroupName(CFStringRef group) {
  gid_t gid = -1;
  char stack[256];
  const char *name = CFStringGetCStringPtr(group, kCFStringEncodingUTF8);
  if (!name && CFStringGetCString(group, stack, 256, kCFStringEncodingUTF8)) {
    name = stack;
  }
  if (name) {
    struct group *gpr = getgrnam(name);
    if (gpr) {
      gid = gpr->gr_gid;
    }
  }
  return gid;
}
/* Null Context Data */
#if __LP64__
#define NULL_CD 0
#else
#define NULL_CD NULL
#endif

static
void _WBDSListUsersRecords(tDirReference gDirRef, const tDirNodeReference nodeRef, WBDSUserCallBack callback, void *ctxt) {
  long dirStatus = eDSNoErr;
  tDataNodePtr rtype = dsDataNodeAllocateString(gDirRef, kDSStdRecordTypeUsers);
  tDataBufferPtr dataBuffer = dsDataBufferAllocate( gDirRef, 8 * 1024 ); // allocate  a 8k buffer
  if (dataBuffer) {
    tDataList recNames;
    tDataList recTypes;
    tDataList attrTypes;
    UInt32 recCount = 0;
    tContextData context = NULL_CD;
    // For readability, the sample code does not check dirStatus  after
    // each call, but
    // your code should.
    dirStatus = dsBuildListFromStringsAlloc (gDirRef, &recNames,  kDSRecordsAll, NULL );
    dirStatus = dsBuildListFromStringsAlloc (gDirRef, &recTypes,  kDSStdRecordTypeUsers, NULL );
    dirStatus = dsBuildListFromStringsAlloc (gDirRef, &attrTypes,  kDSNAttrRecordName, NULL);
    do {
      UInt32 i = 0;
      dirStatus = dsGetRecordList( nodeRef, dataBuffer, &recNames,  eDSExact,  &recTypes, &attrTypes, false, &recCount, &context  );
      for ( i = 1; i <= recCount; i++ ) {
        tRecordEntryPtr pRecEntry = NULL;
        tAttributeListRef attrListRef = 0;
        /* For each record */
        dirStatus = dsGetRecordEntry( nodeRef, dataBuffer, i, &attrListRef, &pRecEntry);
        if (eDSNoErr == dirStatus) {
          if (pRecEntry->fRecordAttributeCount) {
            tAttributeValueListRef valueRef = 0;
            tAttributeEntryPtr pAttrEntry = NULL;
            /* First attribute */
            dirStatus = dsGetAttributeEntry(nodeRef, dataBuffer,  attrListRef, 1, &valueRef, &pAttrEntry);
            if (eDSNoErr == dirStatus) {
              if (pAttrEntry->fAttributeValueCount) {
                tAttributeValueEntryPtr pValueEntry = NULL;
                /* First value */
                dirStatus = dsGetAttributeValue(nodeRef, dataBuffer, 1, valueRef, &pValueEntry);
                if (eDSNoErr == dirStatus) {
                  tRecordReference record = 0;
                  if (eDSNoErr == dsOpenRecord(nodeRef, rtype, &pValueEntry->fAttributeValueData, &record)) {
                    callback(gDirRef, &pValueEntry->fAttributeValueData, record, ctxt);
                    dsCloseRecord(record);
                  }
                  dsDeallocAttributeValueEntry(gDirRef, pValueEntry);
                }
              }
              dirStatus = dsCloseAttributeValueList(valueRef);
              valueRef = 0;
              dirStatus = dsDeallocAttributeEntry(gDirRef,  pAttrEntry);
              pAttrEntry = NULL;
            }
          }
          dirStatus = dsCloseAttributeList(attrListRef);
          attrListRef = 0;
          dirStatus = dsDeallocRecordEntry(gDirRef, pRecEntry);
          pRecEntry = NULL;
        }
      }
    } while (context != NULL_CD); // Loop until all data has been  obtained.
                               // Call dsDataListDeallocate to deallocate recNames, recTypes,  and
                               // attrTypes.
                               // Deallocate dataBuffer by calling dsDataBufferDeAllocate.
    dsDataListDeallocate ( gDirRef, &recNames );
    dsDataListDeallocate ( gDirRef, &recTypes );
    dsDataListDeallocate ( gDirRef, &attrTypes );
    dsDataBufferDeAllocate ( gDirRef, dataBuffer );
    dsDataNodeDeAllocate(gDirRef, rtype);
    dataBuffer = NULL;
  }
}

static
tDirStatus _WBDSGetLocalUsers(tDirReference gDirRef, WBDSUserCallBack callback, void *ctxt) {
  UInt32 count = 0;
  tDataBufferPtr dataBuffer = dsDataBufferAllocate(gDirRef, 2 * 1024); // allocate  a 2k buffer
  tDirStatus dirStatus = dsFindDirNodes(gDirRef, dataBuffer, NULL, eDSLocalNodeNames /*eDSLocalHostedNodes*/, &count, NULL);
  if (dirStatus == eDSNoErr) {
    tDataListPtr nodeName = NULL;
    dirStatus = dsGetDirNodeName(gDirRef, dataBuffer, 1, &nodeName);
    if (dirStatus == eDSNoErr) {
      tDirNodeReference node;
      /* Open node */
      dirStatus = dsOpenDirNode(gDirRef, nodeName, &node);
      if (dirStatus == eDSNoErr) {
        _WBDSListUsersRecords(gDirRef, node, callback, ctxt);
        dsCloseDirNode(node);
      }
      dsDataListDeallocate(gDirRef, nodeName);
    }
  }
  dsDataBufferDeallocate (gDirRef, dataBuffer);

  return dirStatus;
}

#pragma mark -
tDirStatus WBDSGetLocalUsers(WBDSUserCallBack callback, void *ctxt) {
  tDirReference gDirRef;
  tDirStatus dirStatus = dsOpenDirService(&gDirRef);
  if (dirStatus == eDSNoErr) {
    dirStatus = _WBDSGetLocalUsers(gDirRef, callback, ctxt);
    dsCloseDirService(gDirRef);
  }
  return dirStatus;
}

#pragma mark -
#pragma mark High Level Functions
typedef struct _WBDSUserCtxt {
  tDataNodePtr puid;
  CFMutableArrayRef users;
  CFMutableArrayRef nodes;
  CFMutableArrayRef properties;
} WBDSUserCtxt;

static
void _WBDSVisibleUserCallBack(tDirReference gDirRef, tDataNodePtr name, tRecordReference record, void *ctxt) {
  tAttributeValueEntryPtr vuid;
  WBDSUserCtxt *context = (WBDSUserCtxt *)ctxt;

  tDirStatus err = dsGetRecordAttributeValueByIndex(record, context->puid, 1, &vuid);
  if (eDSNoErr == err) {
    long uid = strtol(vuid->fAttributeValueData.fBufferData, NULL, 10);
    if (uid > 500) {
      CFMutableDictionaryRef user = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

      CFIndex count = CFArrayGetCount(context->properties);
      for (CFIndex idx = 0; idx < count; idx++) {
        tAttributeValueEntryPtr value;
        tDataNodePtr property = (tDataNodePtr)CFArrayGetValueAtIndex(context->nodes, idx);
        if (property) {
          err = dsGetRecordAttributeValueByIndex(record, property, 1, &value);
          if (eDSNoErr == err) {
            CFStringRef key = CFArrayGetValueAtIndex(context->properties, idx);
            CFStringRef str = CFStringCreateWithBytes(kCFAllocatorDefault, (UInt8 *)value->fAttributeValueData.fBufferData, dsDataNodeGetLength(&value->fAttributeValueData), kCFStringEncodingUTF8, FALSE);
            CFDictionarySetValue(user, key, str);
            CFRelease(str);
            dsDeallocAttributeValueEntry(gDirRef, value);
          }
        }
      }

      CFArrayAppendValue(context->users, user);
      CFRelease(user);
    }
    dsDeallocAttributeValueEntry(gDirRef, vuid);
  }
}

tDirStatus WBDSGetVisibleUsers(CFArrayRef *users, ...) {
  check(users);

  tDirReference gDirRef;
  tDirStatus dirStatus = dsOpenDirService(&gDirRef);
  if (dirStatus == eDSNoErr) {
    WBDSUserCtxt ctxt;
    ctxt.puid = dsDataNodeAllocateString(gDirRef, kDS1AttrUniqueID);
    ctxt.users = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
    ctxt.nodes = CFArrayCreateMutable(kCFAllocatorDefault, 0, NULL);
    ctxt.properties = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);

    va_list args;
    va_start(args, users);

    const char *property = NULL;
    while ((property = va_arg(args, char *))) {
      CFStringRef str = CFStringCreateWithCString(kCFAllocatorDefault, property, kCFStringEncodingUTF8);
      if (str) {
        tDataNodePtr node = dsDataNodeAllocateString(gDirRef, property);
        if (node) {
          CFArrayAppendValue(ctxt.nodes, node);
          CFArrayAppendValue(ctxt.properties, str);
        }
        CFRelease(str);
      }
    }

    va_end(args);

    dirStatus = _WBDSGetLocalUsers(gDirRef, _WBDSVisibleUserCallBack, &ctxt);

    if (noErr == dirStatus) {
      *users = ctxt.users;
    } else {
      *users = NULL;
      CFRelease(ctxt.users);
    }
    /* Release uid data node */
    dsDataNodeDeallocate(gDirRef, ctxt.puid);
    /* Release data nodes */
    CFIndex count = CFArrayGetCount(ctxt.nodes);
    for (CFIndex idx = 0; idx < count; idx++) {
      tDataNodePtr node = (tDataNodePtr)CFArrayGetValueAtIndex(ctxt.nodes, idx);
      if (node)
        dsDataNodeDeallocate(gDirRef, node);
    }
    CFRelease(ctxt.nodes);
    CFRelease(ctxt.properties);

    dsCloseDirService(gDirRef);
  }
  return dirStatus;
}
