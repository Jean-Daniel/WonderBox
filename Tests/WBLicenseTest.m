//
//  WBLicenseTest.m
//  WonderBox
//
//  Created by Jean-Daniel Dupas on 13/02/08.
//  Copyright 2008 Ninsight. All rights reserved.
//

#import "WBLicenseTest.h"

#import WBHEADER(WBLicenseCrypto.h)

#undef I
#include <openssl/evp.h>

@implementation WBLicenseTest

- (void)testPBKDF {
	char wonder[16], open[16];
	WBPKCS5_PBKDF2_HMAC_SHA1("Youpi", 5, "salt for sally", 14, 1500, 16, wonder);
	PKCS5_PBKDF2_HMAC_SHA1("Youpi", 5, "salt for sally", 14, 1500, 16, open);
	STAssertTrue(0 == memcmp(wonder, open, 16), @"non conform PBKDF function");
}

@end
