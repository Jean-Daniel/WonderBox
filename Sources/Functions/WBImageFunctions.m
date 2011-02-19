/*
 *  WBImageFunctions.c
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBImageFunctions.h)

#pragma mark -
void WBImageSetRepresentationsSize(NSImage *image, NSSize size) {
  if (image) {
    NSArray *reps = [image representations];
    for (NSUInteger idx = 0; idx < [reps count]; idx++) {
      NSImageRep *rep = [reps objectAtIndex:idx];
      if ([rep isKindOfClass:[NSBitmapImageRep class]])
        if ([rep size].width > size.width || [rep size].height > size.height)
          [rep setSize:size];
    }
  }
}

#pragma mark -
NSBitmapImageRep *WBImageResizeImage(NSImage *anImage, NSSize size) {
  NSArray *reps = [anImage representations];
  for (NSUInteger idx = 0; idx < [reps count]; idx++) {
    NSImageRep *rep = [reps objectAtIndex:idx];
    if ([rep isKindOfClass:[NSBitmapImageRep class]] &&
        fequal([rep pixelsWide], size.width) &&
        fequal([rep pixelsHigh], size.height))
      return (NSBitmapImageRep *)rep;
  }

  NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil
                                                                     pixelsWide:size.width
                                                                     pixelsHigh:size.height
                                                                  bitsPerSample:8
                                                                samplesPerPixel:4
                                                                       hasAlpha:YES
                                                                       isPlanar:NO
                                                                 colorSpaceName:NSCalibratedRGBColorSpace
                                                                   bitmapFormat:0
                                                                    bytesPerRow:0
                                                                   bitsPerPixel:0];
  NSGraphicsContext *ctxt = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];

  [NSGraphicsContext saveGraphicsState];
  [NSGraphicsContext setCurrentContext:ctxt];
  [ctxt setShouldAntialias:YES];
  [ctxt setImageInterpolation:NSImageInterpolationHigh];

  NSRect src = NSZeroRect;
  src.size = [anImage size];

  NSRect dest = NSZeroRect;
  dest.size = size;

  /* Clear context */
  CGContextClearRect([ctxt graphicsPort], NSRectToCGRect(dest));

  /* Draw image */
  [anImage drawInRect:dest fromRect:src operation:NSCompositeSourceOver fraction:1];

  /* Restore context */
  [NSGraphicsContext restoreGraphicsState];

  return [bitmap autorelease];
}
