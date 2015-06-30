//
//  WBSecurityCreateKeychain.m
//  WonderBox
//
//  Created by Jean-Daniel on 29/06/2015.
//
//

#import <Foundation/Foundation.h>
#import <Security/Security.h>
#import <os/trace.h>

static
void _XCTAssertNoErr(OSStatus err, NSString *msg) {
  if (noErr != err) {
    CFStringRef str = SecCopyErrorMessageString(err, NULL);
    if (str) {
      // os_trace(@"%@: %@", msg, str);
    } else {
      //XCTFail(@"%@: error %d", msg, err);
    }
    exit(1);
  }
}

int main(int argc, char **argv) {
  if (argc < 2)
    return 1;

  NSURL *path = [[NSURL alloc] initFileURLWithFileSystemRepresentation:argv[1] isDirectory:NO relativeToURL:nil];

  SecKeychainRef keychain;
  OSStatus err = SecKeychainCreate([path fileSystemRepresentation], 4, "test", false, NULL, &keychain);
  if (noErr != err) {
    return 1;
  }
  _XCTAssertNoErr(err, @"create temporary keychain");

  NSDictionary *attrs = @{
    (__bridge id)kSecUseKeychain: (__bridge id)keychain,
    (__bridge id)kSecAttrLabel: @"key RSA",
    (__bridge id)kSecAttrKeyType: (__bridge id)kSecAttrKeyTypeRSA,
    (__bridge id)kSecAttrKeySizeInBits: @4096
  };
  SecKeyGeneratePairAsync(SPXNSToCFDictionary(attrs), dispatch_get_main_queue(), ^(SecKeyRef publicKey, SecKeyRef privateKey, CFErrorRef error) {
    if (error) {
      CFShow(error);
      CFRelease(error);
    } else {
      CFRelease(privateKey);
      CFRelease(publicKey);
      printf("RSA Key generated\n");
    }
  });

  attrs = @{
    (__bridge id)kSecUseKeychain: (__bridge id)keychain,
    (__bridge id)kSecAttrLabel: @"key EC",
    (__bridge id)kSecAttrKeyType: (__bridge id)kSecAttrKeyTypeEC,
    (__bridge id)kSecAttrKeySizeInBits: @521
  };
  SecKeyGeneratePairAsync(SPXNSToCFDictionary(attrs), dispatch_get_main_queue(), ^(SecKeyRef publicKey, SecKeyRef privateKey, CFErrorRef error) {
    if (error) {
      CFShow(error);
      CFRelease(error);
    } else {
      CFRelease(privateKey);
      CFRelease(publicKey);
      printf("EC Key generated\n");
    }
  });

  dispatch_main();
  return 0;
}
