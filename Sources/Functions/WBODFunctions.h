/*
 *  WBODFunctions.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2012 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#if !defined(__WB_OD_FUNCTIONS_H)
#define __WB_OD_FUNCTIONS_H 1

#import WBHEADER(WBBase.h)

#import <OpenDirectory/OpenDirectory.h>

WB_EXPORT
CFStringRef WBODCopyUserNameForUID(uid_t uid);
WB_EXPORT
CFStringRef WBODCopyGroupNameForGID(gid_t gid);

WB_EXPORT
uid_t WBODGetUIDForUserName(CFStringRef user);
WB_EXPORT
gid_t WBODGetGIDForGroupName(CFStringRef group);

WB_EXPORT
CFTypeRef WBODRecordCopyFirstValue(ODRecordRef record, ODAttributeType attribute);
WB_EXPORT
CFDictionaryRef WBODRecordCopyAttributes(ODRecordRef record, CFArrayRef attributes);

WB_EXPORT
CFArrayRef WBODCopyVisibleUsersAttributes(ODAttributeType attribute, ...) WB_REQUIRES_NIL_TERMINATION;

WB_EXPORT
CFTypeRef WBODCopyUserAttribute(CFStringRef username, ODAttributeType attribute);

WB_EXPORT
CFDictionaryRef WBODCopyUserAttributes(CFStringRef username, ODAttributeType attribute, ...) WB_REQUIRES_NIL_TERMINATION;

#endif /* __WB_DS_FUNCTIONS_H */
