/*
 *  WBDSFunctions.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#if !defined(__WB_DS_FUNCTIONS_H)
#define __WB_DS_FUNCTIONS_H 1

#import WBHEADER(WBBase.h)

WB_EXPORT
CFStringRef WBDSCopyUserNameForUID(uid_t uid);
WB_EXPORT
CFStringRef WBDSCopyGroupNameForGID(gid_t gid);

WB_EXPORT
uid_t WBDSGetUIDForUserName(CFStringRef user);
WB_EXPORT
gid_t WBDSGetGIDForGroupName(CFStringRef group);

#include <DirectoryService/DirectoryService.h>

typedef void (*WBDSUserCallBack)(tDirReference gDirRef, tDataNodePtr name, tRecordReference record, void *ctxt);

WB_EXPORT
tDirStatus WBDSGetLocalUsers(WBDSUserCallBack callback, void *ctxt);

WB_EXPORT
tDirStatus WBDSGetVisibleUsers(CFArrayRef *users, ...) WB_REQUIRES_NIL_TERMINATION;

/* Why this function does not follow name convention ?? */
WB_INLINE
tDirStatus dsDataBufferDeallocate(tDirReference	inDirReference, tDataBufferPtr inDataBufferPtr) {
  return dsDataBufferDeAllocate(inDirReference, inDataBufferPtr);
}
WB_INLINE
tDirStatus dsDataNodeDeallocate(tDirReference	inDirReference, tDataNodePtr inDataNodePtr) {
  return dsDataNodeDeAllocate(inDirReference, inDataNodePtr);
}

#endif /* __WB_DS_FUNCTIONS_H */
