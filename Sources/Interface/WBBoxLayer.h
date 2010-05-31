/*
 *  WBBoxLayer.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

enum {
  kWBStringLayerAlignmentLeft   = 1,
  kWBStringLayerAlignmentCenter,
  kWBStringLayerAlignmentRight,
  /* vertical */
  kWBStringLayerAlignmentTop    = kWBStringLayerAlignmentLeft,
  kWBStringLayerAlignmentMiddle = kWBStringLayerAlignmentCenter,
  kWBStringLayerAlignmentBottom = kWBStringLayerAlignmentRight,
};

WB_CLASS_EXPORT
@interface WBBoxLayer : NSObject {
@private
  NSSize wb_size; // layer size.
  NSSize wb_csize; // canvas size.
  NSSize wb_content; // content size.

  /* Box */
  NSRect wb_box;
  NSSize wb_padding;

  CGFloat wb_bwidth; // border width
  CGFloat wb_radius; // corner radius

  NSColor *wb_border; // default transparent or none
  NSColor *wb_background; // default transparent or none

  struct _wb_slFlags {
    unsigned int dirty:1;
    /* box alignment */
    unsigned int box_right:1;
    unsigned int box_bottom:1;
    unsigned int box_content:1; // defined content size

    unsigned int cnt_halign:2;
    unsigned int cnt_valign:2;
  } wb_blFlags;
}

- (id)initWithSize:(NSSize)aSize;

- (NSSize)size;
- (void)setSize:(NSSize)aSize;

- (void)drawAtPoint:(NSPoint)aPoint;
// aContext MUST be flipped.
- (void)drawAtPoint:(NSPoint)aPoint context:(CGContextRef)aContext;

- (NSRect)bounds:(BOOL)isFlipped;

#pragma mark Box Settings
- (NSSize)padding;
- (void)setPadding:(NSSize)aPadding;

- (CGFloat)borderWidth;
- (void)setBorderWidth:(CGFloat)aWidth;

- (NSSize)boxSize;
- (void)setBoxSize:(NSSize)aSize;

- (NSPoint)boxPosition;
- (void)setBoxPosition:(NSPoint)aPosition;

- (NSUInteger)boxVerticalAlignment;
- (void)setBoxVerticalAlignment:(NSUInteger)theAlignment;

- (NSUInteger)boxHorizontalAlignment;
- (void)setBoxHorizontalAlignment:(NSUInteger)theAlignment;

#pragma mark Content
/* content size and box size are dependents */
- (NSSize)contentSize;
- (void)setContentSize:(NSSize)aSize;

- (NSUInteger)contentVerticalAlignment;
- (void)setContentVerticalAlignment:(NSUInteger)theAlignment;

- (NSUInteger)contentHorizontalAlignment;
- (void)setContentHorizontalAlignment:(NSUInteger)theAlignment;

#pragma mark Appareance
- (CGFloat)cornerRadius;
- (void)setCornerRadius:(CGFloat)aRadius;

- (NSColor *)borderColor;
- (void)setBorderColor:(NSColor *)color;

- (NSColor *)backgroundColor;
- (void)setBackgroundColor:(NSColor *)color;

/* protected */
- (void)didUpdate; // to be overriden

- (NSSize)drawingSizeForSize:(NSSize)bounds;

- (void)drawContentInRect:(NSRect)aRect;

- (BOOL)needsUpdate;
- (void)setNeedsUpdate:(BOOL)update;

@end
