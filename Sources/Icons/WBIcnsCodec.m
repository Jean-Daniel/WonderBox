/*
 *  IcnsCodec.c
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import "WBIcnsCodec.h"

#pragma mark xBitData For Bitmap
Handle WBIconFamilyGet32BitDataForBitmap(NSBitmapImageRep *bitmap) {
  if (!bitmap) return nil;
  if ([bitmap bitsPerSample] != 8) {
    SPXThrowException(NSInternalInconsistencyException, @"Image must have 8 bits per sample");
  }

  BOOL premult = YES;
  BOOL alphaFirst = NO;
  /* Pre Tiger version don't know bitmapFormat */
  if ([bitmap respondsToSelector:@selector(bitmapFormat)]) {
    premult = ([bitmap bitmapFormat] & NSAlphaNonpremultipliedBitmapFormat) == 0;
    alphaFirst = ([bitmap bitmapFormat] & NSAlphaFirstBitmapFormat) != 0;
  }

  BOOL alpha;
  Handle handle = nil;
  unsigned char *dest;
  unsigned char *src[6];
  BOOL isPlanar = [bitmap isPlanar];
  NSSize size = NSMakeSize([bitmap pixelsWide], [bitmap pixelsHigh]);
  NSUInteger i, j, pixels = size.width * size.height;
  unsigned char alphaPix;
  CGFloat oneOverAlpha;
  NSUInteger skip = 0;
  if (isPlanar) {
    skip = [bitmap bytesPerRow] - size.width;
  } else {
    skip = [bitmap bytesPerRow] - (size.width * ([bitmap bitsPerPixel] / 8));
  }

  [bitmap getBitmapDataPlanes:src];

  switch (NSNumberOfColorComponents([bitmap colorSpaceName])) {
    case 4: /* CMYK */
      handle = NewHandleClear(pixels * 4);
      dest = (unsigned char *)*handle;
      if (alphaFirst && isPlanar) {
        unsigned char *tmp = src[0];
        src[0] = src[1];
        src[1] = src[2];
        src[2] = src[3];
        src[3] = src[4];
        src[4] = tmp;
      }
      alpha = (isPlanar) ? [bitmap numberOfPlanes] == 5 : [bitmap bitsPerPixel] == 40;
      for (i=0; i<size.height; i++) {
        for (j=0; j<size.width; j++) {
          alphaPix = (alpha) ? ((isPlanar) ? *(src[4]++) : (alphaFirst) ? *(src[0]++) : *(src[0]+4)) : 0;
          oneOverAlpha = (alphaPix && premult) ? 255./alphaPix : 1;
          char black = (isPlanar) ? *(src[3]++) : (alphaFirst) ? src[0][4] : src[0][3];
          *(dest++) = alphaPix;
          *(dest++) = MAX(0, (1 - *(src[0]++) - black)) * oneOverAlpha; /* red = (1 - cyan) - black */
          *(dest++) = MAX(0, (1 - ((isPlanar) ? *(src[1]++) : *(src[0]++)) - black)) * oneOverAlpha; /* green  = (1 - magenta) - black */
          *(dest++) = MAX(0, (1 - ((isPlanar) ? *(src[2]++) : *(src[0]++)) - black)) * oneOverAlpha; /* blue  = (1 - yellow) - black */
          (isPlanar) ? src[3]++ : src[0]++; // ignore black component
          // skip alpha if needed
          if (alpha && !alphaFirst) src[0]++;
        }
        /* Skip padding at end of line */
        src[0] += skip;
        if (isPlanar) { src[1] += skip; src[2] += skip; src[3] += skip; if (alpha) src[4] += skip; }
      }
        break;
    case 3: /* RGB */
      handle = NewHandleClear(pixels * 4);
      dest = (unsigned char *)*handle;
      if (alphaFirst && isPlanar) {
        /* Use src[5] as temp */
        src[5] = src[0];
        src[0] = src[1];
        src[1] = src[2];
        src[2] = src[3];
        src[3] = src[5];
      }
      alpha = (isPlanar) ? [bitmap numberOfPlanes] == 4 : [bitmap bitsPerPixel] == 32;
      for (i=0; i<size.height; i++) {
        for (j=0; j<size.width; j++) {
          alphaPix = (alpha) ? ((isPlanar) ? *(src[3]++) : (alphaFirst) ? *(src[0]++) : *(src[0]+3)) : 0;
          oneOverAlpha = (alphaPix && premult) ? 255./alphaPix : 1;
          *(dest++) = alphaPix;
          *(dest++) = *(src[0]++) * oneOverAlpha; /* red */
          *(dest++) = ((isPlanar) ? *(src[1]++) : *(src[0]++)) * oneOverAlpha; /* green */
          *(dest++) = ((isPlanar) ? *(src[2]++) : *(src[0]++)) * oneOverAlpha; /* blue */
          // skip alpha if needed
          if (alpha && !alphaFirst) src[0]++;
        }
        /* Skip padding at end of line */
        src[0] += skip;
        if (isPlanar) { src[1] += skip; src[2] += skip; if (alpha) src[3] += skip; }
      }
        break;
    case 1: /* Gray */
      handle = NewHandleClear(pixels * 4);
      dest = (unsigned char *)*handle;
      if (alphaFirst) {
        if (isPlanar) {
          /* use src[2] as temp */
          src[2] = src[0];
          src[0] = src[1];
          src[1] = src[2];
        }
      }
      alpha = (isPlanar) ? [bitmap numberOfPlanes] == 2 : [bitmap bitsPerPixel] == 16;
      for (i=0; i<size.height; i++) {
        for (j=0; j<size.width; j++) {
          alphaPix = (alpha) ? ((isPlanar) ? *(src[1]++) : (alphaFirst) ? *(src[0]++) : *(src[0]+1)) : 0;
          oneOverAlpha = (alphaPix && premult) ? 255./alphaPix : 1;
          *(dest++) = alphaPix;
          /* Copy three times the same value */
          *(dest++) = *src[0] * oneOverAlpha;
          *(dest++) = *src[0] * oneOverAlpha;
          *(dest++) = *(src[0]++) * oneOverAlpha;
          // skip alpha if needed
          if (alpha && !alphaFirst) src[0]++;
        }
        /* Skip padding at end of line */
        src[0] += skip;
        if (isPlanar && alpha) { src[1] += skip; }
      }
        break;
    default:
      SPXThrowException(NSInternalInconsistencyException, @"Unsupported colors space: %@", [bitmap colorSpaceName]);
  }
  return handle;
}

