/*
 *  WBImageAndTextCell.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBImageAndTextCell.h)
#import WBHEADER(WBGeometry.h)

#define kWBImageMargin 5

@interface WBImageAndTextCell ()

- (NSSize)wb_imageSize:(NSSize)cellSize;

@end

/* WARNING: Does not correctly handle selection, highligting and edition when alignment != NSLeftTextAlignment.
 Can be used in static centered label.
 */
@implementation WBImageAndTextCell

- (id)copyWithZone:(NSZone *)zone {
  WBImageAndTextCell *copy = (WBImageAndTextCell *)[super copyWithZone:zone];
  copy->wb_image = [wb_image retain];
  copy->wb_itcFlags = wb_itcFlags;
  return copy;
}

+ (id)cell {
  return [[[self alloc] init] autorelease];
}

- (void)dealloc {
  [wb_image release];
  [super dealloc];
}

#pragma mark -
- (void)setObjectValue:(id)anObject {
  NSArray *keys = nil;
  if ([anObject respondsToSelector:@selector(name)] && [anObject respondsToSelector:@selector(icon)]) {
    [self setTitle:[anObject name] ? : @""];
    [self setImage:[anObject icon]];
  } else if ([anObject isKindOfClass:[NSDictionary class]]) {
    [self setTitle:[anObject objectForKey:@"name"] ? : @""];
    [self setImage:[anObject objectForKey:@"icon"]];    
  } else if ((keys = [anObject exposedBindings]) &&
             ([keys containsObject:@"name"] && [keys containsObject:@"icon"])) {
    [self setTitle:[anObject valueForKey:@"name"] ? : @""];
    [self setImage:[anObject valueForKey:@"icon"]];
  } else {
    [self setImage:nil];
    [super setObjectValue:anObject];
  }
}

- (NSImage *)image {
  return wb_image;
}
- (void)setImage:(NSImage *)anImage {
  WBSetterRetain(&wb_image, anImage);
}

- (BOOL)drawsLineOver {
  return wb_itcFlags.line;
}
- (void)setDrawsLineOver:(BOOL)flag {
  WBFlagSet(wb_itcFlags.line, flag);
}

#pragma mark NSCell
- (NSSize)cellSize {
  NSSize cellSize = [super cellSize];
  if (wb_image) 
    cellSize.width += [self wb_imageSize:cellSize].width + kWBImageMargin;
  
  return cellSize;
}

- (NSRect)titleRectForBounds:(NSRect)cellRect {
  if (!wb_image)
    return [super titleRectForBounds:cellRect];
  
  NSRect imageFrame;
  NSSize imageSize = [self wb_imageSize:cellRect.size];
  
  NSDivideRect(cellRect, &imageFrame, &cellRect, kWBImageMargin + imageSize.width, NSMinXEdge);
  
  /* Center Text Verticaly */
  CGFloat yOffset = floor((NSHeight(cellRect) - [[self attributedStringValue] size].height) / 2.0);
  cellRect.origin.y += yOffset;
  cellRect.size.height -= 2 * yOffset;
  
  return cellRect;
}

// -------------------------------------------------------------------------------
//	hitTestForEvent:
//
//	In 10.5, we need you to implement this method for blocking drag and drop of a given cell.
//	So NSCell hit testing will determine if a row can be dragged or not.
//
//	NSTableView calls this cell method when starting a drag, if the hit cell returns
//	NSCellHitTrackableArea, the particular row will be tracked instead of dragged.
//
// -------------------------------------------------------------------------------
- (NSUInteger)hitTestForEvent:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView {
  if (!wb_image) return [super hitTestForEvent:event inRect:cellFrame ofView:controlView];
  
  NSPoint point = [controlView convertPoint:[event locationInWindow] fromView:nil];
  
  NSRect textFrame, imageFrame;
  NSSize imageSize = [self wb_imageSize:cellFrame.size];
  NSDivideRect(cellFrame, &imageFrame, &textFrame, kWBImageMargin + imageSize.width, NSMinXEdge);
  if (NSMouseInRect(point, imageFrame, [controlView isFlipped]))
    return NSCellHitContentArea | NSCellHitTrackableArea;
  
  return [super hitTestForEvent:event inRect:cellFrame ofView:controlView];
}


- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent {
  [super editWithFrame:[self titleRectForBounds:aRect] inView:controlView editor:textObj delegate:anObject event:theEvent];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj
               delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength {
  [super selectWithFrame:[self titleRectForBounds:aRect] inView:controlView editor:textObj 
                delegate:anObject start:selStart length:selLength];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  NSSize textSize = [[self attributedStringValue] size];
  
  if (wb_image) {
    NSRect imageFrame = cellFrame;
    NSSize imageSize = [self wb_imageSize:cellFrame.size];
      
    if ([self alignment] == NSCenterTextAlignment || [self alignment] == NSRightTextAlignment) {
      CGFloat twidth = textSize.width;
      imageFrame.origin.x = AVG(NSWidth(cellFrame), - twidth); // - imageSize.width;
      imageFrame.origin.x -= (5 + imageSize.width);
      imageFrame.origin.x = round(MAX(imageFrame.origin.x, 3));
    } else {
      /* Update cellFrame and imageFrame */
      NSDivideRect(cellFrame, &imageFrame, &cellFrame, kWBImageMargin + imageSize.width, NSMinXEdge);
      /* left padding */
      imageFrame.origin.x = round(imageFrame.origin.x + 3);
    }
    imageFrame.size = imageSize;
    
    if ([self drawsBackground] && ![self isHighlighted]) {
      [[self backgroundColor] setFill];
      [NSBezierPath fillRect:cellFrame];
    }
    
    /* valign => middle */
    if ([controlView isFlipped]) {
      imageFrame.origin.y += floor((NSHeight(cellFrame) + NSHeight(imageFrame)) / 2);
    } else {
      imageFrame.origin.y += ceil((NSHeight(cellFrame) - NSHeight(imageFrame)) / 2);
    }
    
    CGContextRef ctxt = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(ctxt);
    /* Flip if needed */
    if ([controlView isFlipped]) {
      CGContextTranslateCTM(ctxt, 0., NSHeight([controlView frame]));
      CGContextScaleCTM(ctxt, 1., -1.);
      /* Adjust origin */
      imageFrame.origin.y = NSHeight([controlView frame]) - imageFrame.origin.y;
    }
    
    //NSIntegralRect(imageFrame);
    
    NSRect source = NSZeroRect;
    source.size = [wb_image size];
    CGContextSetShouldAntialias(ctxt, true);
    CGContextSetInterpolationQuality(ctxt, kCGInterpolationHigh);
    [wb_image drawInRect:imageFrame fromRect:source operation:NSCompositeSourceOver fraction:1];
    CGContextRestoreGState(ctxt);

    /* Center Text Verticaly */
    CGFloat yOffset = floor((NSHeight(cellFrame) - textSize.height) / 2.0);
    cellFrame.origin.y += yOffset;
    cellFrame.size.height -= yOffset;
  } else {
    /* Center Text Verticaly */
    CGFloat yOffset = floor((NSHeight(cellFrame) - textSize.height) / 2.0);
    cellFrame.origin.y += yOffset;
    cellFrame.size.height -= yOffset;
  }
  [super drawWithFrame:cellFrame inView:controlView];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  [super drawInteriorWithFrame:cellFrame inView:controlView];
  
  if ([self drawsLineOver]) {
    CGFloat twidth = [[self attributedStringValue] size].width;
    // FIXME: userspace scale factor
    CGFloat y = NSMinY(cellFrame) + 7.5f;
    twidth = MIN(NSWidth(cellFrame) - 4, twidth + 2);
    [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(cellFrame) + 2, y) toPoint:NSMakePoint(NSMinX(cellFrame) + twidth, y)];
  }
}

#pragma mark -
- (NSSize)wb_imageSize:(NSSize)cellSize {
  if (!wb_image) return NSZeroSize;
  /* Scale if needed */
  return NSSizeFromCGSize(WBSizeScaleToSize(NSSizeToCGSize([wb_image size]), 
                                            NSSizeToCGSize(cellSize),
                                            kWBScalingModeProportionallyFitDown));
}

@end
