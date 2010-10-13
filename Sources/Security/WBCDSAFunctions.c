/*
 *  WBCDSAFunctions.c
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#include WBHEADER(WBCDSAFunctions.h)

#include <Security/cssm.h>
#include <Security/cssmapple.h>

/*
 * Standard app-level memory functions required by CDSA.
 */
static
void * appMalloc (CSSM_SIZE size, void *allocRef) {
  return( malloc(size) );
}
static
void appFree (void *mem_ptr, void *allocRef) {
  free(mem_ptr);
  return;
}
static
void * appRealloc (void *ptr, CSSM_SIZE size, void *allocRef) {
  return( realloc( ptr, size ) );
}
static
void * appCalloc (uint32 num, CSSM_SIZE size, void *allocRef) {
  return( calloc( num, size ) );
}

static CSSM_API_MEMORY_FUNCS memFuncs = {
  appMalloc,
  appFree,
  appRealloc,
  appCalloc,
  NULL
};

static CSSM_VERSION vers = {2, 0};
static const CSSM_GUID testGuid = { 0xFADE, 0, 0, { 1,2,3,4,5,6,7,0 }};

/*
 * Init CSSM; returns CSSM_FALSE on error. Reusable.
 */
static
CSSM_BOOL cssmStartup(void) {
  static CSSM_BOOL cssmInitd = CSSM_FALSE;
  CSSM_RETURN  crtn;
  CSSM_PVC_MODE pvcPolicy = CSSM_PVC_NONE;

  if(cssmInitd) {
    return CSSM_TRUE;
  }
  crtn = CSSM_Init (&vers,
                    CSSM_PRIVILEGE_SCOPE_NONE,
                    &testGuid,
                    CSSM_KEY_HIERARCHY_NONE,
                    &pvcPolicy,
                    NULL /* reserved */);
  if(crtn != CSSM_OK) {
    WBCDSAPrintError("CSSM_Init", crtn);
    return CSSM_FALSE;
  } else {
    cssmInitd = CSSM_TRUE;
    return CSSM_TRUE;
  }
}

/*
 * Init CSSM and establish a session with the Apple TP.
 */
CSSM_RETURN WBCDSAStartupModule(const CSSM_GUID *guid, CSSM_SERVICE_TYPE service, CSSM_MODULE_HANDLE *handle) {
  CSSM_RETURN crtn;
  if (!handle) return paramErr;

  if(cssmStartup() == CSSM_FALSE) {
    return -1;
  }
  crtn = CSSM_ModuleLoad(guid,
                         CSSM_KEY_HIERARCHY_NONE,
                         NULL,      // eventHandler
                         NULL);     // AppNotifyCallbackCtx
  if(crtn) {
    return crtn;
  }
  crtn = CSSM_ModuleAttach(guid,
                           &vers,
                           &memFuncs,    // memFuncs
                           0,            // SubserviceID
                           service,      // SubserviceFlags
                           0,            // AttachFlags
                           CSSM_KEY_HIERARCHY_NONE,
                           NULL,         // FunctionTable
                           0,            // NumFuncTable
                           NULL,         // reserved
                           handle);
  return crtn;
}

CSSM_RETURN WBCDSAShutdownModule(CSSM_MODULE_HANDLE handle) {
  CSSM_GUID guid;
  CSSM_RETURN crtn = CSSM_GetModuleGUIDFromHandle(handle, &guid);

  if (CSSM_OK != crtn)
    return crtn;

  crtn = CSSM_ModuleDetach(handle);
  if(CSSM_OK != crtn) {
    return crtn;
  }
  crtn = CSSM_ModuleUnload(&guid, NULL, NULL);
  return crtn;
}

#pragma mark Memory
void *WBCDSAMalloc(CSSM_MODULE_HANDLE handle, CSSM_SIZE size) {
  if (handle) {
    CSSM_API_MEMORY_FUNCS funcs;
    if (CSSM_OK == CSSM_GetAPIMemoryFunctions(handle, &funcs)) {
      return funcs.malloc_func ? funcs.malloc_func(size, funcs.AllocRef) : NULL;
    }
  } else {
    return appMalloc(size, NULL);
  }
  return NULL;
}

void *WBCDSACalloc(CSSM_MODULE_HANDLE handle, uint32 count, CSSM_SIZE size) {
  if (handle) {
    CSSM_API_MEMORY_FUNCS funcs;
    if (CSSM_OK == CSSM_GetAPIMemoryFunctions(handle, &funcs)) {
      return funcs.calloc_func ? funcs.calloc_func(count, size, funcs.AllocRef) : NULL;
    }
  } else {
    return appCalloc(count, size, NULL);
  }
  return NULL;
}

void *WBCDSARealloc(CSSM_MODULE_HANDLE handle, void *ptr, CSSM_SIZE size) {
  if (handle) {
    CSSM_API_MEMORY_FUNCS funcs;
    if (CSSM_OK == CSSM_GetAPIMemoryFunctions(handle, &funcs)) {
      return funcs.realloc_func ? funcs.realloc_func(ptr, size, funcs.AllocRef) : NULL;
    }
  } else {
    return appRealloc(ptr, size, NULL);
  }
  return NULL;
}

