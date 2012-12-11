/*
 *  WBCryptoFunctions.c
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#include <WonderBox/WBCryptoFunctions.h>

#include <unistd.h>
#include <Security/cssm.h>

#pragma mark -
#pragma mark --- start of public Functions ---

/*
 * Initialize WBCrypto and attach to the CSP.
 */
CSSM_RETURN WBCryptoCspAttach(CSSM_CSP_HANDLE *cspHandle) {
  return WBCDSAStartupModule(&gGuidAppleCSP, CSSM_SERVICE_CSP, cspHandle);
}

/*
 * Detach from CSP. To be called when app is finished with this
 * library.
 */
CSSM_RETURN WBCryptoCspDetach(CSSM_CSP_HANDLE cspHandle) {
  return WBCDSAShutdownModule(cspHandle);
}

#pragma mark -
#pragma mark ------ Key generation ------
/*
 * Derive a symmetric CSSM_KEY from the specified raw key material.
 */
CSSM_RETURN WBCryptoDeriveKey(CSSM_CSP_HANDLE cspHandle,
                              const void *rawKey,
                              size_t rawKeyLen,
                              const void *salt,
                              size_t saltLen,
                              uint32 iteration,
                              uint32 keySizeInBits,
                              CSSM_ALGORITHMS inKeyAlg,			// e.g., CSSM_ALGID_AES
                              CSSM_KEY_PTR outKey) {
  CSSM_RETURN crtn;
  CSSM_CC_HANDLE ccHand;
  CSSM_DATA dummyLabel = {8, (uint8 *)"tempKey"};
  CSSM_DATA saltData = {saltLen, (uint8 *)salt};
  CSSM_PKCS5_PBKDF2_PARAMS pbeParams;
  CSSM_DATA pbeData;
  CSSM_ACCESS_CREDENTIALS creds;

  memset(outKey, 0, sizeof(CSSM_KEY));
  memset(&creds, 0, sizeof(CSSM_ACCESS_CREDENTIALS));
  crtn = CSSM_CSP_CreateDeriveKeyContext(cspHandle,
                                         CSSM_ALGID_PKCS5_PBKDF2,
                                         inKeyAlg,
                                         keySizeInBits,
                                         &creds,
                                         NULL,			// BaseKey
                                         iteration,			// iterationCount, 1000 is the minimum
                                         &saltData,
                                         NULL,			// seed
                                         &ccHand);
  if(crtn) {
    return crtn;
  }

  /* this is the caller's raw key bits, typically ASCII (though it could be anything) */
  pbeParams.Passphrase.Data = (uint8 *)rawKey;
  pbeParams.Passphrase.Length = rawKeyLen;
  /* The only PRF supported by the CSP is HMACSHA1 */
  pbeParams.PseudoRandomFunction = CSSM_PKCS5_PBKDF2_PRF_HMAC_SHA1;
  pbeData.Data = (uint8 *)&pbeParams;
  pbeData.Length = sizeof(pbeParams);
  crtn = CSSM_DeriveKey(ccHand,
                        &pbeData,
                        CSSM_KEYUSE_ANY,
                        CSSM_KEYATTR_RETURN_DATA | CSSM_KEYATTR_EXTRACTABLE,
                        &dummyLabel,
                        NULL,			// cred and acl
                        outKey);
  CSSM_DeleteContext(ccHand);		// ignore error here
  return crtn;
}

/*
 * Generate asymmetric key pair. Currently supported algorithms
 * are RSA, DSA, and FEE.
 */
