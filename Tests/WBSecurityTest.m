//
//  WBSecurityTest.m
//  WonderBox
//
//  Created by Jean-Daniel on 29/06/2015.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>

#import <WonderBox/WBSecurityFunctions.h>
#import <WonderBox/WBDigestFunctions.h>

@interface WBSecurityTest : XCTestCase

@end

@implementation WBSecurityTest {
  SecKeychainRef _keychain;
  SecKeyRef _pubKey, _privKey;
}

WB_INLINE
void _XCTAssertNoErr(id self, OSStatus err, NSString *msg) {
  if (noErr != err) {
    CFStringRef str = SecCopyErrorMessageString(err, NULL);
    if (str) {
      XCTFail(@"%@: %@", msg, str);
    } else {
      XCTFail(@"%@: error %d", msg, err);
    }
  }
}

- (void)setUp {
  [super setUp];
  NSURL *url = [[NSBundle bundleForClass:WBSecurityTest.class] URLForResource:@"WBTests" withExtension:@"keychain"];
  OSStatus err = SecKeychainOpen([url fileSystemRepresentation], &_keychain);
  _XCTAssertNoErr(self, err, @"SecKeychainOpen");

  err = SecKeychainUnlock(_keychain, 4, "test", true);
  _XCTAssertNoErr(self, err, @"SecKeychainUnlock");

  NSDictionary *query = @{
                          (id)kSecMatchSearchList: @[(id)_keychain],
                          (id)kSecClass: (id)kSecClassKey,
                          (id)kSecReturnRef: @YES,
                          (id)kSecMatchLimit: (id)kSecMatchLimitOne,
                          (id)kSecAttrKeyType: (id)kSecAttrKeyTypeRSA,
                          (id)kSecAttrKeyClass: (id)kSecAttrKeyClassPrivate,
                          };
  err = SecItemCopyMatching(SPXNSToCFDictionary(query), (CFTypeRef *)&_privKey);
  _XCTAssertNoErr(self, err, @"SecItemCopyMatching(RSA private)");

  query = @{
            (id)kSecMatchSearchList: @[(id)_keychain],
            (id)kSecClass: (id)kSecClassKey,
            (id)kSecReturnRef: @YES,
            (id)kSecMatchLimit: (id)kSecMatchLimitOne,
            (id)kSecAttrKeyType: (id)kSecAttrKeyTypeRSA,
            (id)kSecAttrKeyClass: (id)kSecAttrKeyClassPublic,
            };
  err = SecItemCopyMatching(SPXNSToCFDictionary(query), (CFTypeRef *)&_pubKey);
  _XCTAssertNoErr(self, err, @"SecItemCopyMatching(RSA public)");
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
  SPXCFRelease(_pubKey);
  SPXCFRelease(_privKey);
  SPXCFRelease(_keychain);
  [super tearDown];
}

- (void)testSignVerifyData {
  uint8_t bytes[4096];
  SecRandomCopyBytes(kSecRandomDefault, 4096, bytes);
  CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, bytes, 4096, kCFAllocatorNull);

  CFErrorRef error;
  CFDataRef signature = WBSecuritySignData(data, _privKey, kSecDigestSHA2, 512, &error);
  XCTAssertNotNil(SPXCFToNSData(signature));

  CFBooleanRef result = WBSecurityVerifySignature(data, signature, _pubKey, kSecDigestSHA2, 512, &error);
  XCTAssertNotNil(SPXCFToNSType(result));
  if (result)
    XCTAssertTrue(CFBooleanGetValue(result));

  // Test by computing the digest ourself and passing it to the verifier instead of passing the raw data.
  uint8_t digest[WB_SHA512_DIGEST_LENGTH];
  WBDigestData(CFDataGetBytePtr(data), CFDataGetLength(data), kWBDigestSHA512, digest);

  data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, digest, WB_SHA512_DIGEST_LENGTH, kCFAllocatorNull);
  result = WBSecurityVerifyDigestSignature(data, signature, _pubKey, kSecDigestSHA2, 512, &error);
  XCTAssertNotNil(SPXCFToNSType(result));
  if (result)
    XCTAssertTrue(CFBooleanGetValue(result));
}

- (void)testSignVerifyFile {
  CFURLRef file = CFBundleCopyExecutableURL(CFBundleGetMainBundle());

  CFErrorRef error;
  CFDataRef signature = WBSecuritySignFile(file, _privKey, kSecDigestSHA2, 512, &error);
  XCTAssertNotNil(SPXCFToNSData(signature));

  CFBooleanRef result = WBSecurityVerifyFileSignature(file, signature, _pubKey, kSecDigestSHA2, 512, &error);
  XCTAssertNotNil(SPXCFToNSType(result));
  if (result)
    XCTAssertTrue(CFBooleanGetValue(result));

  // Test by computing the digest ourself and passing it to the verifier instead of passing the raw data.
  uint8_t digest[WB_SHA512_DIGEST_LENGTH];
  WBDigestFile([SPXCFToNSURL(file) fileSystemRepresentation], kWBDigestSHA512, digest);

  CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, digest, WB_SHA512_DIGEST_LENGTH, kCFAllocatorNull);
  result = WBSecurityVerifyDigestSignature(data, signature, _pubKey, kSecDigestSHA2, 512, &error);
  XCTAssertNotNil(SPXCFToNSType(result));
  if (result)
    XCTAssertTrue(CFBooleanGetValue(result));
}

@end
