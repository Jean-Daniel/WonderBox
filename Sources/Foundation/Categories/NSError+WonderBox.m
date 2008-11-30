/*
 *  WBExtensions.h
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

#import WBHEADER(NSError+WonderBox.h)

@implementation NSError (WBExtensions)

+ (id)fileErrorWithCode:(NSInteger)code path:(NSString *)aPath {
  NSDictionary *info = nil;
  if (aPath)
    info = [NSDictionary dictionaryWithObject:aPath forKey:NSFilePathErrorKey];
  return [self errorWithDomain:NSCocoaErrorDomain code:code userInfo:info];
}

+ (id)fileErrorWithCode:(NSInteger)code url:(NSURL *)anURL {
  NSDictionary *info = nil;
  if (anURL)
    info = [NSDictionary dictionaryWithObject:anURL forKey:NSURLErrorKey];
  return [self errorWithDomain:NSCocoaErrorDomain code:code userInfo:info];
}

- (BOOL)isCancel {
  /* Cocoa */
  if ([[self domain] isEqualToString:NSCocoaErrorDomain] && [self code] == NSUserCancelledError)
    return YES;
  /* Carbon */
  if ([[self domain] isEqualToString:NSOSStatusErrorDomain] && [self code] == userCanceledErr)
    return YES;
  /* Posix */
  if ([[self domain] isEqualToString:NSPOSIXErrorDomain] && [self code] == ECANCELED)
    return YES;
  /* Mach */
	//  if ([[self domain] isEqualToString:NSMachErrorDomain] && [self code] == KERN_ABORTED)
	//    return YES;
  return NO;
}

@end