CSSM_RETURN WBCryptoGenerateKeyPair(CSSM_CSP_HANDLE cspHandle,
                                    CSSM_ALGORITHMS keyAlg,			// e.g., CSSM_ALGID_RSA
                                    uint32 keySizeInBits,
                                    CSSM_KEY_PTR publicKey,
                                    CSSM_KEY_PTR privateKey) {
  CSSM_RETURN crtn;
  CSSM_CC_HANDLE ccHandle;
  CSSM_DATA dummyLabel = {8, (uint8 *)"tempKey"};

  bzero(publicKey, sizeof(CSSM_KEY));
  bzero(privateKey, sizeof(CSSM_KEY));

  crtn = CSSM_CSP_CreateKeyGenContext(cspHandle,
                                      keyAlg,
                                      keySizeInBits,
                                      NULL,					// Seed
                                      NULL,					// Salt
                                      NULL,					// StartDate
                                      NULL,					// EndDate
                                      NULL,					// Params
                                      &ccHandle);
  if(crtn) {
    return crtn;
  }

  /* post-context-create algorithm-specific stuff */
  switch(keyAlg) {
    case CSSM_ALGID_DSA:
      /*
       * extra step - generate params - this just adds some
       * info to the context
       */
    {
      CSSM_DATA dummy = {0, NULL};
      crtn = CSSM_GenerateAlgorithmParams(ccHandle,
                                          keySizeInBits, &dummy);
      if(crtn) {
        return crtn;
      }
      free(dummy.Data);
    }
      break;
    default:
      /* RSA, FEE - nothing to do */
      break;
  }

  /*
   * Public keys can encrypt and verify signature.
   * Private keys can decrypt and sign.
   */
  crtn = CSSM_GenerateKeyPair(ccHandle,
                              CSSM_KEYUSE_ENCRYPT | CSSM_KEYUSE_VERIFY,
                              CSSM_KEYATTR_RETURN_DATA | CSSM_KEYATTR_EXTRACTABLE,
                              &dummyLabel,
                              publicKey,
                              CSSM_KEYUSE_DECRYPT | CSSM_KEYUSE_SIGN,
                              CSSM_KEYATTR_RETURN_DATA | CSSM_KEYATTR_EXTRACTABLE,
                              &dummyLabel,			// same labels
                              NULL,					// CredAndAclEntry
                              privateKey);
  CSSM_DeleteContext(ccHandle);
  return crtn;
}

/*
 * Free resources allocated in WBCryptoDeriveKey().
 */
CSSM_RETURN WBCryptoFreeKey(CSSM_CSP_HANDLE cspHandle, CSSM_KEY_PTR key) {
  return CSSM_FreeKey(cspHandle,
                      NULL,			// access cred
                      key,
                      CSSM_FALSE);	// don't delete since it wasn't permanent
}

#pragma mark -
#pragma mark ------ Diffie-Hellman key generation and derivation ------
/*
 * Generate a Diffie-Hellman key pair. Algorithm parameters are
 * either specified by caller via inParams, or are generated here
 * and returned to caller in outParams. Exactly one of (inParams,
 * outParams) must be non-NULL.
 */
