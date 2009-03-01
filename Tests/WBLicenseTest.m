/*
 *  WBLicenseTest.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import "WBLicenseTest.h"

#import WBHEADER(WBLicenseCrypto.h)

#undef I
#include <openssl/evp.h>

@implementation WBLicenseTest

- (void)testPBKDF {
	char wonder[16], open[16];
	WBPKCS5_PBKDF2_HMAC_SHA1("Youpi", 5, "salt for sally", 14, 1500, 16, wonder);
	PKCS5_PBKDF2_HMAC_SHA1("Youpi", 5, "salt for sally", 14, 1500, 16, open);
	GHAssertTrue(0 == memcmp(wonder, open, 16), @"non conform PBKDF function");
}

@end
