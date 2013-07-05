/*
 *  WBDigestFunctions.c
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#include <WonderBox/WBDigestFunctions.h>

#include <CommonCrypto/CommonDigest.h>
#include <unistd.h>

typedef struct _WBDigestInfo {
  uint8_t algo;
  uint8_t length;
  const char *name;
  /* functions */
  int (*init)(void *c);
  int (*update)(void *c, const void *data, CC_LONG len);
  int (*final)(unsigned char *md, void *c);
} WBDigestInfo;

typedef struct _WBPrivateDigestContext {
  const WBDigestInfo *digest;
  union {
    CC_MD2_CTX md2;
    CC_MD4_CTX md4;
    CC_MD5_CTX md5;
    CC_SHA1_CTX sha1;
    CC_SHA256_CTX sha256; // 224 & 256
    CC_SHA512_CTX sha512; // 384 & 512
  } ctxt;
} WBPrivateDigestContext;

#define DEFINE_DIGEST_INFO(str, algorithm) { \
  .algo = kWBDigest##algorithm, \
  .length = CC_##algorithm##_DIGEST_LENGTH, \
  .name = str, \
  .init = (int (*)(void *))CC_##algorithm##_Init, \
  .update = (int (*)(void *, const void *, CC_LONG))CC_##algorithm##_Update, \
  .final = (int (*)(unsigned char *, void *))CC_##algorithm##_Final \
}
static const WBDigestInfo _WBDigestInfos[] = {
  /* MD2 */
  DEFINE_DIGEST_INFO("md2", MD2),
  /* MD4 */
  DEFINE_DIGEST_INFO("md4", MD4),
  /* MD5 */
  DEFINE_DIGEST_INFO("md5", MD5),
  /* SHA1 */
  DEFINE_DIGEST_INFO("sha1", SHA1),
  /* SHA224 */
  DEFINE_DIGEST_INFO("sha224", SHA224),
  /* SHA256 */
  DEFINE_DIGEST_INFO("sha256", SHA256),
  /* SHA 384 */
  DEFINE_DIGEST_INFO("sha384", SHA384),
  /* SHA 512 */
  DEFINE_DIGEST_INFO("sha512", SHA512),
  /* Sentinel */
  { kWBDigestUndefined, 0, NULL, NULL, NULL, NULL }
};

WB_INLINE
const WBDigestInfo *__WBDigestInfoForAlgoritm(WBDigestAlgorithm algo) {
  const WBDigestInfo *digest = _WBDigestInfos;
  while (digest->algo && digest->algo != algo) {
    digest++;
  }
  return digest->algo ? digest : NULL;
}

// MARK: -
// MARK: Algorithms
size_t WBDigestGetOutputSize(WBDigestAlgorithm algo) {
  const WBDigestInfo *digest = __WBDigestInfoForAlgoritm(algo);
  return digest ? digest->length : 0;
}

WBDigestAlgorithm WBDigestGetAlgorithmByName(const char *name) {
  const WBDigestInfo *digest = _WBDigestInfos;
  while ((kWBDigestUndefined != digest->algo) && (0 != strcasecmp(name, digest->name))) {
    digest++;
  }
  return digest->algo;
}

// MARK: Digest
int WBDigestInit(WBDigestAlgorithm algo, WBDigestRef c) {
  static_assert(sizeof(*c) >= sizeof(WBPrivateDigestContext), "inconsistent declaration");
  WBPrivateDigestContext *ctxt = (WBPrivateDigestContext *)c;
  memset(ctxt, 0, sizeof(*ctxt));
  ctxt->digest = __WBDigestInfoForAlgoritm(algo);
  if (!ctxt->digest) return 0; // error ?

  return ctxt->digest->init(&ctxt->ctxt);
}

int WBDigestUpdate(WBDigestRef c, const void *data, size_t len) {
  WBPrivateDigestContext *ctxt = (WBPrivateDigestContext *)c;
  if (!ctxt->digest) return 0; // error ?
  assert(len < UINT32_MAX && "integer overflow");
  return ctxt->digest->update(&ctxt->ctxt, data, (CC_LONG)len);
}

int WBDigestFinal(WBDigestRef c, uint8_t *md) {
  WBPrivateDigestContext *ctxt = (WBPrivateDigestContext *)c;
  if (!ctxt->digest) return 0; // error ?
  int err = ctxt->digest->final(md, &ctxt->ctxt);
  return err > 0 ? ctxt->digest->length : 0;
}

// MARK: Context
size_t WBDigestGetOutputSizeFromRef(WBDigestRef c) {
  WBPrivateDigestContext *ctxt = (WBPrivateDigestContext *)c;
  if (!ctxt->digest) return 0;
  return ctxt->digest->length;
}

const char *WBDigestGetAlgorithmNameFromRef(WBDigestRef c) {
  WBPrivateDigestContext *ctxt = (WBPrivateDigestContext *)c;
  if (!ctxt->digest) return NULL;
  return ctxt->digest->name;
}

WBDigestAlgorithm WBDigestGetAlgorithmFromRef(WBDigestRef c) {
  WBPrivateDigestContext *ctxt = (WBPrivateDigestContext *)c;
  if (!ctxt->digest) return 0;
  return ctxt->digest->algo;
}

// MARK: Utilities
int WBDigestData(const void *data, size_t length, WBDigestAlgorithm algo, unsigned char *md) {
  WBDigestContext ctxt;
  int err = WBDigestInit(&ctxt, algo);
  if (err > 0) {
    err = WBDigestUpdate(&ctxt, data, length);
    if (err > 0) {
      err = WBDigestFinal(&ctxt, md);
    } else {
      /* cleanup context */
      memset(&ctxt, 0, sizeof(ctxt));
    }
  }

  return err;
}

int WBDigestFile(const char *path, WBDigestAlgorithm algo, unsigned char *md) {
  int fd = open(path, O_RDONLY);
  if (fd <= 0) return -1;
  /* disable file system caching */
  fcntl(fd, F_NOCACHE, 0);

  WBDigestContext ctxt;
  int err = WBDigestInit(&ctxt, algo);
  if (err > 0) {
    /* must be 4k align because caching is disabled */
    char *buffer = malloc(32 * 1024);
    if (!buffer) {
      err = -1; // memFullErr
    } else {
      ssize_t count = 0;
      while (err > 0 && (count = read(fd, buffer, 32 * 1024)) > 0) {
        err = WBDigestUpdate(&ctxt, buffer, count);
      }
      if (count < 0)
        err = -1; // CSSM_ERRCODE_FUNCTION_FAILED;
      free(buffer);
    }

    if (err > 0) {
      err = WBDigestFinal(&ctxt, md);
    } else {
      /* cleanup context */
      memset(&ctxt, 0, sizeof(ctxt));
    }
  }
  close(fd);

  return err;
}