CSSM_RETURN WBCryptoDhGenerateKeyPair(CSSM_CSP_HANDLE cspHandle,
                                      CSSM_KEY_PTR publicKey,
                                      CSSM_KEY_PTR privateKey,
                                      uint32 keySizeInBits,
                                      const CSSM_DATA *inParams,		// optional
                                      CSSM_DATA *outParams)		// optional, we malloc
{
  CSSM_RETURN crtn;
  CSSM_CC_HANDLE ccHandle;
  CSSM_DATA labelData = {8, (uint8 *)"tempKey"};

  /* Caller must specify either inParams or outParams, not both */
  if(inParams && outParams) {
    return CSSMERR_CSSM_INVALID_POINTER;
  }
  if(!inParams && !outParams) {
    return CSSMERR_CSSM_INVALID_POINTER;
  }
  memset(publicKey, 0, sizeof(CSSM_KEY));
  memset(privateKey, 0, sizeof(CSSM_KEY));

  crtn = CSSM_CSP_CreateKeyGenContext(cspHandle,
                                      CSSM_ALGID_DH,
                                      keySizeInBits,
                                      NULL,					// Seed
                                      NULL,					// Salt
                                      NULL,					// StartDate
                                      NULL,					// EndDate
                                      inParams,				// Params, may be NULL
                                      &ccHandle);
  if(crtn) {
    return crtn;
  }

  if(outParams) {
    /* explicitly generate params and return them to caller */
    outParams->Data = NULL;
    outParams->Length = 0;
    crtn = CSSM_GenerateAlgorithmParams(ccHandle,
                                        keySizeInBits, outParams);
    if(crtn) {
      CSSM_DeleteContext(ccHandle);
      return crtn;
    }
  }

  crtn = CSSM_GenerateKeyPair(ccHandle,
                              CSSM_KEYUSE_DERIVE,		// only legal use of a Diffie-Hellman key
                              CSSM_KEYATTR_RETURN_DATA | CSSM_KEYATTR_EXTRACTABLE,
                              &labelData,
                              publicKey,
                              /* private key specification */
                              CSSM_KEYUSE_DERIVE,
                              CSSM_KEYATTR_RETURN_REF,
                              &labelData,				// same labels
                              NULL,					// CredAndAclEntry
                              privateKey);
  CSSM_DeleteContext(ccHandle);
  return crtn;
}

/*
 * Perform Diffie-Hellman key exchange.
 * Given "our" private key (in the form of a CSSM_KEY) and "their" public
 * key (in the form of a raw blob of bytes), cook up a symmetric key.
 */
CSSM_RETURN WBCryptoDhKeyExchange(CSSM_CSP_HANDLE cspHandle,
                                  CSSM_KEY_PTR myPrivateKey,			// from WBCryptoDhGenerateKeyPair
                                  const void *theirPubKey,
                                  uint32 theirPubKeyLen,
                                  CSSM_KEY_PTR derivedKey,				// RETURNED
                                  uint32 deriveKeySizeInBits,
                                  CSSM_ALGORITHMS derivedKeyAlg)			// e.g., CSSM_ALGID_AES
{
  CSSM_RETURN crtn;
  CSSM_ACCESS_CREDENTIALS creds;
  CSSM_CC_HANDLE ccHandle;
  CSSM_DATA labelData = {8, (uint8 *)"tempKey"};

  memset(&creds, 0, sizeof(CSSM_ACCESS_CREDENTIALS));
  memset(derivedKey, 0, sizeof(CSSM_KEY));

  crtn = CSSM_CSP_CreateDeriveKeyContext(cspHandle,
                                         CSSM_ALGID_DH,
                                         derivedKeyAlg,
                                         deriveKeySizeInBits,
                                         &creds,
                                         myPrivateKey,	// BaseKey
                                         0,				// IterationCount
                                         0,				// Salt
                                         0,				// Seed
                                         &ccHandle);
  if(crtn) {
    return crtn;
  }

  /* public key passed in as CSSM_DATA *Param */
  CSSM_DATA theirPubKeyData = { theirPubKeyLen, (uint8 *)theirPubKey };

  crtn = CSSM_DeriveKey(ccHandle,
                        &theirPubKeyData,
                        CSSM_KEYUSE_ANY,
                        CSSM_KEYATTR_RETURN_DATA | CSSM_KEYATTR_EXTRACTABLE,
                        &labelData,
                        NULL,				// cread/acl
                        derivedKey);
  CSSM_DeleteContext(ccHandle);
  return crtn;
}

#pragma mark -
#pragma mark ------ Simple encrypt/decrypt routines ------
/*
 * Common initialization vector shared by encrypt and decrypt.
 * Some applications may wish to specify a different IV for
 * each encryption op (e.g., disk block number, IP packet number,
 * etc.) but that is outside the scope of this library.
 */
WB_DEPRECATED("CDSA is deprecated")
static uint8 iv[16] = { 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 };
WB_DEPRECATED("CDSA is deprecated")
static const CSSM_DATA ivCommon = {16, iv};

