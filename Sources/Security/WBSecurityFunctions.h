/*
 *  WBSecurityFunctions.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#include <Security/Security.h>

#if !defined(__WBSECURITY_FUNCTIONS_H)
#define __WBSECURITY_FUNCTIONS_H 1

#include <WonderBox/WBBase.h>

// MARK: Modern Security API
WB_EXPORT
bool WBSecTransformSetDigest(SecTransformRef trans, CFTypeRef digestAlg, CFIndex digestBitLength, CFErrorRef *error);

WB_EXPORT
SecTransformRef WBSecTransformCreateWithURL(CFURLRef url, CFErrorRef *error);

WB_EXPORT
SecTransformRef WBSecSignTransformCreate(SecKeyRef pkey, CFTypeRef digestAlg, CFIndex digestBitLength, CFErrorRef *error);

WB_EXPORT
SecTransformRef WBSecVerifyTransformCreate(SecKeyRef pkey, CFDataRef signature, CFTypeRef digestAlg, CFIndex digestBitLength, CFErrorRef *error);

// MARK: Convenient functions
WB_EXPORT
CFDataRef WBSecuritySignData(CFDataRef data, SecKeyRef pkey, CFTypeRef digestAlg, CFIndex digestBitLength, CFErrorRef *error);

WB_EXPORT
CFBooleanRef WBSecurityVerifySignature(CFDataRef data, CFDataRef signature, SecKeyRef pubKey, CFTypeRef digestAlg, CFIndex digestBitLength, CFErrorRef *error);

WB_EXPORT
CFBooleanRef WBSecurityVerifyDigestSignature(CFDataRef data, CFDataRef signature, SecKeyRef pubKey, CFTypeRef digestAlg, CFIndex digestBitLength, CFErrorRef *error);

WB_EXPORT
CFDataRef WBSecuritySignFile(CFURLRef fileURL, SecKeyRef pkey, CFTypeRef digestAlg, CFIndex digestBitLength, CFErrorRef *error);

WB_EXPORT
CFBooleanRef WBSecurityVerifyFileSignature(CFURLRef fileURL, CFDataRef signature, SecKeyRef pubKey, CFTypeRef digestAlg, CFIndex digestBitLength, CFErrorRef *error);

// MARK: -
WB_EXPORT
CFDictionaryRef WBSecItemCopyAttributes(CFTypeRef item, CFTypeRef itemClass);

#pragma mark Certificates
WB_EXPORT
CFStringRef WBCertificateCopyLabel(SecCertificateRef cert, CFErrorRef *error);

#pragma mark Identities
WB_EXPORT
OSStatus WBIdentityFindByEmail(CFTypeRef keychainOrArray, CFStringRef email, SecIdentityRef *identity);

//WB_EXPORT
//CFArrayRef WBSecurityCopyIdentities(CFTypeRef keychainOrArray, CSSM_KEYUSE usage) WB_DEPRECATED("CDSA is deprecated");
//WB_EXPORT
//CFArrayRef WBSecurityCopyPolicies(CSSM_CERT_TYPE certType, const CSSM_OID *policyOID, const CSSM_DATA *value) WB_DEPRECATED("CDSA is deprecated");

#pragma mark Signature
//
//WB_EXPORT
//CSSM_RETURN WBSecuritySignFileWithIdentity(const char *path, SecIdentityRef identity, SecCredentialType credentials, CSSM_ALGORITHMS algid, CSSM_DATA *signature) WB_DEPRECATED("CDSA is deprecated");
//WB_EXPORT
//CSSM_RETURN WBSecurityVerifyFileSignatureWithIdentity(const char *path, const CSSM_DATA *signature, SecIdentityRef identity, CSSM_ALGORITHMS algid, bool *outValid) WB_DEPRECATED("CDSA is deprecated");

#pragma mark Developement

WB_EXPORT
OSStatus WBSecurityPrintAttributeInfo(SecItemClass itemClass);
WB_EXPORT
OSStatus WBSecurityPrintItemAttributeInfo(SecKeychainItemRef item);

#endif /* __WBSECURITY_FUNCTIONS_H */
