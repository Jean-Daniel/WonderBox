/*
 *  WBBackgroundView.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBBase.h)

WB_OBJC_EXPORT
@interface WBBackgroundView : NSView {
  @private
  NSColor *wb_bgcolor;
}

- (NSColor *)backgroundColor;
- (void)setBackgroundColor:(NSColor *)bgColor;

@end