/*
 * Encrypt.
 * cipherText->Data is allocated by the CSP and must be freed (via
 * free()) by caller.
 */
CSSM_RETURN WBCryptoEncrypt(CSSM_CSP_HANDLE cspHandle,
                            const CSSM_KEY *key,
                            const CSSM_DATA *plainText,
                            CSSM_DATA *cipherText) {
  CSSM_RETURN crtn;
  CSSM_CC_HANDLE ccHandle;
  CSSM_DATA remData = {0, NULL};
  CSSM_SIZE bytesEncrypted;

  crtn = WBCDSACreateCryptContext(cspHandle, key, &ivCommon, &ccHandle);
  if(crtn) {
    return crtn;
  }
  cipherText->Length = 0;
  cipherText->Data = NULL;
  crtn = CSSM_EncryptData(ccHandle,
                          plainText,
                          1,
                          cipherText,
                          1,
                          &bytesEncrypted,
                          &remData);
  CSSM_DeleteContext(ccHandle);
  if(crtn) {
    return crtn;
  }

  cipherText->Length = bytesEncrypted;
  if(remData.Length != 0) {
    /* append remaining data to cipherText */
    CSSM_SIZE newLen = cipherText->Length + remData.Length;

    cipherText->Data = (uint8 *)WBCDSARealloc(cspHandle, cipherText->Data, newLen);
    memmove(cipherText->Data + cipherText->Length, remData.Data, remData.Length);
    cipherText->Length = newLen;
    WBCDSAFree(cspHandle, remData.Data);
  }
  return CSSM_OK;
}

/*
 * Decrypt.
 * plainText->Data is allocated by the CSP and must be freed (via
 * free()) by caller.
 */
CSSM_RETURN WBCryptoDecrypt(CSSM_CSP_HANDLE cspHandle,
                            const CSSM_KEY *key,
                            const CSSM_DATA *cipherText,
                            CSSM_DATA *plainText) {
  CSSM_RETURN crtn;
  CSSM_CC_HANDLE ccHandle;
  CSSM_DATA remData = {0, NULL};
  CSSM_SIZE bytesDecrypted;

  crtn = WBCDSACreateCryptContext(cspHandle, key, &ivCommon, &ccHandle);
  if(crtn) {
    return crtn;
  }
  plainText->Length = 0;
  plainText->Data = NULL;
  crtn = CSSM_DecryptData(ccHandle,
                          cipherText,
                          1,
                          plainText,
                          1,
                          &bytesDecrypted,
                          &remData);
  CSSM_DeleteContext(ccHandle);
  if(crtn) {
    return crtn;
  }

  plainText->Length = bytesDecrypted;
  if(remData.Length != 0) {
    /* append remaining data to plainText */
    CSSM_SIZE newLen = plainText->Length + remData.Length;
    plainText->Data = (uint8 *)WBCDSARealloc(cspHandle, plainText->Data, newLen);
    memmove(plainText->Data + plainText->Length, remData.Data, remData.Length);
    plainText->Length = newLen;
    WBCDSAFree(cspHandle, remData.Data);
  }
  return CSSM_OK;
}

#pragma mark -
#pragma mark ------ Staged encrypt/decrypt routines ------
/*
 * Staged init - cook up a CSSM_CC_HANDLE and call the appropriate
 * init.
 */
CSSM_RETURN WBCryptoStagedEncDecrInit(CSSM_CSP_HANDLE cspHandle,		// from WBCryptoCspAttach()
                                      const CSSM_KEY *key,			// from WBCryptoDeriveKey()
                                      StagedOpType opType,			// SO_Encrypt, SO_Decrypt
                                      CSSM_CC_HANDLE *ccHandle)		// RETURNED
{
  CSSM_RETURN crtn;
  CSSM_CC_HANDLE ccHand;

  crtn = WBCDSACreateCryptContext(cspHandle, key, &ivCommon, &ccHand);
  if(crtn) {
    return crtn;
  }
  switch(opType) {
    case SO_Encrypt:
      crtn = CSSM_EncryptDataInit(ccHand);
      break;
    case SO_Decrypt:
      crtn = CSSM_DecryptDataInit(ccHand);
      break;
    default:
      return CSSMERR_CSP_FUNCTION_NOT_IMPLEMENTED;
  }
  if(crtn) {
    CSSM_DeleteContext(ccHand);
  }
  else {
    *ccHandle = ccHand;
  }
  return CSSM_OK;
}

