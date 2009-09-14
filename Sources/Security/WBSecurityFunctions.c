/*
 *  WBSecurityFunctions.c
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#include WBHEADER(WBSecurityFunctions.h)
#include WBHEADER(WBCDSAFunctions.h)

#include <unistd.h>

OSStatus WBKeyGetStrengthInBits(SecKeyRef key, CFIndex *strenght) {
  OSStatus err = noErr;
#if 0
  const CSSM_KEY *ckey;
  CSSM_CSP_HANDLE cspHandle;
  CSSM_KEY_SIZE keysize = {0, 0};
  
  err = SecKeyGetCSSMKey(key, &ckey);
  require_noerr(err, bail);
  
  err = SecKeyGetCSPHandle(key, &cspHandle);
  require_noerr(err, bail);
  
  /* unimplemented */
  err = CSSM_QueryKeySizeInBits(cspHandle,
                                CSSM_INVALID_HANDLE,
                                ckey,
                                &keysize);
  require_noerr(err, bail);
  *strenght = keysize.EffectiveKeySizeInBits ? : keysize.LogicalKeySizeInBits;
#else
  const CSSM_KEY *ckey;

  err = SecKeyGetCSSMKey(key, &ckey);
  require_noerr(err, bail);
  
  *strenght = ckey->KeyHeader.LogicalKeySizeInBits;
#endif
     
  /* unimplemented */
//  const CSSM_X509_ALGORITHM_IDENTIFIER *algid;
//  OSStatus err = SecKeyGetAlgorithmID(key, &algid);
//  if (noErr == err) {
//    unsigned int length = 0;
//    err = SecKeyGetStrengthInBits(key, NULL /* algid */, &length);
//    if (noErr == err)
//      *strenght = length;
//  }
bail:
  return err;
}

static
OSStatus _WBKeyCreateDefaultContext(SecKeyRef key, bool crypts, CSSM_CC_HANDLE *ccHandle) {
  const CSSM_KEY *ckey;
  CSSM_CSP_HANDLE cspHandle;
  
  OSStatus err = SecKeyGetCSSMKey(key, &ckey);
  require_noerr(err, bail);
  
  err = SecKeyGetCSPHandle(key, &cspHandle);
  require_noerr(err, bail);
  
  /* If sign or verify (~ crypts with private key, or decrypt with public key) */
  if ((crypts && ckey->KeyHeader.KeyClass == CSSM_KEYCLASS_PRIVATE_KEY) ||
      (!crypts && ckey->KeyHeader.KeyClass == CSSM_KEYCLASS_PUBLIC_KEY))
    err = CSSM_CSP_CreateSignatureContext(cspHandle, CSSM_ALGID_SHA1WithRSA, NULL, ckey, ccHandle);
  else
    err = WBCDSACreateCryptContext(cspHandle, ckey, NULL, ccHandle);
  
  require_noerr(err, bail);
  
bail:
  return err;
}

OSStatus WBKeyQueryOutputSize(SecKeyRef key, bool crypts, uint32 inputSize, uint32 *outputSize) {
  CSSM_CC_HANDLE ccHandle;
  CSSM_QUERY_SIZE_DATA size = { inputSize, 0 };
  
  OSStatus err = _WBKeyCreateDefaultContext(key, crypts, &ccHandle);
  require_noerr(err, bail);
  
  err = CSSM_QuerySize(ccHandle, crypts, 1, &size);
  CSSM_DeleteContext(ccHandle);
  require_noerr(err, bail);
  
  *outputSize = size.SizeOutputBlock;
  
bail:
  return err;
}

WB_INLINE
OSStatus __WBGetUInt32Attr(const SecKeychainAttributeList *list, SecKeychainAttrType name, UInt32 *value) {
  for (UInt32 idx = 0; idx < list->count; idx++) {
    if (name == list->attr[idx].tag) {
      if (list->attr[idx].length != sizeof(UInt32))
        return -1;
      if (value) *value = *(UInt32 *)list->attr[idx].data;
      return noErr;
    }
  }
  return errSecNoSuchAttr;
}

