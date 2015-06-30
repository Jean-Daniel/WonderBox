/*
 *  WBSplitview.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBBase.h>

#import <Cocoa/Cocoa.h>

enum {
  kWBBorderLeft = 1 << 0,
  kWBBorderTop = 1 << 1,
  kWBBorderRight = 1 << 2,
  kWBBorderBottom = 1 << 3,
};

WB_OBJC_EXPORT
@interface WBSplitView : NSSplitView {
@private
  CGFloat wb_thickness;
  struct _wb_svFlags {
    unsigned int gray:1;
    unsigned int border:4;
    unsigned int reserved:27;
  } wb_svFlags;
}

- (BOOL)isGray;
- (void)setGray:(BOOL)flag;

- (void)setBorders:(NSUInteger)mask;

- (CGFloat)defaultDividerThickness;

- (CGFloat)dividerThickness;
- (void)setDividerThickness:(CGFloat)thickness;

@end
