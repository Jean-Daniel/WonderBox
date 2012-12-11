/*
 *  WBCryptoFunctions.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#if !defined(__WBCRYPTO_FUNCTIONS_H)
#define __WBCRYPTO_FUNCTIONS_H 1

#include <WonderBox/WBCDSAFunctions.h>

#pragma mark -
/*!
 @function
 @abstract Initialize WBCrypto and attach to the CSP.
 @param cspHandle
 @result
 */
WB_EXPORT
CSSM_RETURN WBCryptoCspAttach(CSSM_CSP_HANDLE *cspHandle) WB_DEPRECATED("CDSA is deprecated");

/*!
 @function
 @abstract Detach from CSP. To be called when app is finished with this library.
 @param cspHandle
 @result
 */
WB_EXPORT
CSSM_RETURN WBCryptoCspDetach(CSSM_CSP_HANDLE cspHandle) WB_DEPRECATED("CDSA is deprecated");

#pragma mark -

/*!
 @functiongroup Key generation
 */
#pragma mark ------ Key generation ------
/*!
 @function
 @abstract Derive a CSSM_KEY from the specified raw key material.
 @param cspHandle See WBCryptoCspAttach()
 @param rawKey
 @param rawKeyLen
 @param keyAlg e.g., CSSM_ALGID_AES
 @param keySizeInBits
 @param key
 @result Cryptographie result code.
 */
WB_EXPORT
CSSM_RETURN WBCryptoDeriveKey(CSSM_CSP_HANDLE cspHandle,
                              const void *rawKey,
                              size_t rawKeyLen,
                              const void *salt,
                              size_t saltLen,
                              uint32 iteration,
                              uint32 keySizeInBits,
                              CSSM_ALGORITHMS inKeyAlg,			// e.g., CSSM_ALGID_AES
                              CSSM_KEY_PTR outKey) WB_DEPRECATED("CDSA is deprecated");

/*
 * Generate asymmetric key pair. Currently supported algorithms
 * are RSA, DSA, and FEE.
 */
WB_EXPORT
CSSM_RETURN WBCryptoGenerateKeyPair(CSSM_CSP_HANDLE 	cspHandle,
                                    CSSM_ALGORITHMS		keyAlg,			// e.g., CSSM_ALGID_RSA
                                    uint32			keySizeInBits,
                                    CSSM_KEY_PTR		publicKey,
                                    CSSM_KEY_PTR		privateKey) WB_DEPRECATED("CDSA is deprecated");

/*
 * Free resources allocated in WBCryptoDeriveKey and WBCryptoGenerateKeyPair().
 */
WB_EXPORT
CSSM_RETURN WBCryptoFreeKey(CSSM_CSP_HANDLE		cspHandle,		// from WBCryptoCspAttach()
                            CSSM_KEY_PTR		key) WB_DEPRECATED("CDSA is deprecated");			// from WBCryptoDeriveKey()

#pragma mark -
/*!
 @functiongroup Diffie-Hellman
 */
#pragma mark ------ Diffie-Hellman key generation and derivation ------
/*
 * Generate a Diffie-Hellman key pair. Algorithm parameters are
 * either specified by caller via inParams, or are generated here
 * and returned to caller in outParams. Exactly one of (inParams, outParams) must be non-NULL.
 */
WB_EXPORT
CSSM_RETURN WBCryptoDhGenerateKeyPair(CSSM_CSP_HANDLE	cspHandle,
                                      CSSM_KEY_PTR	publicKey,
                                      CSSM_KEY_PTR	privateKey,
                                      uint32			keySizeInBits,
                                      const CSSM_DATA	*inParams,			// optional
                                      CSSM_DATA *outParams) WB_DEPRECATED("CDSA is deprecated");			// optional, we malloc

/*
 * Perform Diffie-Hellman key exchange.
 * Given "our" private key (in the form of a CSSM_KEY) and "their" public
 * key (in the form of a raw blob of bytes), cook up a symmetric key.
 */
WB_EXPORT
CSSM_RETURN WBCryptoDhKeyExchange(CSSM_CSP_HANDLE	cspHandle,
                                  CSSM_KEY_PTR	myPrivateKey,		// from WBCryptoDhGenerateKeyPair
                                  const void		*theirPubKey,
                                  uint32			theirPubKeyLen,
                                  CSSM_KEY_PTR	derivedKey,			// RETURNED
                                  uint32			deriveKeySizeInBits,
                                  CSSM_ALGORITHMS	derivedKeyAlg) WB_DEPRECATED("CDSA is deprecated");		// e.g., CSSM_ALGID_AES

#pragma mark -
/*!
 @functiongroup Simple Encrypt/Decrypt
 */
#pragma mark ------ Simple encrypt/decrypt routines ------
/*
 * These routines are used to perform simple "one-shot"
 * encryption and decryption oprtations. Use them when
 * all of the data to be encrypted or decrypted is
 * available at once.
 */