OSStatus WBCertificateCopyLabel(SecCertificateRef cert, CFStringRef *label) {
  if (!label) return paramErr;
  *label = NULL;
  
  OSStatus err = noErr;
  UInt32 tags[1] = { kSecLabelItemAttr };
  UInt32 formats[1] = { CSSM_DB_ATTRIBUTE_FORMAT_BLOB };
  SecKeychainAttributeInfo info = { 1, tags, formats };
  
  SecKeychainAttributeList *list = NULL;
  err = SecKeychainItemCopyAttributesAndData((SecKeychainItemRef)cert, &info, NULL, &list, NULL, NULL);
  if (noErr == err) {
    SecKeychainAttribute *attr = list->attr;
    *label = CFStringCreateWithBytes(kCFAllocatorDefault, attr->data, attr->length, kCFStringEncodingUTF8, FALSE);
    if (!*label)
      err = -1;
    
    SecKeychainItemFreeAttributesAndData(list, NULL); // ignore err
  }
  return err;
}

//static
//Boolean _WBIdentitiesEqual(const void *value1, const void *value2) {
//  SecIdentityRef i1 = (SecIdentityRef)value1, i2 = (SecIdentityRef)value2;
//  return kCFCompareEqualTo == SecIdentityCompare(i1, i2, 0);
//}
#pragma mark -
CFArrayRef WBSecurityCopyIdentities(CFTypeRef keychainOrArray, CSSM_KEYUSE usage) {
  CFMutableArrayRef idts = NULL;
  SecIdentitySearchRef search = NULL;
  OSStatus err = SecIdentitySearchCreate(keychainOrArray, usage, &search);
  if (noErr == err) {
    idts = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
    CFArrayCallBacks acb = kCFTypeArrayCallBacks;
//    acb.equal = _WBIdentitiesEqual;
    CFMutableArrayRef certs = CFArrayCreateMutable(kCFAllocatorDefault, 0, &acb);
    
    SecIdentityRef ident = NULL;
    while (noErr == (err = SecIdentitySearchCopyNext(search, &ident))) {
      if (!CFArrayContainsValue(certs, CFRangeMake(0, CFArrayGetCount(certs)), ident)) {
        CFArrayAppendValue(idts, ident);
        CFArrayAppendValue(certs, ident);
      }
      CFRelease(ident);
    }
    /* if an error occured */
    if (err != errSecItemNotFound) {
      CFRelease(idts);
      idts = NULL;
    }
    CFRelease(search);
    CFRelease(certs);
  }
  return idts;
}

CFArrayRef WBSecurityCopyPolicies(CSSM_CERT_TYPE certType, const CSSM_OID *policyOID, const CSSM_DATA *value) {
  SecPolicySearchRef search = NULL;
  CFMutableArrayRef policies = NULL;
  OSStatus err = SecPolicySearchCreate(certType, policyOID, value, &search);
  if (noErr == err) {
    policies = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
    
    SecPolicyRef policy = NULL;
    while (noErr == (err = SecPolicySearchCopyNext(search, &policy))) {
      CFArrayAppendValue(policies, policy);
      CFRelease(policy);
    }
    /* if an error occured */
    if (err != errSecPolicyNotFound) {
      CFRelease(policies);
      policies = NULL;
    }
    CFRelease(search);
  }
  return policies;
}