WB_INLINE WB_DEPRECATED("CDSA is deprecated")
CSSM_CSP_HANDLE __WBCSSM_GetCSPFromContext(CSSM_CC_HANDLE ccHandle) {
  CSSM_CONTEXT *ctxt;
  if (CSSM_OK == CSSM_GetContext(ccHandle, &ctxt))
    return ctxt->CSPHandle;
  return 0;
}
/*
 * Encrypt.
 * cipherText->Data is allocated by the CSP and must be freed (via
 * free()) by caller.
 */
CSSM_RETURN WBCryptoStagedEncrypt(CSSM_CC_HANDLE ccHandle,		// from WBCryptoStagedEncDecrInit()
                                  CSSM_BOOL final,			// CSSM_TRUE on last call
                                  const CSSM_DATA *plainText,
                                  CSSM_DATA *cipherText) {
  CSSM_RETURN crtn = CSSM_OK;

  cipherText->Length = 0;
  cipherText->Data = NULL;

  /* 1. any more data to encrypt? */
  if(plainText && plainText->Length) {
    CSSM_SIZE bytesEncrypted;

    crtn = CSSM_EncryptDataUpdate(ccHandle,
                                  plainText,
                                  1,
                                  cipherText,
                                  1,
                                  &bytesEncrypted);
    if(crtn) {
      goto abort;
    }
    cipherText->Length = bytesEncrypted;
  }

  /* 2. Last call? */
  if(final) {
    CSSM_DATA remData = {0, NULL};

    crtn = CSSM_EncryptDataFinal(ccHandle, &remData);
    if(crtn) {
      goto abort;
    }

    /* append remaining data to plainText */
    CSSM_SIZE newLen = cipherText->Length + remData.Length;

    cipherText->Data = (uint8 *)WBCDSARealloc(__WBCSSM_GetCSPFromContext(ccHandle), cipherText->Data, newLen);
    memmove(cipherText->Data + cipherText->Length,
            remData.Data, remData.Length);
    cipherText->Length = newLen;
    WBCDSAFree(__WBCSSM_GetCSPFromContext(ccHandle), remData.Data);
  }
abort:
  /* in any case, delete the context if we're done */
  if(final) {
    CSSM_DeleteContext(ccHandle);
  }
  return crtn;
}

/*
 * Decrypt.
 * plainText->Data is allocated by the CSP and must be freed (via
 * free()) by caller.
 */
CSSM_RETURN WBCryptoStagedDecrypt(CSSM_CC_HANDLE ccHandle,		// from WBCryptoStagedEncDecrInit()
                                  CSSM_BOOL final,			// CSSM_TRUE on last call
                                  const CSSM_DATA *cipherText,
                                  CSSM_DATA *plainText) {
  CSSM_RETURN crtn = CSSM_OK;

  plainText->Length = 0;
  plainText->Data = NULL;

  /* 1. any more data to decrypt? */
  if(cipherText && cipherText->Length) {
    CSSM_SIZE bytesDecrypted;

    crtn = CSSM_DecryptDataUpdate(ccHandle,
                                  cipherText,
                                  1,
                                  plainText,
                                  1,
                                  &bytesDecrypted);
    if(crtn) {
      goto abort;
    }
    plainText->Length = bytesDecrypted;
  }

  /* 2. Last call? */
  if(final) {
    CSSM_DATA remData = {0, NULL};

    crtn = CSSM_DecryptDataFinal(ccHandle, &remData);
    if(crtn) {
      goto abort;
    }

    /* append remaining data to plainText */
    CSSM_SIZE newLen = plainText->Length + remData.Length;
    plainText->Data = (uint8 *)WBCDSARealloc(__WBCSSM_GetCSPFromContext(ccHandle), plainText->Data, newLen);
    memmove(plainText->Data + plainText->Length,
            remData.Data, remData.Length);
    plainText->Length = newLen;
    WBCDSAFree(__WBCSSM_GetCSPFromContext(ccHandle), remData.Data);
  }
abort:
  /* in any case, delete the context if we're done */
  if(final) {
    CSSM_DeleteContext(ccHandle);
  }
  return crtn;
}