/*
 * Encrypt.
 * cipherText->Data is allocated by the CSP and must be freed (via WBCryptoFree()) by caller.
 */
WB_EXPORT
CSSM_RETURN WBCryptoEncrypt(CSSM_CSP_HANDLE		cspHandle,		// from WBCryptoCspAttach()
                            const CSSM_KEY		*key,			// from WBCryptoDeriveKey()
                            const CSSM_DATA		*plainText,
                            CSSM_DATA *cipherText) WB_DEPRECATED("CDSA is deprecated");

/*
 * Decrypt.
 * plainText->Data is allocated by the CSP and must be freed (via WBCryptoFree()) by caller.
 */
WB_EXPORT
CSSM_RETURN WBCryptoDecrypt(CSSM_CSP_HANDLE cspHandle,		// from WBCryptoCspAttach()
                            const CSSM_KEY *key,			// from WBCryptoDeriveKey()
                            const CSSM_DATA *cipherText,
                            CSSM_DATA *plainText) WB_DEPRECATED("CDSA is deprecated");

#pragma mark -
/*!
 @functiongroup Staged Encrypt/Decrypt
 */
#pragma mark ------ Staged encrypt/decrypt routines ------
/*
 * These routines are used to perform staged encryption and
 * decryption operations. A typical use for these routines
 * would be to encrypt or decrypt data coming from a
 * stream or a file.
 *
 * To use these functions, first call WBCryptoStagedEncDecrInit
 * to set up a CSSM_CC_HANDLE. Then call WBCryptoStagedEncrypt
 * or WBCryptoStagedDecrypt as many times as you wish, setting the
 * 'final' aergument to CSSM_TRUE only for the last call.
 * Caller does not need to be concerned about buffer or block
 * boundaries.
 */

typedef enum {
  /* for use in WBCryptoStagedEncDecrInit() */
  SO_Encrypt,
  SO_Decrypt,
  /* for use in WBCryptoStagedSignVerifyInit() */
  SO_Sign,
  SO_Verify
} StagedOpType;

WB_EXPORT
CSSM_RETURN WBCryptoStagedEncDecrInit(CSSM_CSP_HANDLE	cspHandle,		// from WBCryptoCspAttach()
                                      const CSSM_KEY		*key,			// from WBCryptoDeriveKey()
                                      StagedOpType		opType,			// SO_Encrypt, SO_Decrypt
                                      CSSM_CC_HANDLE		*ccHandle) WB_DEPRECATED("CDSA is deprecated");		// RETURNED

/*
 * Encrypt.
 * -- cipherText->Data is allocated by the CSP and must be freed (via WBCryptoFree()) by caller.
 * -- plainText and its referent (plainText->Data) are optional on
 *    the final call; either one can be NULL at that time.
 */
WB_EXPORT
CSSM_RETURN WBCryptoStagedEncrypt(CSSM_CC_HANDLE		ccHandle,		// from WBCryptoStagedEncDecrInit()
                                  CSSM_BOOL			final,			// CSSM_TRUE on last call
                                  const CSSM_DATA	*plainText,
                                  CSSM_DATA *cipherText) WB_DEPRECATED("CDSA is deprecated");

/*
 * Decrypt.
 * -- plainText->Data is allocated by the CSP and must be freed (via WBCryptoFree()) by caller.
 * -- cipherText and its referent (cipherText->Data) are optional on
 *    the final call; either one can be NULL at that time.
 */
WB_EXPORT
CSSM_RETURN WBCryptoStagedDecrypt(CSSM_CC_HANDLE		ccHandle,		// from WBCryptoStagedEncDecrInit()
                                  CSSM_BOOL			final,			// CSSM_TRUE on last call
                                  const CSSM_DATA	*cipherText,
                                  CSSM_DATA *plainText) WB_DEPRECATED("CDSA is deprecated");

#pragma mark -
/*!
 @functiongroup Digest
 */
#pragma mark ------ Digest routines ------

/*!
 @function
 @abstract The simple one-shot digest routine, when all of the data to be processed is available at once.
 @param cspHandle From WBCryptoCspAttach()
 @param digestAlg e.g., CSSM_ALGID_SHA1
 @param inData
 @param outDigestData digestData->Data is allocated by the CSP and must be freed (via WBCryptoFree()) by caller.
 @result
 */
WB_EXPORT
CSSM_RETURN WBCryptoDigest(CSSM_CSP_HANDLE		cspHandle,
                           CSSM_ALGORITHMS		digestAlg,
                           const CSSM_DATA		*inData,
                           CSSM_DATA *outDigestData) WB_DEPRECATED("CDSA is deprecated");