OSStatus WBIdentityFindByEmail(CFTypeRef keychainOrArray, CFStringRef email, SecIdentityRef *identity) {
	check(identity);
	check(!*identity);
	
  //SecKeychainItemRef pref;
	OSStatus err = SecIdentityCopyPreference(email, 0, NULL, identity);
  //OSStatus err = SecIdentityFindPreferenceItem(keychainOrArray, email, &pref);
  //if (noErr == err) {
    //err = SecIdentityCopyFromPreferenceItem(pref, identity);
    //CFRelease(pref);
  //} else 
	if (errSecItemNotFound == err || !*identity) {
    SecIdentitySearchRef search = NULL;
    err = SecIdentitySearchCreate(keychainOrArray, 0, &search);
    if (noErr == err) {
      SecIdentityRef ident = NULL;
      while (noErr == (err = SecIdentitySearchCopyNext(search, &ident))) {
        bool found = false;
        SecCertificateRef cert;
        err = SecIdentityCopyCertificate(ident, &cert);
        if (noErr == err) {
          CFArrayRef addresses = NULL;
          if (noErr == SecCertificateCopyEmailAddresses(cert, &addresses) && addresses) {
            if (CFArrayContainsValue(addresses, CFRangeMake(0, CFArrayGetCount(addresses)), email)) {
              found = true;
            }
            CFRelease(addresses);
          } else {
            WBCLogWarning("SecCertificateCopyEmailAddresses() return %ld", (long)err);
          }
          
          CFRelease(cert);
        }
        if (found) {
          *identity = ident;
          break;
        } else {
          CFRelease(ident);
        }
      }
    }
  }
  return err;
}

#pragma mark Signature
OSStatus WBSecurityCreateSignatureContext(SecKeyRef privKey, SecCredentialType credentials, CSSM_ALGORITHMS algid, CSSM_CC_HANDLE *ccHandle) {
  OSStatus err = noErr;
  CSSM_CSP_HANDLE cspHandle = 0;
  const CSSM_KEY *privkey = NULL;
  const CSSM_ACCESS_CREDENTIALS *credits = NULL;
  
  /* retreive cssm objects */
  err = SecKeyGetCSSMKey(privKey, &privkey);
  require_noerr(err, bail);
  err = SecKeyGetCSPHandle(privKey, &cspHandle);
  require_noerr(err, bail);
  err = SecKeyGetCredentials(privKey, CSSM_ACL_AUTHORIZATION_SIGN, credentials, &credits);
  require_noerr(err, bail);
  
  /* create cssm context */
  err = CSSM_CSP_CreateSignatureContext(cspHandle, algid, credits, privkey, ccHandle);
  require_noerr(err, bail);
  
bail:
    return err;
}

OSStatus WBSecurityCreateVerifyContext(SecKeyRef pubKey, CSSM_ALGORITHMS algid, CSSM_CC_HANDLE *ccHandle) {
  OSStatus err = noErr;
  CSSM_CSP_HANDLE cspHandle = 0;
  const CSSM_KEY *pubkey = NULL;
  
  /* retreive pubkey and csp */
  err = SecKeyGetCSSMKey(pubKey, &pubkey);
  require_noerr(err, bail);
  err = SecKeyGetCSPHandle(pubKey, &cspHandle);
  require_noerr(err, bail);
  
  /* create cssm context */
  err = CSSM_CSP_CreateSignatureContext(cspHandle, algid, NULL, pubkey, ccHandle);
  require_noerr(err, bail);
  
bail:
    return err;
}

OSStatus WBSecuritySignData(SecKeyRef privKey, SecCredentialType credentials, const CSSM_DATA *data, CSSM_ALGORITHMS algid, CSSM_DATA *signature) {
  OSStatus err = noErr;
  CSSM_CC_HANDLE ccHandle = 0;
  
  err = WBSecurityCreateSignatureContext(privKey, credentials, algid, &ccHandle);
  require_noerr(err, bail);
  err = CSSM_SignData(ccHandle, data, 1, CSSM_ALGID_NONE, signature);
  require_noerr(err, bail);
  
bail:
    /* cleanup */
    if (ccHandle) CSSM_DeleteContext(ccHandle);
  
  return err;
}

