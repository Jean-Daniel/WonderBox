/*
 *  WBBoxLayer.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBBoxLayer.h>

#import <WonderBox/WBCGFunctions.h>

#pragma mark -
@implementation WBBoxLayer

- (id)init {
  return [self initWithSize:NSZeroSize];
}

- (id)initWithSize:(NSSize)aSize {
  if (self = [super init]) {
    wb_bwidth = 1;
    wb_radius = 4;
    [self setSize:aSize];
    wb_padding = NSMakeSize(4, 2);
    [self setContentSize:NSZeroSize]; // fit to content
    [self setBoxPosition:NSZeroPoint]; // top / left
  }
  return self;
}

- (void)dealloc {
  spx_release(wb_background);
  spx_release(wb_border);
  [super dealloc];
}

#pragma mark -
- (CGFloat)cornerRadius {
  return wb_radius;
}
- (void)setCornerRadius:(CGFloat)aRadius {
  wb_radius = aRadius;
}

- (NSColor *)borderColor {
  return wb_border;
}
- (void)setBorderColor:(NSColor *)color {
  SPXSetterRetain(wb_border, color);
}

- (NSColor *)backgroundColor {
  return wb_background;
}
- (void)setBackgroundColor:(NSColor *)color {
  SPXSetterRetain(wb_background, color);
}

#pragma mark Sizing
- (NSSize)padding {
  return wb_padding;
}
- (void)setPadding:(NSSize)aPadding {
  if (!NSEqualSizes(aPadding, wb_padding)) {
    wb_padding = aPadding;
    [self setNeedsUpdate:YES];
  }
}

- (CGFloat)borderWidth {
  return wb_bwidth;
}
- (void)setBorderWidth:(CGFloat)aWidth {
  if (fnotequal(aWidth, wb_bwidth)) {
    wb_bwidth = aWidth;
    [self setNeedsUpdate:YES];
  }
}

#pragma mark -
- (NSSize)wb_boxSizeForContentSize:(NSSize)cntSize {
  NSSize size = NSZeroSize;

  /* width */
  if (fiszero(wb_box.size.width)) { // fit to content
    size.width = cntSize.width + 2 * (wb_bwidth + wb_padding.width);
  } else {
    if (wb_box.size.width < 0) { // relative to container
      size.width = (-wb_box.size.width / 100) * wb_size.width;
    } else if (wb_box.size.width > 0) { // fixed point size
      size.width = wb_box.size.width;
    }
    /*
     if wb_box describe the box content size, add border + padding
     else make sure the size is at least border + padding.
     */
    if (wb_blFlags.box_content)
      size.width += 2 * (wb_bwidth + wb_padding.width);
    else
      size.width = MAX(size.width, 2 * (wb_bwidth + wb_padding.width));
  }

  /* height */
  if (fiszero(wb_box.size.height)) { // fit to content
    size.height = cntSize.height + 2 * (wb_bwidth + wb_padding.height);
  } else {
    if (wb_box.size.height < 0) { // relative to container
      size.height = (-wb_box.size.height / 100) * wb_size.height;
    } else if (wb_box.size.height > 0) { // fixed point size
      size.height = wb_box.size.height;
    }
    /*
     if wb_box describe the box content size, add border + padding
     else make sure the size is at least border + padding.
     */
    if (wb_blFlags.box_content)
      size.height += 2 * (wb_bwidth + wb_padding.height);
    else
      size.height = MAX(size.height, 2 * (wb_bwidth + wb_padding.height));
  }

  return size;
}

- (NSSize)wb_boxSize {
  return [self wb_boxSizeForContentSize:wb_csize];
}

WB_INLINE
NSSize __WBBoxContentSizeForBoxSize(WBBoxLayer *layer, NSSize box) {
  // content size = box size - (borders + paddings) */
  return NSMakeSize(box.width - 2 * (layer->wb_bwidth + layer->wb_padding.width),
                    box.height - 2 * (layer->wb_bwidth + layer->wb_padding.height));
}

- (void)update {
  if ([self needsUpdate]) {
    /* max content size: container size - (border + padding) */
    NSSize content = __WBBoxContentSizeForBoxSize(self, wb_size);

    NSSize box = NSZeroSize;
    // if fit to content, we ignore container size and choose an arbitrary big value
    if (fiszero(wb_box.size.width)) content.width = 64e3;
    if (fiszero(wb_box.size.height)) content.height = 64e3;

    /* if box size is absolute or relative to container => box actual size,
     if box size is fit to container => box max size */
    box = [self wb_boxSizeForContentSize:content];

    /* adjust content according to the computed box size */
    content = __WBBoxContentSizeForBoxSize(self, box);

    /* cache requested content size */
    wb_content = [self drawingSizeForSize:content];

    if (wb_content.width >= 64e3 || wb_content.height >= 64e3)
      SPXThrowException(NSInternalInconsistencyException, @"request fit to content, but content does not has a valid size");

    // compute real content size (may be smaller than requested)
    // this size is used to compute the real box size, and to clip the content.
    wb_csize.width = MIN(content.width, wb_content.width);
    wb_csize.height = MIN(content.height, wb_content.height);

    [self setNeedsUpdate:NO];
    [self didUpdate];
  }
}

