/*
 *  WBTextFunction.h
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

#if !defined(__WBTEXTFUNCTIONS_H)
#define __WBTEXTFUNCTIONS_H 1

enum {
  kWBParagraphSeparatorCharacter = 0x2029,
  kWBLineSeparatorCharacter = 0x2028,
  kWBTabCharacter = 0x0009,
  kWBFormFeedCharacter = 0x000c,
  kWBNewlineCharacter = 0x000a,
  kWBCarriageReturnCharacter = 0x000d,
  kWBEnterCharacter = 0x0003,
  kWBBackspaceCharacter = 0x0008,
  kWBBackTabCharacter = 0x0019,
  kWBDeleteCharacter = 0x007f
};

WB_EXPORT
CFIndex WBTextGetCountOfLines(CFStringRef str);

WB_EXPORT
CFIndex WBTextConvertLineEnding(CFMutableStringRef str, CFStringRef endOfLine);

#endif /* __WBTEXTFUNCTIONS_H */
