/*
 *  WBTextFunction.c
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

#include WBHEADER(WBTextFunctions.h)

CFIndex WBTextGetCountOfLines(CFStringRef str) {
	CFIndex lines = 0;
	
	CFIndex stringLength = CFStringGetLength(str);
	for (CFIndex idx = 0; idx < stringLength; lines++)
		CFStringGetLineBounds(str, CFRangeMake(idx, 0), NULL, &idx, NULL);
	
	return lines;
}

CFIndex WBTextConvertLineEnding(CFMutableStringRef str, CFStringRef endOfLine) {
  CFIndex position = 0, idx = 0, count = 0;
  
  CFIndex eol = CFStringGetLength(endOfLine);
  CFIndex length = CFStringGetLength(str);
  
  UniChar ch;
  CFStringInlineBuffer buffer;
  CFStringInitInlineBuffer(str, &buffer, CFRangeMake(0, length));
  
  while (ch = CFStringGetCharacterFromInlineBuffer(&buffer, idx)) {
    CFRange range = CFRangeMake(kCFNotFound, 0);
    if (kWBCarriageReturnCharacter == ch) {
      range.length = 1;
      range.location = idx;
      ch = CFStringGetCharacterFromInlineBuffer(&buffer, idx + 1);
      if (kWBNewlineCharacter == ch) {
        idx++;
        range.length = 2;
      }
    } else if (kWBNewlineCharacter == ch || kWBLineSeparatorCharacter == ch || kWBParagraphSeparatorCharacter == ch) {
      range.length = 1;
      range.location = idx;
    }
    idx++;
    if (range.location != kCFNotFound) {
      count++;
      range.location += position;
      CFIndex delta = eol - range.length;
      CFStringReplace(str, range, endOfLine);
      if (delta != 0) {
        idx += delta;
        length += delta;
        position += idx;
        CFStringInitInlineBuffer(str, &buffer, CFRangeMake(position, length - position));
        idx = 0;
      }
    }
  }
  return count;
}