- (NSRect)bounds:(BOOL)isFlipped {
  if ([self needsUpdate]) [self update];

  NSRect bounds = NSZeroRect;

  bounds.size = [self wb_boxSize];

  if (wb_box.origin.x < 0) {
    /* relative position */
    bounds.origin.x = (-wb_box.origin.x / 100) * (wb_size.width - bounds.size.width);
  } else {
    /* fixed position */
    bounds.origin.x = wb_box.origin.x;
  }
  /* inverse if needed */
  if (wb_blFlags.box_right)
    bounds.origin.x = wb_size.width - bounds.size.width - bounds.origin.x;

  if (wb_box.origin.y < 0) {
    /* relative position */
    bounds.origin.y = (-wb_box.origin.y / 100) * (wb_size.height - bounds.size.height);
  } else {
    /* fixed position */
    bounds.origin.y = wb_box.origin.y;
  }
  /* inverse if needed */
  isFlipped = isFlipped ? 1 : 0;
  if (wb_blFlags.box_bottom == isFlipped)
    bounds.origin.y = wb_size.height - bounds.size.height - bounds.origin.y;

  return bounds;
}

- (NSSize)size {
  return wb_size;
}
- (void)setSize:(NSSize)aSize {
  NSParameterAssert(aSize.width >= 0);
  NSParameterAssert(aSize.height >= 0);
  if (!NSEqualSizes(aSize, wb_size)) {
    wb_size = aSize;
    [self setNeedsUpdate:YES];
  }
}

- (NSPoint)boxPosition {
  return wb_box.origin;
}
- (void)setBoxPosition:(NSPoint)aPosition {
  if (!NSEqualPoints(aPosition, wb_box.origin)) {
    wb_box.origin = aPosition;
    [self setNeedsUpdate:YES];
  }
}

- (NSSize)boxSize {
  if (!wb_blFlags.box_content)
    return wb_box.size;

  NSSize size = wb_box.size;
  size.width += 2 * (wb_bwidth + wb_padding.width);
  size.height += 2 * (wb_bwidth + wb_padding.height);
  return size;
}
- (void)setBoxSize:(NSSize)aSize {
  if (wb_blFlags.box_content || !NSEqualSizes(aSize, wb_box.size)) {
    wb_box.size = aSize;
    wb_blFlags.box_content = 0;
    [self setNeedsUpdate:YES];
  }
}

- (NSUInteger)boxVerticalAlignment {
  return wb_blFlags.box_bottom ? kWBStringLayerAlignmentBottom : kWBStringLayerAlignmentTop;
}
- (void)setBoxVerticalAlignment:(NSUInteger)theAlignment {
  bool update = false;
  switch (theAlignment) {
    default:
    case kWBStringLayerAlignmentTop:
      update = SPXFlagTestAndSet(wb_blFlags.box_bottom, 0) != 0;
      break;
    case kWBStringLayerAlignmentBottom:
      update = SPXFlagTestAndSet(wb_blFlags.box_bottom, 1) != 1;
      break;
  }
  if (update)
    [self setNeedsUpdate:YES];
}

- (NSUInteger)boxHorizontalAlignment {
  return wb_blFlags.box_right ? kWBStringLayerAlignmentRight : kWBStringLayerAlignmentLeft;
}
- (void)setBoxHorizontalAlignment:(NSUInteger)theAlignment {
  bool update = false;
  switch (theAlignment) {
    default:
    case kWBStringLayerAlignmentLeft:
      update = SPXFlagTestAndSet(wb_blFlags.box_right, 0) != 0;
      break;
    case kWBStringLayerAlignmentRight:
      update = SPXFlagTestAndSet(wb_blFlags.box_right, 1) != 1;
      break;
  }
  if (update)
    [self setNeedsUpdate:YES];
}

#pragma mark Content
- (NSSize)contentSize {
  if (wb_blFlags.box_content)
    return wb_box.size;

  NSSize size = wb_box.size;
  size.width = MAX(0, size.width - 2 * (wb_bwidth + wb_padding.width));
  size.height = MAX(0, size.height - 2 * (wb_bwidth + wb_padding.height));
  return size;
}
- (void)setContentSize:(NSSize)aSize {
  if (!wb_blFlags.box_content || !NSEqualSizes(aSize, wb_box.size)) {
    wb_box.size = aSize;
    wb_blFlags.box_content = 1;
    [self setNeedsUpdate:YES];
  }
}

