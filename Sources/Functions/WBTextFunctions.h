/*
 *  WBTextFunction.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#if !defined(__WB_TEXT_FUNCTIONS_H)
#define __WB_TEXT_FUNCTIONS_H 1

__BEGIN_DECLS

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

__END_DECLS

#endif /* __WB_TEXT_FUNCTIONS_H */
