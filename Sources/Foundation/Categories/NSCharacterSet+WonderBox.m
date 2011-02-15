/*
 *  NSCharacterSet+WonderBox.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(NSCharacterSet+WonderBox.h)

#import WBHEADER(WBFunctions.h)

@implementation NSCharacterSet (NewLineCharacterSet)

#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_5
CFCharacterSetRef WBCharacterSetGetNewLine(void) {
	if ((WBSystemMajorVersion() == 10 && WBSystemMinorVersion() >= 5) || WBSystemMajorVersion() > 10) {
		return CFCharacterSetGetPredefined(kCFCharacterSetNewline);
	} else {
		static CFCharacterSetRef charset = nil;
		if (!charset) {
			UniChar chars[] = {0x000A, 0x000B, 0x000C, 0x000D, 0x0085, 0x2028, 0x2029};
			CFStringRef string = CFStringCreateWithCharacters(kCFAllocatorDefault, chars, 7);
			WBCAssert(string != nil, "Unable to create new line string.");
			charset = CFCharacterSetCreateWithCharactersInString(kCFAllocatorDefault, string);
			CFRelease(string);
		}
		return charset;
	}
}

+ (id)newlineCharacterSet {
  return (NSCharacterSet *)WBCharacterSetGetNewLine();
}
#else
/* @deprecated */
CFCharacterSetRef WBCharacterSetGetNewLine(void) {
	return CFCharacterSetGetPredefined(kCFCharacterSetNewline);
}
#endif
@end
