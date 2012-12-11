/*
 *  WBCDSAFunctions.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#if !defined(__WB_CDSA_FUNCTIONS_H)
#define __WB_CDSA_FUNCTIONS_H 1

#include <WonderBox/WBBase.h>

#include <Security/cssmtype.h>

WB_EXPORT CSSM_BOOL WBCDSADataEqual(const CSSM_DATA *d1, const CSSM_DATA *d2) WB_DEPRECATED("CDSA is deprecated");

WB_EXPORT const char *WBCDSAGetErrorString(CSSM_RETURN error) WB_DEPRECATED("CDSA is deprecated");
WB_EXPORT CFStringRef WBCDSACopyErrorMessageString(OSStatus status) DEPRECATED_IN_MAC_OS_X_VERSION_10_5_AND_LATER;
WB_EXPORT void WBCDSAPrintError(const char *op, CSSM_RETURN err) WB_DEPRECATED("CDSA is deprecated");

WB_EXPORT
CSSM_RETURN WBCDSAStartupModule(const CSSM_GUID *guid, CSSM_SERVICE_TYPE service, CSSM_MODULE_HANDLE *handle) WB_DEPRECATED("CDSA is deprecated");
WB_EXPORT
CSSM_RETURN WBCDSAShutdownModule(CSSM_MODULE_HANDLE handle) WB_DEPRECATED("CDSA is deprecated");

#pragma mark Helper
WB_EXPORT
CSSM_RETURN WBCDSACreateCryptContext(CSSM_CSP_HANDLE cspHandle, const CSSM_KEY *key, const CSSM_DATA *ivPtr, CSSM_CC_HANDLE *ccHandle) WB_DEPRECATED("CDSA is deprecated");

#pragma mark Memory functions
WB_EXPORT
void *WBCDSAMalloc(CSSM_MODULE_HANDLE handle, CSSM_SIZE size) WB_DEPRECATED("CDSA is deprecated");
WB_EXPORT
void *WBCDSACalloc(CSSM_MODULE_HANDLE handle, uint32 count, CSSM_SIZE size) WB_DEPRECATED("CDSA is deprecated");
WB_EXPORT
void *WBCDSARealloc(CSSM_MODULE_HANDLE handle, void *ptr, CSSM_SIZE length) WB_DEPRECATED("CDSA is deprecated");
WB_EXPORT
void WBCDSAFree(CSSM_MODULE_HANDLE handle, void *ptr) WB_DEPRECATED("CDSA is deprecated");

#endif  /* __WB_CDSA_FUNCTIONS_H */