- (NSUInteger)contentVerticalAlignment {
  return wb_blFlags.cnt_valign;
}
- (void)setContentVerticalAlignment:(NSUInteger)theAlignment {
  NSParameterAssert(theAlignment <= kWBStringLayerAlignmentRight);
  if (theAlignment != wb_blFlags.cnt_valign) {
    wb_blFlags.cnt_valign = (uint32_t)theAlignment;
    [self setNeedsUpdate:YES];
  }
}

- (NSUInteger)contentHorizontalAlignment {
  return wb_blFlags.cnt_halign;
}
- (void)setContentHorizontalAlignment:(NSUInteger)theAlignment {
  NSParameterAssert(theAlignment <= kWBStringLayerAlignmentBottom);
  if (theAlignment != wb_blFlags.cnt_halign) {
    wb_blFlags.cnt_halign = (uint32_t)theAlignment;
    [self setNeedsUpdate:YES];
  }
}

#pragma mark -
- (void)drawAtPoint:(NSPoint)aPoint {
  NSGraphicsContext *gctx = [NSGraphicsContext currentContext];
  CGRect bounds = NSRectToCGRect([self bounds:[gctx isFlipped]]);
  CGContextRef ctxt = [gctx graphicsPort];

  bounds.origin.x += aPoint.x;
  bounds.origin.y += aPoint.y;

  CGFloat radius = wb_radius;
  bool stroke = false, fill = false;
  CGRect box = WBCGContextIntegralPixelRect(ctxt, bounds);

  if (wb_border && wb_bwidth > 0) {
    stroke = true;
    [wb_border setStroke];
    radius -= wb_bwidth / 2;
    CGContextSetLineWidth(ctxt, wb_bwidth);
    box = CGRectInset(box, wb_bwidth / 2, wb_bwidth / 2);
  }
  if (wb_background) {
    fill = true;
    [wb_background setFill];
  }

  if (stroke || fill) {
    if (radius > 0) WBCGContextAddRoundRect(ctxt, box, radius);
    else CGContextAddRect(ctxt, box);
  }

  if (stroke && fill) CGContextDrawPath(ctxt, kCGPathFillStroke);
  else if (stroke) CGContextDrawPath(ctxt, kCGPathStroke);
  else if (fill) CGContextDrawPath(ctxt, kCGPathFill);

  bounds = WBCGContextIntegralPixelRect(ctxt, CGRectInset(bounds, wb_bwidth + wb_padding.width, wb_bwidth + wb_padding.height));


  CGFloat shift;
  CGRect clip = CGRectMake(bounds.origin.x, bounds.origin.y, wb_csize.width, wb_csize.height);
  NSRect content = NSMakeRect(bounds.origin.x, bounds.origin.y, wb_content.width, wb_content.height);

  switch (wb_blFlags.cnt_halign) {
    default:
    case kWBStringLayerAlignmentLeft:
      shift = 0;
      break;
    case kWBStringLayerAlignmentCenter:
      shift = (bounds.size.width - wb_content.width) / 2;
      break;
    case kWBStringLayerAlignmentRight:
      shift = bounds.size.width - wb_content.width;
      break;
  }
  content.origin.x += shift;
  if (shift > 0) clip.origin.x += shift;

  switch (wb_blFlags.cnt_valign) {
    default:
    case kWBStringLayerAlignmentTop:
      if ([gctx isFlipped]) shift = 0;
      else shift = bounds.size.height - wb_content.height;
      break;
    case kWBStringLayerAlignmentMiddle:
      shift = (bounds.size.height - wb_content.height) / 2;
      break;
    case kWBStringLayerAlignmentBottom:
      if ([gctx isFlipped]) shift = bounds.size.height - wb_content.height;
      else shift = 0;
      break;
  }
  content.origin.y += shift;
  if (shift > 0) clip.origin.y += shift;

  CGContextSaveGState(ctxt);
  /* clip to content */
  CGContextClipToRect(ctxt, clip);
  [self drawContentInRect:content];
  CGContextRestoreGState(ctxt);
}

- (void)drawAtPoint:(NSPoint)aPoint context:(CGContextRef)aContext {
  [NSGraphicsContext saveGraphicsState];
  [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:aContext flipped:YES]];
  [self drawAtPoint:aPoint];
  [NSGraphicsContext restoreGraphicsState];
}

- (void)didUpdate { }

- (NSSize)drawingSizeForSize:(NSSize)bounds { return NSZeroSize; }
- (void)drawContentInRect:(NSRect)aRect { }

- (BOOL)needsUpdate {
  return wb_blFlags.dirty;
}
- (void)setNeedsUpdate:(BOOL)display {
  SPXFlagSet(wb_blFlags.dirty, display);
}

@end
