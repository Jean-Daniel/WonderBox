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

#define Color(c)		(float)(c/65535.)
static CGDeviceColor kWB4BitPalette[16] = {
{1, 1, 1},
{Color(64512), Color(62333), Color(1327)},
{1, Color(25738), Color(652)},
{Color(56683), Color(2242), Color(1698)},
{Color(62167), Color(2134), Color(34028)},
{Color(18147), 0, Color(42302)},
{0, 0, Color(54272)},
{Color(577), Color(43860), Color(60159)},
{Color(7969), Color(46995), Color(5169)},
{0, Color(25775), Color(4528)},
{Color(22016), Color(11421), Color(1316)},
{Color(37079), Color(29024), Color(14900)},
{Color(49152), Color(49152), Color(49152)},
{Color(32768), Color(32768), Color(32768)},
{Color(16384), Color(16384), Color(16384)},
{0, 0, 0}};

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

Handle WBIconFamilyGet8BitDataForBitmap(NSBitmapImageRep *bitmap) {
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

  CGDeviceColor color;
  CGDirectPaletteRef palette = CGPaletteCreateDefaultColorPalette();

  [bitmap getBitmapDataPlanes:src];

  switch (NSNumberOfColorComponents([bitmap colorSpaceName])) {
    case 4: /* CMYK */
      handle = NewHandleClear(pixels);
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
          char black 	= (isPlanar) ? *(src[3]++) : (alphaFirst) ? src[0][4] : src[0][3];
          color.red 	= (float)(MAX(0, (1 - *(src[0]++) - black)) * oneOverAlpha) / 255; /* red = (1 - cyan) - black */
          color.green	= (float)(MAX(0, (1 - ((isPlanar) ? *(src[1]++) : *(src[0]++)) - black)) * oneOverAlpha) / 255; /* green  = (1 - magenta) - black */
          color.blue 	= (float)(MAX(0, (1 - ((isPlanar) ? *(src[2]++) : *(src[0]++)) - black)) * oneOverAlpha) / 255; /* blue  = (1 - yellow) - black */
          (isPlanar) ? src[3]++ : src[0]++; // ignore black component
          if (alpha && !alphaFirst) src[0]++; // ignore alpha
          *(dest++) = CGPaletteGetIndexForColor(palette, color);
        }
        /* Skip padding at end of line */
        src[0] += skip;
        if (isPlanar) { src[1] += skip; src[2] += skip; src[3] += skip; if (alpha) src[4] += skip; }
      }
        break;
    case 3: /* RGB */
      handle = NewHandleClear(pixels);
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
          color.red 	= (float)(*(src[0]++) * oneOverAlpha) / 255; /* red */
          color.green = (float)(((isPlanar) ? *(src[1]++) : *(src[0]++)) * oneOverAlpha) / 255; /* green */
          color.blue 	= (float)(((isPlanar) ? *(src[2]++) : *(src[0]++)) * oneOverAlpha) / 255; /* blue */
          // skip alpha if needed
          if (alpha && !alphaFirst) src[0]++;
          *(dest++) = CGPaletteGetIndexForColor(palette, color);
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
          color.red 	= (float)(*src[0] * oneOverAlpha) / 255; /* red = (1 - cyan) - black */
          color.green = (float)(*src[0] * oneOverAlpha) / 255; /* green  = (1 - magenta) - black */
          color.blue 	= (float)(*(src[0]++) * oneOverAlpha) / 255; /* blue  = (1 - yellow) - black */
          // skip alpha if needed
          if (alpha && !alphaFirst) src[0]++;
          *(dest++) = CGPaletteGetIndexForColor(palette, color);
        }
        /* Skip padding at end of line */
        src[0] += skip;
        if (isPlanar && alpha) { src[1] += skip; }
      }
      break;
    default:
      CGPaletteRelease(palette);
      SPXThrowException(NSInternalInconsistencyException, @"Unsupported colors space: %@", [bitmap colorSpaceName]);
  }
  CGPaletteRelease(palette);
  return handle;
}