#pragma mark xBit Mask for Bitmap
Handle WBIconFamilyGet8BitMaskForBitmap(NSBitmapImageRep *bitmap) {
  if (!bitmap) return nil;
  if ([bitmap bitsPerSample] != 8) {
    SPXThrowException(NSInternalInconsistencyException, @"Image must have 8 bits per sample");
  }

  BOOL alphaFirst = NO;
  /* Pre Tiger version don't know bitmapFormat */
  if ([bitmap respondsToSelector:@selector(bitmapFormat)]) {
    alphaFirst = ([bitmap bitmapFormat] & NSAlphaFirstBitmapFormat) != 0;
  }

  Handle handle = nil;
  unsigned char *dest;
  unsigned char *src[5];
  NSSize size = NSMakeSize([bitmap pixelsWide], [bitmap pixelsHigh]);
  NSUInteger i, pixels = size.width * size.height;
  NSUInteger skip = 0;
  if ([bitmap isPlanar]) {
    skip = [bitmap bytesPerRow] - size.width;
  } else {
    skip = [bitmap bytesPerRow] - (size.width * ([bitmap bitsPerPixel] / 8));
  }

  [bitmap getBitmapDataPlanes:src];

  if (![bitmap hasAlpha]) {
    handle = NewHandle(size.width * size.height);
    memset(*handle, 255, GetHandleSize(handle));
  } else if ([bitmap isPlanar]) {
    UInt8* plan = src[(alphaFirst) ? 0 : [bitmap numberOfPlanes] - 1];
    handle = NewHandle(pixels);
    dest = (unsigned char *)*handle;
    for (i=0; i<size.height; i++) {
      memcpy(dest, plan, size.width * sizeof(char));
      dest += (NSInteger)size.width;
      plan += [bitmap bytesPerRow];
    }
  } else { // has alpha and is interleaved
    NSUInteger step = [bitmap samplesPerPixel];
    handle = NewHandleClear(pixels * 1);
    dest = (unsigned char *)*handle;
    src[0] += (alphaFirst) ? 0 : (step - 1); // First alpha value.
    for (i=0; i<pixels; i++) {
      *(dest++) = *src[0];
      src[0] += step;
    }
  }
  return handle;
}

#pragma mark -
#pragma mark Bitmap For xBitData
NSUInteger WBIconFamilyBitmapDataFor32BitData(NSData *data, NSSize size, unsigned char *planes[]) {
  NSUInteger pixels = size.width * size.height;
  if (([data length] / 4) < pixels) {
    return 0;
  }
  unsigned char *bytes = (unsigned char *)[data bytes];
  unsigned char *r, *g, *b, *a;
  r = malloc(pixels * sizeof(char));
  g = malloc(pixels * sizeof(char));
  b = malloc(pixels * sizeof(char));
  a = malloc(pixels * sizeof(char));
  CGFloat alpha;
  for (NSUInteger i = 0; i < pixels; i++) {
    a[i] = *(bytes++);
    alpha = a[i]/255.;
    r[i] = *(bytes++) * alpha;
    g[i] = *(bytes++) * alpha;
    b[i] = *(bytes++) * alpha;
  }
  planes[0] = r;
  planes[1] = g;
  planes[2] = b;
  planes[3] = a;
  return 4;
}

#pragma mark Bitmap For xBitMask
NSUInteger WBIconFamilyBitmapDataFor8BitMask(NSData *data, NSSize size, unsigned char *planes[]) {
  NSUInteger pixels = size.width * size.height;
  if ([data length] < pixels) {
    return 0;
  }
  unsigned char *bytes = (unsigned char *)[data bytes];
  unsigned char *gray;
  gray = malloc(pixels * sizeof(char));
  for (NSUInteger i = 0; i < pixels; i++) {
    gray[i] = *bytes;
    bytes++;
  }
  planes[0] = gray;
  return 1;
}
