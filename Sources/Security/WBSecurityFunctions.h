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

#pragma mark Keys
WB_EXPORT
OSStatus WBKeyGetStrengthInBits(SecKeyRef key, uint32 *strenght);
WB_EXPORT
OSStatus WBKeyQueryOutputSize(SecKeyRef key, bool crypts, uint32 inputSize, uint32 *outputSize) WB_DEPRECATED("not accurate. do not rely on this function");

#pragma mark Certificates
WB_EXPORT
OSStatus WBCertificateCopyLabel(SecCertificateRef cert, CFStringRef *label);

#pragma mark Identities
WB_EXPORT
CFArrayRef WBSecurityCopyIdentities(CFTypeRef keychainOrArray, CSSM_KEYUSE usage);
WB_EXPORT
CFArrayRef WBSecurityCopyPolicies(CSSM_CERT_TYPE certType, const CSSM_OID *policyOID, const CSSM_DATA *value);

WB_EXPORT
OSStatus WBIdentityFindByEmail(CFTypeRef keychainOrArray, CFStringRef email, SecIdentityRef *identity);

#pragma mark Signature
WB_EXPORT
OSStatus WBSecurityCreateVerifyContext(SecKeyRef pubKey, CSSM_ALGORITHMS algid, CSSM_CC_HANDLE *ccHandle);
WB_EXPORT
OSStatus WBSecurityCreateSignatureContext(SecKeyRef privKey, SecCredentialType credentials, CSSM_ALGORITHMS algid, CSSM_CC_HANDLE *ccHandle);

WB_EXPORT
OSStatus WBSecuritySignData(SecKeyRef privKey, SecCredentialType credentials, const CSSM_DATA *data, CSSM_ALGORITHMS digestAlg, CSSM_DATA *signature);
WB_EXPORT
OSStatus WBSecurityVerifySignature(SecKeyRef pubKey, const CSSM_DATA *digest, CSSM_ALGORITHMS digestAlg, const CSSM_DATA *signature, Boolean *valid);

WB_EXPORT
CSSM_RETURN WBSecuritySignFile(const char *path, SecKeyRef pkey, SecCredentialType credentials, CSSM_ALGORITHMS algid, CSSM_DATA *signature);
WB_EXPORT
CSSM_RETURN WBSecurityVerifyFileSignature(const char *path, const CSSM_DATA *signature, SecKeyRef pkey, CSSM_ALGORITHMS algid, bool *outValid);

WB_EXPORT
CSSM_RETURN WBSecuritySignFileWithIdentity(const char *path, SecIdentityRef identity, SecCredentialType credentials, CSSM_ALGORITHMS algid, CSSM_DATA *signature);
WB_EXPORT
CSSM_RETURN WBSecurityVerifyFileSignatureWithIdentity(const char *path, const CSSM_DATA *signature, SecIdentityRef identity, CSSM_ALGORITHMS algid, bool *outValid);

#pragma mark Developement

WB_EXPORT
OSStatus WBSecurityPrintAttributeInfo(SecItemClass itemClass);
WB_EXPORT
OSStatus WBSecurityPrintItemAttributeInfo(SecKeychainItemRef item);

#endif /* __WBSECURITY_FUNCTIONS_H */