void WBCDSAFree(CSSM_MODULE_HANDLE handle, void *ptr) {
  if (handle) {
    CSSM_API_MEMORY_FUNCS funcs;
    if (CSSM_OK == CSSM_GetAPIMemoryFunctions(handle, &funcs)) {
      if (funcs.free_func) funcs.free_func(ptr, funcs.AllocRef);
    }
  } else {
    appFree(ptr, NULL);
  }
}

CSSM_BOOL WBCDSADataEqual(const CSSM_DATA *d1, const CSSM_DATA *d2) {
  if(d1->Length != d2->Length) {
    return CSSM_FALSE;
  }
  if (!d1->Data) return !d2->Data ? CSSM_TRUE : CSSM_FALSE;
  if (!d2->Data) return CSSM_FALSE;
  if(memcmp(d1->Data, d2->Data, d1->Length)) {
    return CSSM_FALSE;
  }
  return CSSM_TRUE;
}

#pragma mark -
/*
 * Cook up a symmetric encryption context for the specified key,
 * inferring all needed attributes solely from the key algorithm.
 * This is obviously not a one-size-fits all function, but rather
 * the "most common case". If you need to encrypt/decrypt with other
 * padding, mode, etc., do it yourself.
 */
CSSM_RETURN WBCDSACreateCryptContext(CSSM_CSP_HANDLE cspHandle, const CSSM_KEY *key, const CSSM_DATA *ivPtr, CSSM_CC_HANDLE *ccHandle) {
  CSSM_ALGORITHMS keyAlg = key->KeyHeader.AlgorithmId;
  CSSM_ALGORITHMS encrAlg;
  CSSM_ENCRYPT_MODE encrMode = CSSM_ALGMODE_NONE;
  CSSM_PADDING encrPad = CSSM_PADDING_NONE;
  CSSM_RETURN crtn;
  CSSM_CC_HANDLE ccHand = 0;
  CSSM_ACCESS_CREDENTIALS creds;
  CSSM_BOOL isSymmetric = CSSM_TRUE;

  /*
    * Infer algorithm - ususally it's the same as in the key itself
   */
  switch(keyAlg) {
    case CSSM_ALGID_3DES_3KEY:
      encrAlg = CSSM_ALGID_3DES_3KEY_EDE;
      break;
    default:
      encrAlg = keyAlg;
      break;
  }

  /* infer mode and padding */
  switch(encrAlg) {
    /* 8-byte block ciphers */
    case CSSM_ALGID_DES:
    case CSSM_ALGID_3DES_3KEY_EDE:
    case CSSM_ALGID_RC5:
    case CSSM_ALGID_RC2:
      encrMode = CSSM_ALGMODE_CBCPadIV8;
      encrPad = CSSM_PADDING_PKCS5;
      break;

      /* 16-byte block ciphers */
    case CSSM_ALGID_AES:
      encrMode = CSSM_ALGMODE_CBCPadIV8;
      encrPad = CSSM_PADDING_PKCS7;
      break;

      /* stream ciphers */
    case CSSM_ALGID_ASC:
    case CSSM_ALGID_RC4:
      encrMode = CSSM_ALGMODE_NONE;
      encrPad = CSSM_PADDING_NONE;
      break;

      /* RSA asymmetric */
    case CSSM_ALGID_RSA:
      /* encrMode not used */
      encrPad = CSSM_PADDING_PKCS1;
      //      isSymmetric = CSSM_FALSE;
      break;
    default:
      /* don't wing it - abort */
      return CSSMERR_CSP_INTERNAL_ERROR;
  }
  /* if public or private key, we guess it is not symmetric */
  if (key->KeyHeader.KeyClass == CSSM_KEYCLASS_PUBLIC_KEY ||
      key->KeyHeader.KeyClass == CSSM_KEYCLASS_PRIVATE_KEY)
    isSymmetric = CSSM_FALSE;

  memset(&creds, 0, sizeof(CSSM_ACCESS_CREDENTIALS));
  if(isSymmetric) {
    crtn = CSSM_CSP_CreateSymmetricContext(cspHandle,
                                           encrAlg,
                                           encrMode,
                                           NULL,      // access cred
                                           key,
                                           ivPtr,     // InitVector
                                           encrPad,
                                           NULL,      // Params
                                           &ccHand);
  } else {
    crtn = CSSM_CSP_CreateAsymmetricContext(cspHandle,
                                            encrAlg,
                                            &creds,    // access
                                            key,
                                            encrPad,
                                            &ccHand);

  }
  if(crtn) {
    return crtn;
  }
  *ccHandle = ccHand;
  return CSSM_OK;
}

#pragma mark -
extern const char *cssmErrorString(CSSM_RETURN error); // private API

void WBCDSAPrintError(const char *op, CSSM_RETURN err) { cssmPerror(op, err); }
const char *WBCDSAGetErrorString(CSSM_RETURN error) { return cssmErrorString(error); }
CFStringRef WBCDSACopyErrorMessageString(OSStatus status) { return SecCopyErrorMessageString(status, NULL); }