OSStatus WBSecurityVerifySignature(SecKeyRef pubKey, const CSSM_DATA *data, CSSM_ALGORITHMS algid, const CSSM_DATA *signature, Boolean *valid) {
  OSStatus err = noErr;
  CSSM_CC_HANDLE ccHandle = 0;
  
  /* retreive pubkey and csp */
  err = WBSecurityCreateVerifyContext(pubKey, algid, &ccHandle);
  require_noerr(err, bail);
  
  /* verify data */
  err = CSSM_VerifyData(ccHandle, data, 1, CSSM_ALGID_NONE, signature);
  if (CSSMERR_CSP_VERIFY_FAILED == err) {
    err = noErr;
    *valid = FALSE;
  } else if (noErr == err) {
    *valid = TRUE;
  }
  require_noerr(err, bail);
  
bail:
    /* cleanup */
    if (ccHandle) CSSM_DeleteContext(ccHandle);
  
  return err;
}

// MARK: File Signature
CSSM_RETURN WBSecuritySignFile(const char *path, SecKeyRef pkey, SecCredentialType credentials, CSSM_ALGORITHMS algid, CSSM_DATA *signature) {
  if (!path || !pkey || !signature) return CSSMERR_CSSM_INVALID_POINTER;
  
  int fd = open(path, O_RDONLY);
  if (fd <= 0) return CSSMERR_CSSM_FUNCTION_FAILED;
  /* disable file system caching */
  fcntl(fd, F_NOCACHE, 0);
  
  CSSM_CC_HANDLE ctxt;
  CSSM_RETURN err = WBSecurityCreateSignatureContext(pkey, credentials, algid, &ctxt);
  if (CSSM_OK == err) {
    err = CSSM_SignDataInit(ctxt);
    
    if (CSSM_OK == err) {
      const size_t blen = 64 * 1024;
      /* must be 4k align because caching is disabled */
      unsigned char *buffer = malloc(blen);
      if (!buffer) {
        err = CSSMERR_CSSM_MEMORY_ERROR;
      } else {
        ssize_t count = 0;
        while (CSSM_OK == err && (count = read(fd, buffer, blen)) > 0) {
          CSSM_DATA data = { count, buffer };
          err = CSSM_SignDataUpdate(ctxt, &data, 1);
        }
        if (count < 0)
          err = CSSMERR_CSSM_FUNCTION_FAILED;
        free(buffer);
      }
    }
    
    if (CSSM_OK == err) 
      err = CSSM_SignDataFinal(ctxt, signature);
    
    CSSM_DeleteContext(ctxt);
  }
  
  close(fd);  
  return err;
}

CSSM_RETURN WBSecurityVerifyFileSignature(const char *path, const CSSM_DATA *signature, SecKeyRef pkey, CSSM_ALGORITHMS algid, bool *outValid) {
  if (!path || !signature || !pkey || !outValid) return CSSMERR_CSSM_INVALID_POINTER;
  
  int fd = open(path, O_RDONLY);
  if (fd <= 0) return CSSMERR_CSSM_FUNCTION_FAILED;
  /* disable file system caching */
  fcntl(fd, F_NOCACHE, 0);
  
  *outValid = false;
  CSSM_CC_HANDLE ctxt;
  CSSM_RETURN err = WBSecurityCreateVerifyContext(pkey, algid, &ctxt);
  if (CSSM_OK == err) {
    err = CSSM_VerifyDataInit(ctxt);
    
    if (CSSM_OK == err) {
      const size_t blen = 64 * 1024;
      /* must be 4k align because caching is disabled */
      unsigned char *buffer = malloc(blen);
      if (!buffer) {
        err = CSSMERR_CSSM_MEMORY_ERROR;
      } else {
        ssize_t count = 0;
        while (CSSM_OK == err && (count = read(fd, buffer, blen)) > 0) {
          CSSM_DATA data = { count, buffer };
          err = CSSM_VerifyDataUpdate(ctxt, &data, 1);
        }
        if (count < 0)
          err = CSSMERR_CSSM_FUNCTION_FAILED;
        free(buffer);
      }
    }
    
    if (CSSM_OK == err) {
      err = CSSM_VerifyDataFinal(ctxt, signature);
      if (CSSM_OK == err)
        *outValid = true;
      else if (CSSMERR_CSP_VERIFY_FAILED == err)
        err = CSSM_OK; // just means that the signature is not valid
    }
    
    CSSM_DeleteContext(ctxt);
  }
  close(fd);
  
  return err;
}