#pragma mark -
#pragma mark ------ Digest routines ------
/*
 * The simple one-shot digest routine, when all of the data to
 * be processed is available at once.
 * digest->Data is allocated by the CSP and must be freed (via
 * free()) by caller.
 */
CSSM_RETURN WBCryptoDigest(CSSM_CSP_HANDLE cspHandle,		// from WBCryptoCspAttach()
                           CSSM_ALGORITHMS digestAlg,		// e.g., CSSM_ALGID_SHA1
                           const CSSM_DATA *inData,
                           CSSM_DATA *digestData) {
  CSSM_RETURN crtn;
  CSSM_CC_HANDLE ccHandle;

  digestData->Data = NULL;
  digestData->Length = 0;

  crtn = CSSM_CSP_CreateDigestContext(cspHandle, digestAlg, &ccHandle);
  if(crtn) {
    return crtn;
  }
  crtn = CSSM_DigestData(ccHandle, inData, 1, digestData);
  CSSM_DeleteContext(ccHandle);
  return crtn;
}

/*
 * Staged digest routines. For processing multiple chunks of
 * data into one digest.
 * This is called once....
 */
CSSM_RETURN WBCryptoStagedDigestInit(CSSM_CSP_HANDLE cspHandle,		// from WBCryptoCspAttach()
                                     CSSM_ALGORITHMS digestAlg,		// e.g., CSSM_ALGID_SHA1
                                     CSSM_CC_HANDLE *ccHandle)		// RETURNED
{
  CSSM_RETURN crtn;
  CSSM_CC_HANDLE ccHand;

  crtn = CSSM_CSP_CreateDigestContext(cspHandle, digestAlg, &ccHand);
  if(crtn) {
    return crtn;
  }
  crtn = CSSM_DigestDataInit(ccHand);
  if(crtn) {
    CSSM_DeleteContext(ccHand);
  }
  else {
    *ccHandle = ccHand;
  }
  return crtn;
}

