/*
 *  WBTextFieldCell.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBBase.h>

#import <Cocoa/Cocoa.h>

WB_OBJC_EXPORT
@interface WBTextFieldCell : NSTextFieldCell <NSCopying, NSCoding> {
@private
  struct {
    unsigned int line:1;
    unsigned int middle:1;
    unsigned int noHighlight:1;
    unsigned int reserved:29;
  } wb_tfFlags;
}

+ (id)cell;

- (BOOL)drawsLineOver;
- (void)setDrawsLineOver:(BOOL)flag;

- (BOOL)centersVertically;
- (void)setCentersVertically:(BOOL)flag;

- (BOOL)isHighlightingEnabled;
- (void)setHighlightingEnabled:(BOOL)flag;

// Method used to adjust text drawing area.
- (NSRect)contentRectForBounds:(NSRect)bounds;

@end