CSSM_RETURN WBSecuritySignFileWithIdentity(const char *path, SecIdentityRef identity, SecCredentialType credentials, CSSM_ALGORITHMS algid, CSSM_DATA *signature) {
  SecKeyRef privKey;
  CSSM_RETURN err = SecIdentityCopyPrivateKey(identity, &privKey);
  if (noErr == err) {
    err = WBSecuritySignFile(path, privKey, credentials, algid, signature);
    CFRelease(privKey);
  }
  return err;
}

CSSM_RETURN WBSecurityVerifyFileSignatureWithIdentity(const char *path, const CSSM_DATA *signature, SecIdentityRef identity, CSSM_ALGORITHMS algid, bool *outValid) {
  SecCertificateRef cert;
  CSSM_RETURN err = SecIdentityCopyCertificate(identity, &cert);
  if (noErr == err) {
    SecKeyRef pubKey;
    err = SecCertificateCopyPublicKey(cert, &pubKey);
    if (noErr == err) {
      err = WBSecurityVerifyFileSignature(path, signature, pubKey, algid, outValid);
      CFRelease(pubKey);
    }
    CFRelease(cert);
  }
  return err;
}

#pragma mark -
/* Format strings */
WB_INLINE
const char *__WBAttributeFormat(UInt32 format) {
  switch (format) {
    case CSSM_DB_ATTRIBUTE_FORMAT_STRING:
      return "string";
    case CSSM_DB_ATTRIBUTE_FORMAT_SINT32:
      return "SInt32";
    case CSSM_DB_ATTRIBUTE_FORMAT_UINT32:
      return "UInt32";
    case CSSM_DB_ATTRIBUTE_FORMAT_BIG_NUM:
      return "big number";
    case CSSM_DB_ATTRIBUTE_FORMAT_REAL:
      return "real";
    case CSSM_DB_ATTRIBUTE_FORMAT_TIME_DATE:
      return "time/date";
    case CSSM_DB_ATTRIBUTE_FORMAT_BLOB:
      return "data";
    case CSSM_DB_ATTRIBUTE_FORMAT_MULTI_UINT32:
      return "multi UInt32";
    case CSSM_DB_ATTRIBUTE_FORMAT_COMPLEX:
      return "complex";
  }
  return "<unknown>";
}