CSSM_RETURN WBCryptoStagedDigest(CSSM_CC_HANDLE ccHandle,		// from WBCryptoStagedEncDecrInit()
                                 CSSM_BOOL final,			// CSSM_TRUE on last call
                                 const CSSM_DATA *inData,
                                 CSSM_DATA *digestData) {
  CSSM_RETURN crtn = CSSM_OK;

  /* 1. any more data to digest? */
  if(inData && inData->Length) {
    crtn = CSSM_DigestDataUpdate(ccHandle, inData, 1);
    if(crtn) {
      goto abort;
    }
  }

  /* 2. Last call? */
  if(final) {
    digestData->Data = NULL;
    digestData->Length = 0;

    crtn = CSSM_DigestDataFinal(ccHandle, digestData);
  }
abort:
  /* in any case, delete the context if we're done */
  if(final) {
    CSSM_DeleteContext(ccHandle);
  }
  return crtn;
}
#if 0
CSSM_RETURN WBCryptoDigestFile(CSSM_CSP_HANDLE cspHandle,
                               CSSM_ALGORITHMS digestAlg,
                               const char *path,
                               CSSM_DATA *outDigestData) {
  int fd = open(path, O_RDONLY);
  if (fd <= 0)
    return CSSM_ERRCODE_FUNCTION_FAILED;
  /* disable file system caching */
  fcntl(fd, F_NOCACHE, 0);

  CSSM_RETURN err = CSSM_OK;

  CSSM_CC_HANDLE ctxt;
  err = WBCryptoStagedDigestInit(cspHandle, digestAlg, &ctxt);
  if (CSSM_OK == err) {
    /* should be 4k align because caching is disabled */
    char *buffer = malloc(32 * 1024);
    if (!buffer) {
      err = CSSM_ERRCODE_MEMORY_ERROR;
    } else {
      ssize_t count;
      while (CSSM_OK == err && (count = read(fd, buffer, 32 * 1024)) > 0) {
        CSSM_DATA data = { count, (UInt8 *)buffer };
        err = WBCryptoStagedDigest(ctxt, false, &data, NULL);
      }
      if (count < 0)
        err = CSSM_ERRCODE_FUNCTION_FAILED;
      free(buffer);
    }

    if (CSSM_OK == err) {
      /* final call delete the context */
      err = WBCryptoStagedDigest(ctxt, true, NULL, outDigestData);
    } else {
      CSSM_DeleteContext(ctxt);
    }
  }
  close(fd);

  return err;
}
#endif
#pragma mark -
#pragma mark ------ Simple sign/verify ------
/*
 * Generate a digital signature, one-shot version. To be
 * used when all of the data to be signed is available at once.
 * signature->Data is allocated by the CSP and must be freed (via free()) by caller.
 */
CSSM_RETURN WBCryptoSign(CSSM_CSP_HANDLE cspHandle,		// from WBCryptoCspAttach()
                         const CSSM_KEY *key,			// from WBCryptoDeriveKey()
                         CSSM_ALGORITHMS sigAlg,			// e.g., CSSM_ALGID_SHA1WithRSA
                         const CSSM_DATA *dataToSign,
                         CSSM_DATA *signature) {
  CSSM_CC_HANDLE sigHand;
  CSSM_RETURN crtn;

  crtn = CSSM_CSP_CreateSignatureContext(cspHandle,
                                         sigAlg,
                                         NULL,				// passPhrase
                                         key,
                                         &sigHand);
  if(crtn) {
    return crtn;
  }
  crtn = CSSM_SignData(sigHand,
                       dataToSign,
                       1,
                       CSSM_ALGID_NONE,
                       signature);
  CSSM_DeleteContext(sigHand);
  return crtn;
}

/*
 * Verify a digital signature, one-shot version. To be
 * used when all of the data to be verified is available at once.
 */
CSSM_RETURN WBCryptoVerify(CSSM_CSP_HANDLE cspHandle,		// from WBCryptoCspAttach()
                           const CSSM_KEY *key,			// from WBCryptoDeriveKey()
                           CSSM_ALGORITHMS sigAlg,			// e.g., CSSM_ALGID_SHA1WithRSA
                           const CSSM_DATA *dataToSign,
                           const CSSM_DATA *signature) {
  CSSM_CC_HANDLE sigHand;
  CSSM_RETURN crtn;

  crtn = CSSM_CSP_CreateSignatureContext(cspHandle,
                                         sigAlg,
                                         NULL,				// passPhrase
                                         key,
                                         &sigHand);
  if(crtn) {
    return crtn;
  }
  crtn = CSSM_VerifyData(sigHand,
                         dataToSign,
                         1,
                         CSSM_ALGID_NONE,
                         signature);
  CSSM_DeleteContext(sigHand);
  return crtn;
}

#pragma mark -
#pragma mark ------ Staged Sign/Verify routines ------
/*
 * These routines are used to initialize staged sign and
 * verify oprtations. A typical use for these routines
 * would be to generate or verify a digitial signature for
 * data coming from a stream or a file.
 *
 * To use these functions, first call WBCryptoStagedSignVerifyInit
 * to set up a CSSM_CC_HANDLE. Then call WBCryptoStagedSign
 * or WBCryptoStagedVerify as many times as you wish, passing a
 * non-NULL 'signature' argument only for the last call.
 * Caller does not need to be concerned about buffer or block
 * boundaries.
 */