Handle WBIconFamilyGet4BitDataForBitmap(NSBitmapImageRep *bitmap) {
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
  NSUInteger i, j, idx = 0, pixels = size.width * size.height;
  unsigned char alphaPix;
  CGFloat oneOverAlpha;
  NSUInteger skip = 0;
  if (isPlanar) {
    skip = [bitmap bytesPerRow] - size.width;
  } else {
    skip = [bitmap bytesPerRow] - (size.width * ([bitmap bitsPerPixel] / 8));
  }

  CGDeviceColor color;
  CGDirectPaletteRef palette = CGPaletteCreateWithSamples(kWB4BitPalette, 16);

  [bitmap getBitmapDataPlanes:src];
  handle = NewHandleClear(pixels / 2);
  dest = (unsigned char *)*handle;
  switch (NSNumberOfColorComponents([bitmap colorSpaceName])) {
    case 4: /* CMYK */
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
        for (j=0; j<size.width; j++, idx++) {
          alphaPix = (alpha) ? ((isPlanar) ? *(src[4]++) : (alphaFirst) ? *(src[0]++) : *(src[0]+4)) : 0;
          oneOverAlpha = (alphaPix && premult) ? 255./alphaPix : 1;
          char black 	= (isPlanar) ? *(src[3]++) : (alphaFirst) ? src[0][4] : src[0][3];
          color.red 	= (float)(MAX(0, (1 - *(src[0]++) - black)) * oneOverAlpha) / 255; /* red = (1 - cyan) - black */
          color.green = (float)(MAX(0, (1 - ((isPlanar) ? *(src[1]++) : *(src[0]++)) - black)) * oneOverAlpha) / 255; /* green  = (1 - magenta) - black */
          color.blue 	= (float)(MAX(0, (1 - ((isPlanar) ? *(src[2]++) : *(src[0]++)) - black)) * oneOverAlpha) / 255; /* blue  = (1 - yellow) - black */
          (isPlanar) ? src[3]++ : src[0]++; // ignore black component
          if (alpha && !alphaFirst) src[0]++; // ignore alpha
          if (idx % 2) {
            *(dest++) |= CGPaletteGetIndexForColor(palette, color);
          } else {
            *dest |= CGPaletteGetIndexForColor(palette, color) << 4;
          }
        }
        /* Skip padding at end of line */
        src[0] += skip;
        if (isPlanar) { src[1] += skip; src[2] += skip; src[3] += skip; if (alpha) src[4] += skip; }
      }
      break;
    case 3: /* RGB */
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
        for (j=0; j<size.width; j++, idx++) {
          alphaPix = (alpha) ? ((isPlanar) ? *(src[3]++) : (alphaFirst) ? *(src[0]++) : *(src[0]+3)) : 0;
          oneOverAlpha = (alphaPix && premult) ? 255./alphaPix : 1;
          color.red = (float)(*(src[0]++) * oneOverAlpha) / 255; /* red */
          color.green = (float)(((isPlanar) ? *(src[1]++) : *(src[0]++)) * oneOverAlpha) / 255; /* green */
          color.blue = (float)(((isPlanar) ? *(src[2]++) : *(src[0]++)) * oneOverAlpha) / 255; /* blue */
          // skip alpha if needed
          if (alpha && !alphaFirst) src[0]++;
          if (idx % 2) {
            *(dest++) |= CGPaletteGetIndexForColor(palette, color);
          } else {
            *dest |= CGPaletteGetIndexForColor(palette, color) << 4;
          }
        }
        /* Skip padding at end of line */
        src[0] += skip;
        if (isPlanar) { src[1] += skip; src[2] += skip; if (alpha) src[3] += skip; }
      }
      break;
    case 1: /* Gray */
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
        for (j=0; j<size.width; j++, idx++) {
          alphaPix = (alpha) ? ((isPlanar) ? *(src[1]++) : (alphaFirst) ? *(src[0]++) : *(src[0]+1)) : 0;
          oneOverAlpha = (alphaPix && premult) ? 255./alphaPix : 1;
          color.red = (float)(*src[0] * oneOverAlpha) / 255; /* red = (1 - cyan) - black */
          color.green = (float)(*src[0] * oneOverAlpha) / 255; /* green  = (1 - magenta) - black */
          color.blue = (float)(*(src[0]++) * oneOverAlpha) / 255; /* blue  = (1 - yellow) - black */
          // skip alpha if needed
          if (alpha && !alphaFirst) src[0]++;
          if (idx % 2) {
            *(dest++) |= CGPaletteGetIndexForColor(palette, color);
          } else {
            *dest |= CGPaletteGetIndexForColor(palette, color) << 4;
          }
        }
        /* Skip padding at end of line */
        src[0] += skip;
        if (isPlanar && alpha) { src[1] += skip; }
      }
      break;
    default:
      DisposeHandle(handle);
      CGPaletteRelease(palette);
      SPXThrowException(NSInternalInconsistencyException, @"Unsupported colors space: %@", [bitmap colorSpaceName]);
  }
  CGPaletteRelease(palette);
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