WB_INLINE
const char *__WBAttributeName(OSType type) {
  switch (type) {
    case kSecCreationDateItemAttr: return "kSecCreationDateItemAttr";
    case kSecModDateItemAttr: return "kSecModDateItemAttr";
    case kSecDescriptionItemAttr: return "kSecDescriptionItemAttr";
    case kSecCommentItemAttr: return "kSecCommentItemAttr";
    case kSecCreatorItemAttr: return "kSecCreatorItemAttr";
    case kSecTypeItemAttr: return "kSecTypeItemAttr";
    case kSecScriptCodeItemAttr: return "kSecScriptCodeItemAttr";
    case kSecLabelItemAttr: return "kSecLabelItemAttr";
    case kSecInvisibleItemAttr: return "kSecInvisibleItemAttr";
    case kSecNegativeItemAttr: return "kSecNegativeItemAttr";
    case kSecCustomIconItemAttr: return "kSecCustomIconItemAttr";
    case kSecAccountItemAttr: return "kSecAccountItemAttr";
    case kSecServiceItemAttr: return "kSecServiceItemAttr";
    case kSecGenericItemAttr: return "kSecGenericItemAttr";
    case kSecSecurityDomainItemAttr: return "kSecSecurityDomainItemAttr";
    case kSecServerItemAttr: return "kSecServerItemAttr";
    case kSecAuthenticationTypeItemAttr: return "kSecAuthenticationTypeItemAttr";
    case kSecPortItemAttr: return "kSecPortItemAttr";
    case kSecPathItemAttr: return "kSecPathItemAttr";
    case kSecVolumeItemAttr: return "kSecVolumeItemAttr";
    case kSecAddressItemAttr: return "kSecAddressItemAttr";
    case kSecSignatureItemAttr: return "kSecSignatureItemAttr";
    case kSecProtocolItemAttr: return "kSecProtocolItemAttr";
//    case kSecCertificateType:
//    case kSecCertificateEncoding:
    case kSecCrlType: return "kSecCrlType";
    case kSecCrlEncoding: return "kSecCrlEncoding";
    case kSecAlias: return "kSecAlias";
      /* X509 extensions */
    case kSecSubjectItemAttr: return "kSecSubjectItemAttr";
    case kSecIssuerItemAttr: return "kSecIssuerItemAttr";
    case kSecSerialNumberItemAttr: return "kSecSerialNumberItemAttr";
    case kSecPublicKeyHashItemAttr: return "kSecPublicKeyHashItemAttr";
    case kSecSubjectKeyIdentifierItemAttr: return "kSecSubjectKeyIdentifierItemAttr";
    case kSecCertTypeItemAttr: return "kSecCertificateType / kSecCertTypeItemAttr";
    case kSecCertEncodingItemAttr: return "kSecCertificateEncoding / kSecCertEncodingItemAttr";
  }
  return NULL;
}

WB_INLINE
void __WBAttributeInfoPrint(SecKeychainAttributeInfo *info) {
  check(info != NULL);
  for (UInt32 idx = 0; idx < info->count; idx++) {
    const char *name = __WBAttributeName(info->tag[idx]);
    if (name) {
      printf("- %s: %s\n", name, __WBAttributeFormat(info->format[idx]));
    } else {
      char btag[4];
      OSWriteBigInt32(btag, 0, info->tag[idx]);
      if (btag[0] && btag[1] && btag[2] && btag[3])
        printf("- '%4.4s': %s\n", btag, __WBAttributeFormat(info->format[idx]));
      else
        printf("- %lu: %s\n", (long)info->tag[idx], __WBAttributeFormat(info->format[idx]));
    }
  }
}

OSStatus WBSecurityPrintAttributeInfo(SecItemClass itemClass) {
  SecKeychainRef keychain = NULL;
  SecKeychainAttributeInfo *info = NULL;
  
  OSStatus err = SecKeychainCopyDefault(&keychain);
  require_noerr(err, bail);
  err = SecKeychainAttributeInfoForItemID(keychain, itemClass, &info);
  require_noerr(err, bail);
  
  __WBAttributeInfoPrint(info);
  
bail:
  if (info) SecKeychainFreeAttributeInfo(info);
  if (keychain) CFRelease(keychain);
  
  return err;
}

OSStatus WBSecurityPrintItemAttributeInfo(SecKeychainItemRef item) {
  SecItemClass cls = 0;
  SecKeychainRef keychain = NULL;
  SecKeychainAttributeInfo *info = NULL;
  
  OSStatus err = SecKeychainItemCopyAttributesAndData(item, NULL, &cls, NULL, NULL, NULL);
  require_noerr(err, bail);
  
  err = SecKeychainItemCopyKeychain(item, &keychain);
  require_noerr(err, bail);
  
  err = SecKeychainAttributeInfoForItemID(keychain, cls, &info);
  require_noerr(err, bail);
  
  __WBAttributeInfoPrint(info);
  
bail:
    if (info) SecKeychainFreeAttributeInfo(info);
  if (keychain) CFRelease(keychain);
  
  return err;
}