/*!
 @function
 @abstract Staged digest routines. For processing multiple chunks of data into one digest. This is called once…
 @param cspHandle From WBCryptoCspAttach()
 @param digestAlg e.g., CSSM_ALGID_SHA1
 @param ccHandle Returned.
 @result
 */
WB_EXPORT
CSSM_RETURN WBCryptoStagedDigestInit(CSSM_CSP_HANDLE	cspHandle,
                                     CSSM_ALGORITHMS	digestAlg,
                                     CSSM_CC_HANDLE		*ccHandle) WB_DEPRECATED("CDSA is deprecated");

/*!
 @function
 @abstract …And this is called an arbitrary number of times, with a value of CSSM_TRUE for the 'final' argument on the last call.
 @param ccHandle From WBCryptoStagedDigestInit()
 @param final CSSM_TRUE on last call
 @param inData inData and its referent (inData->Data) are optional on the final call; either one can be NULL at that time.
 @param digestData Until the final call, the digestData argument is ignored.
 digestData->Data is allocated by the CSP and must be freed (via WBCryptoFree()) by caller.
 @result
 */
WB_EXPORT
CSSM_RETURN WBCryptoStagedDigest(CSSM_CC_HANDLE		ccHandle,
                                 CSSM_BOOL			final,
                                 const CSSM_DATA		*inData,
                                 CSSM_DATA *digestData) WB_DEPRECATED("CDSA is deprecated");

#pragma mark -
/*!
 @functiongroup Simple Sign/Verify
 */
#pragma mark ------ Simple sign/verify ------
/*
 * Generate a digital signature, one-shot version. To be
 * used when all of the data to be signed is available at once.
 * signature->Data is allocated by the CSP and must be freed (via WBCryptoFree()) by caller.
 */
WB_EXPORT
CSSM_RETURN WBCryptoSign(CSSM_CSP_HANDLE	cspHandle,		// from WBCryptoCspAttach()
                         const CSSM_KEY		*key,			// from WBCryptoGenerateKeyPair()
                         CSSM_ALGORITHMS	sigAlg,			// e.g., CSSM_ALGID_SHA1WithRSA
                         const CSSM_DATA		*dataToSign,
                         CSSM_DATA *signature) WB_DEPRECATED("CDSA is deprecated");

/*
 * Verify a digital signature, one-shot version. To be
 * used when all of the data to be verified is available at once.
 */
WB_EXPORT
CSSM_RETURN WBCryptoVerify(CSSM_CSP_HANDLE cspHandle,		// from WBCryptoCspAttach()
                           const CSSM_KEY *key,			// from WBCryptoGenerateKeyPair()
                           CSSM_ALGORITHMS sigAlg,			// e.g., CSSM_ALGID_SHA1WithRSA
                           const CSSM_DATA *dataToSign,
                           const CSSM_DATA *signature) WB_DEPRECATED("CDSA is deprecated");

#pragma mark -
/*!
 @functiongroup Staged Sign/Verify
 */
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
WB_EXPORT
CSSM_RETURN WBCryptoStagedSignVerifyInit(CSSM_CSP_HANDLE	cspHandle,		// from WBCryptoCspAttach()
                                         const CSSM_KEY		*key,			// from WBCryptoDeriveKey()
                                         CSSM_ALGORITHMS	sigAlg,			// e.g., CSSM_ALGID_SHA1WithRSA
                                         StagedOpType		opType,			// SO_Sign, SO_Verify
                                         CSSM_CC_HANDLE		*ccHandle) WB_DEPRECATED("CDSA is deprecated");		// RETURNED

/*
 * Sign.
 * -- The signature argument is non-NULL only on the final call to
 *    this function.
 * -- signature->Data is allocated by the CSP and must be freed (via WBCryptoFree()) by caller.
 * -- dataToSign and its referent (dataToSign->Data) are optional on
 *    the final call; either one can be NULL at that time.
 */
WB_EXPORT
CSSM_RETURN WBCryptoStagedSign(CSSM_CC_HANDLE ccHandle,		// from WBCryptoStagedSignVerifyInit()
                               const CSSM_DATA	*dataToSign,
                               CSSM_DATA *signature) WB_DEPRECATED("CDSA is deprecated");		// non-NULL on final call only

/*
 * Verify.
 * -- The signature argument is non-NULL only on the final call to
 *    this function.
 * -- dataToVerify and its referent (dataToVerify->Data) are optional on
 *    the final call; either one can be NULL at that time.
 */
WB_EXPORT
CSSM_RETURN WBCryptoStagedVerify(CSSM_CC_HANDLE ccHandle,		// from WBCryptoStagedSignVerifyInit()
                                 const CSSM_DATA *dataToVerify,
                                 const CSSM_DATA *signature) WB_DEPRECATED("CDSA is deprecated");	// non-NULL on final call only

#endif	/* __WBCRYPTO_FUNCTIONS_H */