Handle WBIconFamilyGet1BitDataAndMaskForBitmap(NSBitmapImageRep *bitmap) {
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
  unsigned char r, g, b;
  unsigned char *src[6];
  unsigned char *dest, *mask;
  BOOL isPlanar = [bitmap isPlanar];
  NSSize size = NSMakeSize([bitmap pixelsWide], [bitmap pixelsHigh]);
  NSUInteger i, j, pixels = size.width * size.height, idx = 0;
  unsigned char alphaPix;
  CGFloat oneOverAlpha;
  NSUInteger skip = 0;
  if (isPlanar) {
    skip = [bitmap bytesPerRow] - size.width;
  } else {
    skip = [bitmap bytesPerRow] - (size.width * ([bitmap bitsPerPixel] / 8));
  }

  [bitmap getBitmapDataPlanes:src];
  /* lceil does not exists but lceil(x) ~ lround(x - 0.5) */
  handle = NewHandleClear(lround((pixels / 4.) - 0.49));
  dest = (unsigned char *)*handle;
  mask = (unsigned char *)(*handle) + lround((pixels / 8.) - 0.49);
  switch (NSNumberOfColorComponents([bitmap colorSpaceName])) {
    case 4: /* CMYK */
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
        for (j=0; j<size.width; j++, idx++) {
          alphaPix = (alpha) ? ((isPlanar) ? *(src[4]++) : (alphaFirst) ? *(src[0]++) : *(src[0]+4)) : 0;
          oneOverAlpha = (alphaPix && premult) ? 255./alphaPix : 1;
          char black = (isPlanar) ? *(src[3]++) : (alphaFirst) ? src[0][4] : src[0][3];
          r = (MAX(0, (1 - *(src[0]++) - black)) * oneOverAlpha); /* red = (1 - cyan) - black */
          g = (MAX(0, (1 - ((isPlanar) ? *(src[1]++) : *(src[0]++)) - black)) * oneOverAlpha); /* green  = (1 - magenta) - black */
          b = (MAX(0, (1 - ((isPlanar) ? *(src[2]++) : *(src[0]++)) - black)) * oneOverAlpha); /* blue  = (1 - yellow) - black */
          (isPlanar) ? src[3]++ : src[0]++; // ignore black component
          /* skip alpha if needed */
          if (alpha && !alphaFirst) src[0]++;
          *dest |= ((((r+g+b) / 3) < 127) ? 1 : 0) << (7 - (idx % 8)) ;
          *mask |= ((alphaPix > 127) ? 1 : 0) << (7 - (idx % 8));
          if ((idx % 8) == 7) {
            dest++;
            mask++;
          }
        }
        /* Skip padding at end of line */
        src[0] += skip;
        if (isPlanar) { src[1] += skip; src[2] += skip; src[3] += skip; if (alpha) src[4] += skip; }
      }
        break;
    case 3: /* RGB */
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
        for (j=0; j<size.width; j++, idx++) {
          alphaPix = (alpha) ? ((isPlanar) ? *(src[3]++) : (alphaFirst) ? *(src[0]++) : *(src[0]+3)) : 0;
          oneOverAlpha = (alphaPix && premult) ? 255./alphaPix : 1;
          r = (*(src[0]++) * oneOverAlpha); /* red */
          g = (((isPlanar) ? *(src[1]++) : *(src[0]++)) * oneOverAlpha); /* green */
          b = (((isPlanar) ? *(src[2]++) : *(src[0]++)) * oneOverAlpha); /* blue */
          // skip alpha if needed
          if (alpha && !alphaFirst) src[0]++;
          *dest |= ((((r+g+b) / 3) < 127) ? 1 : 0) << (7 - (idx % 8)) ;
          *mask |= ((alphaPix > 127) ? 1 : 0) << (7 - (idx % 8));
          if ((idx % 8) == 7) {
            dest++;
            mask++;
          }
        }
        /* Skip padding at end of line */
        src[0] += skip;
        if (isPlanar) { src[1] += skip; src[2] += skip; if (alpha) src[3] += skip; }
      }
      break;
    case 1: /* Gray */
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
        for (j=0; j<size.width; j++, idx++) {
          alphaPix = (alpha) ? ((isPlanar) ? *(src[1]++) : (alphaFirst) ? *(src[0]++) : *(src[0]+1)) : 0;
          oneOverAlpha = (alphaPix && premult) ? 255./alphaPix : 1;
          g = (*(src[0]++) * oneOverAlpha); /* blue  = (1 - yellow) - black */
          // skip alpha if needed
          if (alpha && !alphaFirst) src[0]++;
          *dest |= ((g < 127) ? 1 : 0) << (7 - (idx % 8)) ;
          *mask |= ((alphaPix > 127) ? 1 : 0) << (7 - (idx % 8));
          if ((idx % 8) == 7) {
            dest++;
            mask++;
          }
        }
        /* Skip padding at end of line */
        src[0] += skip;
        if (isPlanar && alpha) { src[1] += skip; }
      }
      break;
    default:
      DisposeHandle(handle);
      SPXThrowException(NSInternalInconsistencyException, @"Unsupported colors space: %@", [bitmap colorSpaceName]);
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
  r = NSZoneMalloc(nil, pixels * sizeof(char));
  g = NSZoneMalloc(nil, pixels * sizeof(char));
  b = NSZoneMalloc(nil, pixels * sizeof(char));
  a = NSZoneMalloc(nil, pixels * sizeof(char));
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

