/*
 *  WBSecurityFunctions.c
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#include <WonderBox/WBSecurityFunctions.h>

#include <unistd.h>

bool WBSecTransformSetDigest(SecTransformRef trans, CFTypeRef digestAlg, CFIndex digestBitLength, CFErrorRef *error) {
  if (digestAlg) {
    if (!SecTransformSetAttribute(trans, kSecDigestTypeAttribute, digestAlg, error))
      return false;

    if (digestBitLength > 0) {
      spx::unique_cfptr<CFNumberRef> length(CFNumberCreate(kCFAllocatorDefault, kCFNumberCFIndexType, &digestBitLength));
      if (!SecTransformSetAttribute(trans, kSecDigestLengthAttribute, length.get(), error))
        return false;
    }
  }

  return true;
}

SecTransformRef WBSecSignTransformCreate(SecKeyRef pkey, CFTypeRef digestAlg, CFIndex digestBitLength, CFErrorRef *error) {
  spx::unique_cfptr<SecTransformRef> trans(SecSignTransformCreate(pkey, error));
  if (trans && !WBSecTransformSetDigest(trans.get(), digestAlg, digestBitLength, error))
    return nullptr;
  return trans.release();
}

SecTransformRef WBSecVerifyTransformCreate(SecKeyRef pkey, CFDataRef signature, CFTypeRef digestAlg, CFIndex digestBitLength, CFErrorRef *error) {
  spx::unique_cfptr<SecTransformRef> trans(SecVerifyTransformCreate(pkey, signature, error));
  if (trans && !WBSecTransformSetDigest(trans.get(), digestAlg, digestBitLength, error))
    return nullptr;
  return trans.release();
}

SecTransformRef WBSecTransformCreateWithURL(CFURLRef url, CFErrorRef *error) {
  spx::unique_cfptr<CFReadStreamRef> stream(CFReadStreamCreateWithFile(kCFAllocatorDefault, url));
  if (stream)
    return SecTransformCreateReadTransformWithReadStream(stream.get());
  if (error)
    *error = CFErrorCreate(kCFAllocatorDefault, kCFErrorDomainOSStatus, coreFoundationUnknownErr, nullptr);
  return nullptr;
}

CFDataRef WBSecuritySignData(CFDataRef data, SecKeyRef pkey, CFTypeRef digestAlg, CFIndex digestBitLength, CFErrorRef *error) {
  spx::unique_cfptr<SecTransformRef> sign(WBSecSignTransformCreate(pkey, digestAlg, digestBitLength, error));
  if (sign && SecTransformSetAttribute(sign.get(), kSecTransformInputAttributeName, data, error))
    return static_cast<CFDataRef>(SecTransformExecute(sign.get(), error));
  return nullptr;
}

CFBooleanRef WBSecurityVerifySignature(CFDataRef data, CFDataRef signature, SecKeyRef pubKey, CFTypeRef digestAlg, CFIndex digestBitLength, CFErrorRef *error) {
  spx::unique_cfptr<SecTransformRef> trans(WBSecVerifyTransformCreate(pubKey, signature, digestAlg, digestBitLength, error));
  if (trans && SecTransformSetAttribute(trans.get(), kSecTransformInputAttributeName, data, error))
    return static_cast<CFBooleanRef>(SecTransformExecute(trans.get(), error));
  return nullptr;
}

CFBooleanRef WBSecurityVerifyDigestSignature(CFDataRef data, CFDataRef signature, SecKeyRef pubKey, CFTypeRef digestAlg, CFIndex digestBitLength, CFErrorRef *error) {
  spx::unique_cfptr<SecTransformRef> trans(WBSecVerifyTransformCreate(pubKey, signature, digestAlg, digestBitLength, error));
  if (trans &&
      SecTransformSetAttribute(trans.get(), kSecInputIsAttributeName, kSecInputIsDigest, error) &&
      SecTransformSetAttribute(trans.get(), kSecTransformInputAttributeName, data, error))
    return static_cast<CFBooleanRef>(SecTransformExecute(trans.get(), error));
  return nullptr;
}

CFDataRef WBSecuritySignFile(CFURLRef fileURL, SecKeyRef pkey, CFTypeRef digestAlg, CFIndex digestBitLength, CFErrorRef *error) {
  spx::unique_cfptr<SecTransformRef> file(WBSecTransformCreateWithURL(fileURL, error));
  if (file) {
    spx::unique_cfptr<SecTransformRef> sign(WBSecSignTransformCreate(pkey, digestAlg, digestBitLength, error));
    if (sign) {
      spx::unique_cfptr<SecGroupTransformRef> group(SecTransformCreateGroupTransform());
      if (SecTransformConnectTransforms(file.get(), kSecTransformOutputAttributeName, sign.get(), kSecTransformInputAttributeName, group.get(), error)) {
        return static_cast<CFDataRef>(SecTransformExecute(group.get(), error));
      }
    }
  }
  return nullptr;
}

CFBooleanRef WBSecurityVerifyFileSignature(CFURLRef fileURL, CFDataRef signature, SecKeyRef pubKey, CFTypeRef digestAlg, CFIndex digestBitLength, CFErrorRef *error) {
  spx::unique_cfptr<SecTransformRef> file(WBSecTransformCreateWithURL(fileURL, error));
  if (file) {
    spx::unique_cfptr<SecTransformRef> verif(WBSecVerifyTransformCreate(pubKey, signature, digestAlg, digestBitLength, error));
    if (verif) {
      spx::unique_cfptr<SecGroupTransformRef> group(SecTransformCreateGroupTransform());
      if (SecTransformConnectTransforms(file.get(), kSecTransformOutputAttributeName, verif.get(), kSecTransformInputAttributeName, group.get(), error)) {
        return static_cast<CFBooleanRef>(SecTransformExecute(group.get(), error));
      }
    }
  }
  return nullptr;
}

// MARK: -
CFDictionaryRef WBSecItemCopyAttributes(CFTypeRef item, CFTypeRef itemClass) {
  CFTypeRef keys[] = {
    kSecClass,
    kSecReturnAttributes,
    kSecMatchLimit,
    kSecMatchItemList
  };
  spx::unique_cfptr<CFArrayRef> list(CFArrayCreate(kCFAllocatorDefault, &item, 1, &kCFTypeArrayCallBacks));
  CFTypeRef values[] = {
    itemClass,
    kCFBooleanTrue,
    kSecMatchLimitOne,
    list.get(),
  };
  spx::unique_cfptr<CFDictionaryRef> query(CFDictionaryCreate(kCFAllocatorDefault, keys, values, 4, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks));

  CFDictionaryRef attributes;
  OSStatus err = SecItemCopyMatching(query.get(), (CFTypeRef *)&attributes);
  if (noErr == err)
    return attributes;
  return nullptr;
}

CFStringRef WBCertificateCopyLabel(SecCertificateRef cert, CFErrorRef *error) {
  spx::unique_cfptr<CFArrayRef> attrs(CFArrayCreate(kCFAllocatorDefault, (const void **)&kSecPropertyKeyLabel, 1, &kCFTypeArrayCallBacks));
  spx::unique_cfptr<CFDictionaryRef> values(SecCertificateCopyValues(cert, attrs.get(), error));
  if (values) {
    CFStringRef label = (CFStringRef)CFDictionaryGetValue(values.get(), kSecPropertyKeyLabel);
    CFRetain(label);
    return label;
  }
  return nullptr;
}

//static
//Boolean _WBIdentitiesEqual(const void *value1, const void *value2) {
//  SecIdentityRef i1 = (SecIdentityRef)value1, i2 = (SecIdentityRef)value2;
//  return kCFCompareEqualTo == SecIdentityCompare(i1, i2, 0);
//}
#pragma mark -
OSStatus WBIdentityFindByEmail(CFTypeRef keychainOrArray, CFStringRef email, SecIdentityRef *identity) {
  if (!identity)
    return paramErr;

  OSStatus err = noErr;
  *identity = SecIdentityCopyPreferred(email, nullptr, nullptr);
  if (!*identity) {
    CFTypeRef keys[] = {
      kSecClass,
      kSecReturnRef,
      kSecMatchLimit,
      kSecMatchEmailAddressIfPresent,
      kSecMatchCaseInsensitive,
      kSecMatchWidthInsensitive,
      kSecMatchDiacriticInsensitive,
    };
    CFTypeRef values[] = {
      kSecClassIdentity,
      kCFBooleanTrue,
      kSecMatchLimitAll,
      email,
      kCFBooleanTrue,
      kCFBooleanTrue,
      kCFBooleanTrue,
    };
    CFArrayRef identities;
    spx::unique_cfptr<CFDictionaryRef> query(CFDictionaryCreate(kCFAllocatorDefault, keys, values, 7, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks));
    err = SecItemCopyMatching(query.get(), (CFTypeRef *)&identities);
    if (noErr == err) {
      for (CFIndex idx = 0, count = CFArrayGetCount(identities); !*identity && idx < count; ++idx) {
        SecIdentityRef ident = (SecIdentityRef)CFArrayGetValueAtIndex(identities, idx);
        SecCertificateRef cert;
        err = SecIdentityCopyCertificate(ident, &cert);
        if (noErr == err) {
          CFArrayRef addresses = NULL;
          if (noErr == SecCertificateCopyEmailAddresses(cert, &addresses) && addresses) {
            if (CFArrayContainsValue(addresses, CFRangeMake(0, CFArrayGetCount(addresses)), email)) {
              *identity = ident;
              CFRetain(*identity);
            }
            CFRelease(addresses);
          } else {
            spx_log_warning("SecCertificateCopyEmailAddresses() return %ld", (long)err);
          }
          CFRelease(cert);
        }
      }
    }
    if (noErr == err && !*identity)
      err = errSecItemNotFound;
  }
  return err;
}

#pragma mark Signature
#if 0

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
          CSSM_DATA data = { (CSSM_SIZE)count, buffer };
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
          CSSM_DATA data = { (CSSM_SIZE)count, buffer };
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
    CFRelease(privKey); // Analyze: Never NULL because noErr == err
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
      CFRelease(pubKey); // Analyze: Never NULL because noErr == err
    }
    CFRelease(cert);
  }
  return err;
}

#endif

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
  if (!info) return;
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
    if (info)
      SecKeychainFreeAttributeInfo(info);
  if (keychain) CFRelease(keychain);

  return err;
}