CSSM_RETURN WBCryptoStagedSignVerifyInit(CSSM_CSP_HANDLE cspHandle,		// from WBCryptoCspAttach()
                                         const CSSM_KEY *key,			// from WBCryptoDeriveKey()
                                         CSSM_ALGORITHMS sigAlg,			// e.g., CSSM_ALGID_SHA1WithRSA
                                         StagedOpType opType,			// SO_Sign, SO_Verify
                                         CSSM_CC_HANDLE *ccHandle)		// RETURNED
{
  CSSM_CC_HANDLE sigHand;
  CSSM_RETURN crtn;

  /* Create a signature context */
  crtn = CSSM_CSP_CreateSignatureContext(cspHandle, sigAlg, NULL,				// passPhrase
                                         key, &sigHand);
  if(crtn) {
    return crtn;
  }

  /* init */
  switch(opType) {
    case SO_Sign:
      crtn = CSSM_SignDataInit(sigHand);
      break;
    case SO_Verify:
      crtn = CSSM_VerifyDataInit(sigHand);
      break;
    default:
      return CSSMERR_CSP_FUNCTION_NOT_IMPLEMENTED;
  }
  if(crtn) {
    CSSM_DeleteContext(sigHand);
  }
  else {
    *ccHandle = sigHand;
  }
  return CSSM_OK;
}

/*
 * Sign.
 * -- The signature argument is non-NULL only on the final call to
 *    this function.
 * -- signature->Data is allocated by the CSP and must be freed (via
 *    free()) by caller.
 * -- dataToSign and its referent (dataToSign->Data) are optional on
 *    the final call; either one can be NULL at that time.
 */
CSSM_RETURN WBCryptoStagedSign(CSSM_CC_HANDLE ccHandle,		// from WBCryptoStagedSignVerifyInit()
                               const CSSM_DATA *dataToSign,
                               CSSM_DATA *signature)		// non-NULL on final call only
{
  CSSM_RETURN crtn = CSSM_OK;

  /* 1. Any more data to sign? */
  if(dataToSign && dataToSign->Length) {
    crtn = CSSM_SignDataUpdate(ccHandle, dataToSign, 1);
  }

  /* 2. Last call? */
  if(signature && (crtn == CSSM_OK)) {
    signature->Length = 0;
    signature->Data = NULL;
    crtn = CSSM_SignDataFinal(ccHandle, signature);
  }

  /* 3. Delete the context if we're done */
  if(signature)
    CSSM_DeleteContext(ccHandle);

  return crtn;
}

/*
 * Verify.
 * -- The signature argument is non-NULL only on the final call to
 *    this function.
 * -- dataToVerify and its referent (dataToVerify->Data) are optional on
 *    the final call; either one can be NULL at that time.
 */
CSSM_RETURN WBCryptoStagedVerify(CSSM_CC_HANDLE ccHandle,		// from WBCryptoStagedSignVerifyInit()
                                 const CSSM_DATA *dataToVerify,
                                 const CSSM_DATA *signature)		// non-NULL on final call only
{
  CSSM_RETURN crtn = CSSM_OK;

  /* 1. any more data to verify? */
  if(dataToVerify && dataToVerify->Length) {
    crtn = CSSM_VerifyDataUpdate(ccHandle, dataToVerify, 1);
  }

  /* 2. Last call? */
  if(signature && (crtn == CSSM_OK)) {
    crtn = CSSM_VerifyDataFinal(ccHandle, signature);
  }

  /* 3. Delete the context if we're done */
  if(signature) {
    CSSM_DeleteContext(ccHandle);
  }
  return crtn;
}