NSUInteger WBIconFamilyBitmapDataFor8BitData(NSData *data, NSSize size, unsigned char *planes[]) {
  CGDeviceColor color;
  CGDirectPaletteRef palette;
  NSUInteger pixels = size.width * size.height;
  if ([data length] < pixels) {
    return 0;
  }
  unsigned char *bytes = (unsigned char *)[data bytes];
  unsigned char *r, *g, *b;
  r = NSZoneMalloc(nil, pixels * sizeof(char));
  g = NSZoneMalloc(nil, pixels * sizeof(char));
  b = NSZoneMalloc(nil, pixels * sizeof(char));
  palette = CGPaletteCreateDefaultColorPalette();
  for (NSUInteger i = 0; i < pixels; i++) {
    color = CGPaletteGetColorAtIndex(palette, *(bytes++));
    r[i] = color.red * 255;
    g[i] = color.green * 255;
    b[i] = color.blue * 255;
  }
  CGPaletteRelease(palette);
  planes[0] = r;
  planes[1] = g;
  planes[2] = b;
  return 3;
}

NSUInteger WBIconFamilyBitmapDataFor4BitData(NSData *data, NSSize size, unsigned char *planes[]) {
  CGDeviceColor color;
  CGDirectPaletteRef palette;
  NSUInteger pixels = size.width * size.height;
  if (([data length] * 2) < pixels) {
    return 0;
  }
  unsigned char *bytes = (unsigned char *)[data bytes];
  unsigned char *r, *g, *b;
  r = NSZoneMalloc(nil, pixels * sizeof(char));
  g = NSZoneMalloc(nil, pixels * sizeof(char));
  b = NSZoneMalloc(nil, pixels * sizeof(char));
  palette = CGPaletteCreateWithSamples(kWB4BitPalette, 16);
  for (NSUInteger i = 0; i < pixels; i++) {
    if (i%2) {
      color = CGPaletteGetColorAtIndex(palette, *bytes >> 4);
    } else {
      color = CGPaletteGetColorAtIndex(palette, *(bytes++) & 0xF);
    }
    r[i] = color.red * 255;
    g[i] = color.green * 255;
    b[i] = color.blue * 255;
  }
  CGPaletteRelease(palette);
  planes[0] = r;
  planes[1] = g;
  planes[2] = b;
  return 3;
}

NSUInteger WBIconFamilyBitmapDataFor1BitData(NSData *data, NSSize size, unsigned char *planes[]) {
  NSUInteger pixels = size.width * size.height;
  if (([data length] * 8) < pixels) {
    return 0;
  }
  unsigned char *bytes = (unsigned char *)[data bytes];
  unsigned char *gray;
  gray = NSZoneMalloc(nil, pixels * sizeof(char));
  for (NSUInteger i = 0; i < pixels; i++) {
    gray[i] = ((*bytes >> (7 - (i % 8))) & 0x1) ? 255 : 0;
    if ((i % 8) == 7) {
      bytes++;
    }
  }
  planes[0] = gray;
  return 1;
}

#pragma mark Bitmap For xBitMask
NSUInteger WBIconFamilyBitmapDataFor8BitMask(NSData *data, NSSize size, unsigned char *planes[]) {
  NSUInteger pixels = size.width * size.height;
  if ([data length] < pixels) {
    return 0;
  }
  unsigned char *bytes = (unsigned char *)[data bytes];
  unsigned char *gray;
  gray = NSZoneMalloc(nil, pixels * sizeof(char));
  for (NSUInteger i = 0; i < pixels; i++) {
    gray[i] = *bytes;
    bytes++;
  }
  planes[0] = gray;
  return 1;
}

NSUInteger WBIconFamilyBitmapDataFor1BitMask(NSData *data, NSSize size, unsigned char *planes[]) {
  NSUInteger pixels = size.width * size.height;
  if (([data length] * 8) < pixels) {
    return 0;
  }
  unsigned char *bytes = (unsigned char *)[data bytes];
  bytes += [data length]/2;
  unsigned char *gray;
  gray = NSZoneMalloc(nil, pixels * sizeof(char));
  for (NSUInteger i = 0; i < pixels; i++) {
    gray[i] = ((*bytes >> (7 - (i % 8))) & 0x1) ? 255 : 0;
    if ((i % 8) == 7) {
      bytes++;
    }
  }
  planes[0] = gray;
  return 1;
}
