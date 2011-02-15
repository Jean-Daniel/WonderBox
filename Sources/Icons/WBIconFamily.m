/*
 *  WBIconFamily.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import "WBIcnsCodec.h"
#import WBHEADER(WBIconFamily.h)
#import WBHEADER(WBIconFunctions.h)

#import WBHEADER(WBFSFunctions.h)
#import WBHEADER(NSData+WonderBox.h)
// #import WBHEADER(WBImageFunctions.h)

#pragma mark -
static NSMutableArray *WBIconFamilyFindVariants(IconFamilyResource *rsrc);
static BOOL WBIconFamilyContainsVariant(IconFamilyResource *rsrc, OSType variant);
static IconFamilyHandle WBIconFamilyCopyVariant(IconFamilyResource *rsrc, OSType variant);
static BOOL WBIconFamilyRemoveVariant(IconFamilyResource *rsrc, OSType variant, IconFamilyHandle result);

#pragma mark -
@implementation WBIconFamily

- (id)copyWithZone:(NSZone *)zone {
  WBIconFamily *copy = [[[self class] allocWithZone:zone] init];
  [copy setFamilyHandle:self->wb_family];
  return copy;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  id data = [[NSData alloc] initWithHandle:(Handle)wb_family];
  [aCoder encodeObject:data forKey:@"WBIconFamilyData"];
  [data release];
}
- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super init]) {
    NSData *data = [coder decodeObjectForKey:@"WBIconFamilyData"];
    PtrToHand([data bytes], (Handle *)&wb_family, [data length]);
  }
  return self;
}

#pragma mark Convenients Methods
+ (id)iconFamily {
  return [[[self alloc] init] autorelease];
}

+ (id)iconFamilyWithContentsOfFile:(NSString*)path {
  return [[[self alloc] initWithContentsOfFile:path] autorelease];
}

+ (id)iconFamilyWithIconAtPath:(NSString*)path {
  return [[[self alloc] initWithIconAtPath:path] autorelease];
}

+ (id)iconFamilyWithIconFamilyHandle:(IconFamilyHandle)newIconFamily {
  return [[[self alloc] initWithIconFamilyHandle:newIconFamily] autorelease];
}

+ (id)iconFamilyWithSystemIcon:(OSType)fourByteCode {
  return [[[self alloc] initWithSystemIcon:fourByteCode] autorelease];
}

+ (id)iconFamilyWithThumbnailsOfImage:(NSImage*)image {
  return [[[self alloc] initWithThumbnailsOfImage:image] autorelease];
}

+ (id)iconFamilyWithThumbnailsOfImage:(NSImage*)image forElements:(WBIconFamilySelector)elements {
  return [[[self alloc] initWithThumbnailsOfImage:image forElements:elements] autorelease];
}

#pragma mark -
#pragma mark Initializer
- (id)init {
  return [self initWithThumbnailsOfImage:nil];
}

- (id)initWithContentsOfFile:(NSString *)path {
  if (self = [super init]) {
    if (!WBIconFamilyReadFromPath((CFStringRef)[path stringByExpandingTildeInPath], &wb_family)) {
      wb_family = nil;
      [self release];
      self = nil;
    }
  }
  return self;
}

- (id)initWithIconFamilyHandle:(IconFamilyHandle)newIconFamily {
  if (self = [super init]) {
    [self setFamilyHandle:newIconFamily];
  }
  return self;
}

- (id)initWithIconAtPath:(NSString*)path {
  if (self = [super init]) {
    if (!WBIconFamilyGetFromPath((CFStringRef)[path stringByExpandingTildeInPath], &wb_family)) {
      wb_family = nil;
      [self release];
      self = nil;
    }
  }
  return self;
}

- (id)initWithSystemIcon:(OSType)fourByteCode {
  if (self = [super init]) {
    if (noErr != WBIconFamilyGetSystemIcon(fourByteCode, &wb_family)) {
      wb_family = nil;
      [self release];
      self = nil;
    }
  }
  return self;
}

- (id)initWithThumbnailsOfImage:(NSImage *)anImage {
  return [self initWithThumbnailsOfImage:anImage forElements:kWBSelectorAllNewAvailable];
}

- (id)initWithThumbnailsOfImage:(NSImage*)anImage forElements:(WBIconFamilySelector)elements {
  if (self = [super init]) {
    wb_family = (IconFamilyHandle)NewHandle(0);
    if (!wb_family) {
      [self release];
      self = nil;
    }
    if (anImage) {
      [self setIconFamilyElements:elements fromImage:anImage];
    }
  }
  return self;
}

- (void)dealloc {
  if (wb_family) {
    DisposeHandle((Handle)wb_family);
    wb_family = nil;
  }
  [super dealloc];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p>",
    NSStringFromClass([self class]), self];
}

#pragma mark -
#pragma mark Variants manipulation
- (NSArray *)variantsTypes {
  id variants;
  HLock((Handle)wb_family);
  variants = WBIconFamilyFindVariants(WBIconFamilyGetFamilyResource(wb_family));
  HUnlock((Handle)wb_family);
  return variants;
}

- (BOOL)containsVariant:(OSType)aVariant {
  BOOL exists;
  HLock((Handle)wb_family);
  exists = WBIconFamilyContainsVariant(WBIconFamilyGetFamilyResource(wb_family), aVariant);
  HUnlock((Handle)wb_family);
  return exists;
}

- (WBIconFamily *)iconFamilyVariantForType:(OSType)aVariant {
  IconFamilyHandle icon = nil;
  icon = WBIconFamilyCopyVariant(WBIconFamilyGetFamilyResource(wb_family), aVariant);
  if (icon) {
    id family = [WBIconFamily iconFamilyWithIconFamilyHandle:icon];
    DisposeHandle((Handle)icon);
    return family;
  }
  return nil;
}

- (BOOL)setIconFamilyVariant:(WBIconFamily *)aFamily forType:(OSType)aVariant {
  OSStatus err;
  if (!WBIsIconVariantType(aVariant)) {
    WBThrowException(NSInvalidArgumentException, @"%@ isn't a valid Variant type", NSFileTypeForHFSTypeCode(aVariant));
  }
  if (!aFamily) {
    WBThrowException(NSInvalidArgumentException, @"aFamily cannot be nil");
  }
  if ([self containsVariant:aVariant]) {
    if (![self removeVariant:aVariant]) {
      DLog(@"Unable to remove old variant");
      return NO;
    }
  }
  /* Remove anything that is not a Tile ?? */
  NSArray *variants = [aFamily variantsTypes];
  if ([variants count] > 1 || ([variants count] == 1 && [[variants objectAtIndex:0] unsignedIntValue] != kTileIconVariant)) {
    aFamily = [aFamily copy];
    for (NSUInteger i = 0; i < [variants count]; i++) {
      OSType type = [[variants objectAtIndex:i] unsignedIntValue];
      if (type != kTileIconVariant) {
        [aFamily removeVariant:type];
      }
    }
  } else {
    [aFamily retain];
  }

  IconFamilyResource *rsrc;
  IconFamilyHandle variant = [aFamily familyHandle];
  rsrc = WBIconFamilyGetFamilyResource(variant);
  WBIconFamilyResourceSetType(rsrc, aVariant);
  err = HandAndHand((Handle)variant, (Handle)wb_family);
  WBIconFamilyResourceSetType(rsrc, kIconFamilyType);
  if (noErr == err) {
    WBIconFamilyResourceSetSize(WBIconFamilyGetFamilyResource(wb_family), (SInt32)GetHandleSize((Handle)wb_family));
  }
  [aFamily release];
  return noErr == err;
}

- (BOOL)removeVariant:(OSType)aVariant {
  BOOL result = NO;
  if (![self containsVariant:aVariant]) {
    return YES;
  }
  IconFamilyHandle icon = (IconFamilyHandle)NewHandle(0);
  HLock((Handle)wb_family);
  result = WBIconFamilyRemoveVariant(WBIconFamilyGetFamilyResource(wb_family), aVariant, icon);
  HUnlock((Handle)wb_family);
  if (result) {
    [self setFamilyHandle:icon];
  }
  DisposeHandle((Handle)icon);
  return result;
}

#pragma mark -
- (IconFamilyHandle)familyHandle {
  return wb_family;
}

- (void)setFamilyHandle:(IconFamilyHandle)newIconFamily {
  if (!newIconFamily) {
    WBThrowException(NSInvalidArgumentException, @"iconfamily Handle cannot be nil");
  }
  if (nil != wb_family) {
    DisposeHandle((Handle)wb_family);
  }
  wb_family = newIconFamily;
  OSErr err = HandToHand((Handle *)&wb_family);
  if (noErr != err) {
    wb_family = nil;
    WBThrowException(NSMallocException, @"Exception while copying Handle: %d", err);
  }
  WBIconFamilyResourceSetType(WBIconFamilyGetFamilyResource(wb_family), kIconFamilyType);
}

#pragma mark -
#pragma mark Write To File
- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)flag {
  id data = [[NSData alloc] initWithHandle:(Handle)wb_family];
  BOOL wrote = [data writeToFile:path atomically:flag];
  [data release];
  return wrote;
}

#pragma mark -
#pragma mark Elements Manipulation
- (NSData *)dataForIconFamilyElement:(OSType)anElement {
  id data = nil;
  switch (anElement) {
    case kHuge1BitData:
      anElement = kHuge1BitMask;
      break;
    case kLarge1BitData:
      anElement = kLarge1BitMask;
      break;
    case kSmall1BitData:
      anElement = kSmall1BitMask;
      break;
    case kMini1BitData:
      anElement = kMini1BitMask;
      break;
  }
  Handle handle = NewHandle(0);
  if (noErr == GetIconFamilyData(wb_family, anElement, handle)) {
    data = [NSData dataWithHandle:handle];
  }
  DisposeHandle(handle);
  return data;
}

- (NSBitmapImageRep *)bitmapForIconFamilyElement:(OSType)anElement {
  return [self bitmapForIconFamilyElement:anElement withMask:NO];
}

- (NSBitmapImageRep *)bitmapForIconFamilyElement:(OSType)anElement withMask:(BOOL)useAlpha {
  /* switch d'element pour trouver la taille et le nbr de bits */
  NSSize size = NSZeroSize;
  NSUInteger samples = 0;
  NSData *data = [self dataForIconFamilyElement:anElement];
  NSData *alpha = nil;
  unsigned char *planes[5] = {nil, nil, nil, nil, nil};
  if (!data) {
    return nil;
  }
  switch (anElement) {
    /* 512 x 512 */
    case kIconServices512PixelDataARGB:
      size = NSMakeSize(512, 512);
      samples = WBIconFamilyBitmapDataFor32BitData(data, size, planes);
      break;
    /* 256 x 256 */
    case kIconServices256PixelDataARGB: // 'ic08' 256x256 32-bits ARGB image
      size = NSMakeSize(256, 256);
      samples = WBIconFamilyBitmapDataFor32BitData(data, size, planes);
      break;
      /* Thumbnail */
    case kThumbnail32BitData:
      size = NSMakeSize(128, 128);
      samples = WBIconFamilyBitmapDataFor32BitData(data, size, planes);
      break;
    case kThumbnail8BitMask:
      useAlpha = NO;
      size = NSMakeSize(128, 128);
      samples = WBIconFamilyBitmapDataFor8BitMask(data, size, planes);
      break;
      /* Huge */
    case kHuge32BitData:
      size = NSMakeSize(48, 48);
      samples = WBIconFamilyBitmapDataFor32BitData(data, size, planes);
      break;
    case kHuge8BitData:
      size = NSMakeSize(48, 48);
      samples = WBIconFamilyBitmapDataFor8BitData(data, size, planes);
      alpha = (useAlpha) ? [self dataForIconFamilyElement:kHuge1BitMask] : nil;
      break;
    case kHuge4BitData:
      size = NSMakeSize(48, 48);
      samples = WBIconFamilyBitmapDataFor4BitData(data, size, planes);
      alpha = (useAlpha) ? [self dataForIconFamilyElement:kHuge1BitMask] : nil;
      break;
    case kHuge1BitData:
      size = NSMakeSize(48, 48);
      samples = WBIconFamilyBitmapDataFor1BitData(data, size, planes);
      alpha = (useAlpha) ? [self dataForIconFamilyElement:kHuge1BitMask] : nil;
      break;
    case kHuge8BitMask:
      useAlpha = NO;
      size = NSMakeSize(48, 48);
      samples = WBIconFamilyBitmapDataFor8BitMask(data, size, planes);
      break;
    case kHuge1BitMask:
      useAlpha = NO;
      size = NSMakeSize(48, 48);
      samples = WBIconFamilyBitmapDataFor1BitMask(data, size, planes);
      break;
      /* Large */
    case kLarge32BitData:
      size = NSMakeSize(32, 32);
      samples = WBIconFamilyBitmapDataFor32BitData(data, size, planes);
      break;
    case kLarge8BitData:
      size = NSMakeSize(32, 32);
      samples = WBIconFamilyBitmapDataFor8BitData(data, size, planes);
      alpha = (useAlpha) ? [self dataForIconFamilyElement:kLarge1BitMask] : nil;
      break;
    case kLarge4BitData:
      size = NSMakeSize(32, 32);
      samples = WBIconFamilyBitmapDataFor4BitData(data, size, planes);
      alpha = (useAlpha) ? [self dataForIconFamilyElement:kLarge1BitMask] : nil;
      break;
    case kLarge1BitData:
      size = NSMakeSize(32, 32);
      samples = WBIconFamilyBitmapDataFor1BitData(data, size, planes);
      alpha = (useAlpha) ? [self dataForIconFamilyElement:kLarge1BitMask] : nil;
      break;
    case kLarge8BitMask:
      useAlpha = NO;
      size = NSMakeSize(32, 32);
      samples = WBIconFamilyBitmapDataFor8BitMask(data, size, planes);
      break;
    case kLarge1BitMask:
      useAlpha = NO;
      size = NSMakeSize(32, 32);
      samples = WBIconFamilyBitmapDataFor1BitMask(data, size, planes);
      break;
      /* Small */
    case kSmall32BitData:
      size = NSMakeSize(16, 16);
      samples = WBIconFamilyBitmapDataFor32BitData(data, size, planes);
      break;
    case kSmall8BitData:
      size = NSMakeSize(16, 16);
      samples = WBIconFamilyBitmapDataFor8BitData(data, size, planes);
      alpha = (useAlpha) ? [self dataForIconFamilyElement:kSmall1BitMask] : nil;
      break;
    case kSmall4BitData:
      size = NSMakeSize(16, 16);
      samples = WBIconFamilyBitmapDataFor4BitData(data, size, planes);
      alpha = (useAlpha) ? [self dataForIconFamilyElement:kSmall1BitMask] : nil;
      break;
    case kSmall1BitData:
      size = NSMakeSize(16, 16);
      samples = WBIconFamilyBitmapDataFor1BitData(data, size, planes);
      alpha = (useAlpha) ? [self dataForIconFamilyElement:kSmall1BitMask] : nil;
      break;
    case kSmall8BitMask:
      useAlpha = NO;
      size = NSMakeSize(16, 16);
      samples = WBIconFamilyBitmapDataFor8BitMask(data, size, planes);
      break;
    case kSmall1BitMask:
      useAlpha = NO;
      size = NSMakeSize(16, 16);
      samples = WBIconFamilyBitmapDataFor1BitMask(data, size, planes);
      break;
      /* Mini */
    case kMini8BitData:
      size = NSMakeSize(16, 12);
      samples = WBIconFamilyBitmapDataFor8BitData(data, size, planes);
      alpha = (useAlpha) ? [self dataForIconFamilyElement:kMini1BitMask] : nil;
      break;
    case kMini4BitData:
      size = NSMakeSize(16, 12);
      samples = WBIconFamilyBitmapDataFor4BitData(data, size, planes);
      alpha = (useAlpha) ? [self dataForIconFamilyElement:kMini1BitMask] : nil;
      break;
    case kMini1BitData:
      size = NSMakeSize(16, 12);
      samples = WBIconFamilyBitmapDataFor1BitData(data, size, planes);
      alpha = (useAlpha) ? [self dataForIconFamilyElement:kMini1BitMask] : nil;
      break;
    case kMini1BitMask:
      useAlpha = NO;
      size = NSMakeSize(16, 12);
      samples = WBIconFamilyBitmapDataFor1BitMask(data, size, planes);
      break;
    default:
      WBThrowException(NSInvalidArgumentException, @"Unsupported Element type: %@", NSFileTypeForHFSTypeCode(anElement));
  }
  if (samples > 0) {
    if (useAlpha && ((samples == 1) || (samples == 3))) {
      if (alpha && WBIconFamilyBitmapDataFor1BitMask(alpha, size, planes + samples)) {
        samples++;
      }
      NSUInteger i, j;
      NSUInteger pixels = size.width * size.height;
      for (i=0; i<pixels; i++) {
        unsigned char a = (planes[samples-1][i] == 255) ? 1 : 0;
        for (j=0; j<(samples -1); j++) {
          /* Premultiply Alpha */
          planes[j][i] *= a;
        }
      }
    } else if (!useAlpha && samples == 4) {
      NSZoneFree(nil, planes[3]);
      samples = 3;
    }
    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:planes
                                                                       pixelsWide:size.width
                                                                       pixelsHigh:size.height
                                                                    bitsPerSample:8
                                                                  samplesPerPixel:samples
                                                                         hasAlpha:(samples == 4) || (samples == 2)
                                                                         isPlanar:YES
                                                                   colorSpaceName:(samples <= 2) ? NSDeviceBlackColorSpace : NSDeviceRGBColorSpace
                                                                      bytesPerRow:size.width
                                                                     bitsPerPixel:8];
    if (!bitmap) {
      for (NSUInteger i = 0; i < samples; i++) {
        NSZoneFree(nil, planes[i]);
      }
    }
    return [bitmap autorelease];
  }
  return nil;
}

- (BOOL)setIconFamilyElement:(OSType)anElement fromData:(NSData *)data {
  BOOL result = NO;
  Handle handle = nil;
  if (noErr == PtrToHand([data bytes], &handle, [data length])) {
    result = (noErr == SetIconFamilyData(wb_family, anElement, handle));
  }
  if (handle)
    DisposeHandle(handle);
  return result;
}

- (BOOL)setIconFamilyElement:(OSType)anElement fromImage:(NSImage *)anImage {
  WBIconFamilySelector selector = 0;
  switch (anElement) {
    /* 512 x 512 */
     case kIconServices512PixelDataARGB:
       selector = kWBSelectorARGB512PixelData;
       break;
    case kIconServices256PixelDataARGB: // 'ic08' 256x256 32-bits ARGB image
      selector = kWBSelectorARGB256PixelData;
      break;
      /******** Thumbnail *********/
    case kThumbnail32BitData: // 'it32' 128x128 32-bit ARGB image
      selector = kWBSelectorThumbnail32BitData;
      break;
    case kThumbnail8BitMask: // 't8mk' 128x128 8-bit alpha mask
      selector = kWBSelectorThumbnail8BitMask;
      break;
      /******** Huge *********/
    case kHuge32BitData: // 'ih32' 48x48 32-bit RGB image
      selector = kWBSelectorHuge32BitData;
      break;
    case kHuge8BitData:
      selector = kWBSelectorHuge8BitData;
      break;
    case kHuge4BitData:
      selector = kWBSelectorHuge4BitData;
      break;
    case kHuge1BitData:
      selector = kWBSelectorHuge1BitData;
      break;
    case kHuge8BitMask:
      selector = kWBSelectorHuge8BitMask;
      break;
    case kHuge1BitMask:
      selector = kWBSelectorHuge1BitMask;
      break;
      /******** Large *********/
    case kLarge32BitData: // 'il32' 32x32 32-bit RGB image
      selector = kWBSelectorLarge32BitData;
      break;
    case kLarge8BitData: // 'icl8' 32x32 8-bit indexed image data
      selector = kWBSelectorLarge8BitData;
      break;
    case kLarge4BitData: // 'icl4' 32x32 4-bit indexed image data
      selector = kWBSelectorLarge4BitData;
      break;
    case kLarge1BitData:
      selector = kWBSelectorLarge1BitData;
      break;
    case kLarge8BitMask: // 'l8mk' 32x32 8-bit alpha mask
      selector = kWBSelectorLarge8BitMask;
      break;
    case kLarge1BitMask: // 'ICN#' 32x32 1-bit alpha mask
      selector = kWBSelectorLarge1BitMask;
      break;
      /******** Small *********/
    case kSmall32BitData: // 'is32' 16x16 32-bit RGB image
      selector = kWBSelectorSmall32BitData;
      break;
    case kSmall8BitData: // 'ics8' 16x16 8-bit indexed image data
      selector = kWBSelectorSmall8BitData;
      break;
    case kSmall4BitData: // 'ics4' 16x16 4-bit indexed image data
      selector = kWBSelectorSmall4BitData;
      break;
    case kSmall1BitData: // 'ics4' 16x16 4-bit indexed image data
      selector = kWBSelectorSmall1BitData;
      break;
    case kSmall8BitMask: // 's8mk' 16x16 8-bit alpha mask
      selector = kWBSelectorSmall8BitMask;
      break;
    case kSmall1BitMask: // 'ics#' 16x16 1-bit alpha mask
      selector = kWBSelectorSmall1BitMask;
      break;
      /******** Mini *********/
    case kMini8BitData: // 'icm8' 16x12 8-bit indexed image data
      selector = kWBSelectorMini8BitData;
      break;
    case kMini4BitData: // 'icm4' 16x12 4-bit indexed image data
      selector = kWBSelectorMini4BitData;
      break;
    case kMini1BitData: // 'icm4' 16x12 4-bit indexed image data
      selector = kWBSelectorMini1BitData;
      break;
    case kMini1BitMask: // 'icm#' 16x12 1-bit alpha mask
      selector = kWBSelectorMini1BitMask;
      break;
    default:
      WBThrowException(NSInvalidArgumentException, @"Invalid element %@", NSFileTypeForHFSTypeCode(anElement));
  }
  return [self setIconFamilyElements:selector fromImage:anImage] > 0;
}

- (NSUInteger)setIconFamilyElements:(WBIconFamilySelector)selector fromImage:(NSImage *)anImage {
  id bitmap = nil;
  NSUInteger count = 0;
  /* 512 x 512 */
  if (selector & kWBSelectorARGB512PixelData) {
    bitmap = [self scaleImage:anImage toSize:NSMakeSize(512, 512)];
    count += [self setIconFamilyElement:kIconServices512PixelDataARGB fromBitmap:bitmap] ? 1 : 0;
  }
  /* 256 x 256 */
  if (selector & kWBSelectorARGB256PixelData) {
    bitmap = [self scaleImage:anImage toSize:NSMakeSize(256, 256)];
    count += [self setIconFamilyElement:kIconServices256PixelDataARGB fromBitmap:bitmap] ? 1 : 0;
  }
  /* Thumbnails */
  if (selector & kWBSelectorAllThumbnail) {
    bitmap = [self scaleImage:anImage toSize:NSMakeSize(128, 128)];
    if (selector & kWBSelectorThumbnail32BitData) count += [self setIconFamilyElement:kThumbnail32BitData fromBitmap:bitmap] ? 1 : 0;
    if (selector & kWBSelectorThumbnail8BitMask) count += [self setIconFamilyElement:kThumbnail8BitMask fromBitmap:bitmap] ? 1 : 0;
  }

  if (selector & kWBSelectorAllHuge) {
    bitmap = [self scaleImage:anImage toSize:NSMakeSize(48, 48)];
    /* Huge Data */
    if (selector & kWBSelectorHuge32BitData) count += [self setIconFamilyElement:kHuge32BitData fromBitmap:bitmap] ? 1 : 0;
    if (selector & kWBSelectorHuge8BitData) count += [self setIconFamilyElement:kHuge8BitData fromBitmap:bitmap] ? 1 : 0;
    if (selector & kWBSelectorHuge4BitData) count += [self setIconFamilyElement:kHuge4BitData fromBitmap:bitmap] ? 1 : 0;
    /* Huge Mask */
    if (selector & kWBSelectorHuge8BitMask) count += [self setIconFamilyElement:kHuge8BitMask fromBitmap:bitmap] ? 1 : 0;
    if (selector & (kWBSelectorHuge1BitData | kWBSelectorHuge1BitMask)) count += [self setIconFamilyElement:kHuge1BitMask fromBitmap:bitmap] ? 1 : 0;
  }

  if (selector & kWBSelectorAllLarge) {
    bitmap = [self scaleImage:anImage toSize:NSMakeSize(32, 32)];
    /* Large Data */
    if (selector & kWBSelectorLarge32BitData) count += [self setIconFamilyElement:kLarge32BitData fromBitmap:bitmap] ? 1 : 0;
    if (selector & kWBSelectorLarge8BitData) count += [self setIconFamilyElement:kLarge8BitData fromBitmap:bitmap] ? 1 : 0;
    if (selector & kWBSelectorLarge4BitData) count += [self setIconFamilyElement:kLarge4BitData fromBitmap:bitmap] ? 1 : 0;
    /* Large Mask */
    if (selector & kWBSelectorLarge8BitMask) count += [self setIconFamilyElement:kLarge8BitMask fromBitmap:bitmap] ? 1 : 0;
    if (selector & (kWBSelectorLarge1BitData | kWBSelectorLarge1BitMask)) count += [self setIconFamilyElement:kLarge1BitMask fromBitmap:bitmap] ? 1 : 0;
  }

  if (selector & kWBSelectorAllSmall) {
    bitmap = [self scaleImage:anImage toSize:NSMakeSize(16, 16)];
    /* Small Data */
    if (selector & kWBSelectorSmall32BitData) count += [self setIconFamilyElement:kSmall32BitData fromBitmap:bitmap] ? 1 : 0;
    if (selector & kWBSelectorSmall8BitData) count += [self setIconFamilyElement:kSmall8BitData fromBitmap:bitmap] ? 1 : 0;
    if (selector & kWBSelectorSmall4BitData) count += [self setIconFamilyElement:kSmall4BitData fromBitmap:bitmap] ? 1 : 0;
    /* Small Mask */
    if (selector & kWBSelectorSmall8BitMask) count += [self setIconFamilyElement:kSmall8BitMask fromBitmap:bitmap] ? 1 : 0;
    if (selector & (kWBSelectorSmall1BitData | kWBSelectorSmall1BitMask)) count += [self setIconFamilyElement:kSmall1BitMask fromBitmap:bitmap] ? 1 : 0;
  }

  if (selector & kWBSelectorAllMini) {
    bitmap = [self scaleImage:anImage toSize:NSMakeSize(16, 12)];
    /* Mini Data */
    if (selector & kWBSelectorMini8BitData) count += [self setIconFamilyElement:kMini8BitData fromBitmap:bitmap] ? 1 : 0;
    if (selector & kWBSelectorMini4BitData) count += [self setIconFamilyElement:kMini4BitData fromBitmap:bitmap] ? 1 : 0;
    /* Mini Mask */
    if (selector & (kWBSelectorMini1BitData | kWBSelectorMini1BitMask)) count += [self setIconFamilyElement:kMini1BitMask fromBitmap:bitmap] ? 1 : 0;
  }
  return count;
}

- (BOOL)setIconFamilyElement:(OSType)anElement fromBitmap:(NSBitmapImageRep *)bitmap {
  NSSize size = NSMakeSize([bitmap pixelsWide], [bitmap pixelsHigh]);
  Handle handle = nil;
  switch (anElement) {
    /* 512 x 512 */
     case kIconServices512PixelDataARGB:
       if (NSEqualSizes(size, NSMakeSize(512, 512))) {
         handle = WBIconFamilyGet32BitDataForBitmap(bitmap);
       }
       break;
    /* 256 x 256 */
    case kIconServices256PixelDataARGB: // 'ic08' 256x256 32-bits ARGB image
      if (NSEqualSizes(size, NSMakeSize(256, 256))) {
        handle = WBIconFamilyGet32BitDataForBitmap(bitmap);
      }
      break;
      /******** Thumbnail *********/
    case kThumbnail32BitData: // 'it32' 128x128 32-bit ARGB image
      if (NSEqualSizes(size, NSMakeSize(128, 128))) {
        handle = WBIconFamilyGet32BitDataForBitmap(bitmap);
      }
      break;
    case kThumbnail8BitMask: // 't8mk' 128x128 8-bit alpha mask
      if (NSEqualSizes(size, NSMakeSize(128, 128))) {
        handle = WBIconFamilyGet8BitMaskForBitmap(bitmap);
      }
      break;
      /******** Huge *********/
    case kHuge32BitData: // 'ih32' 48x48 32-bit RGB image
      if (NSEqualSizes(size, NSMakeSize(48, 48))) {
        handle = WBIconFamilyGet32BitDataForBitmap(bitmap);
      }
      break;
    case kHuge8BitData:
      if (NSEqualSizes(size, NSMakeSize(48, 48))) {
        handle = WBIconFamilyGet8BitDataForBitmap(bitmap);
      }
      break;
    case kHuge4BitData:
      if (NSEqualSizes(size, NSMakeSize(48, 48))) {
        handle = WBIconFamilyGet4BitDataForBitmap(bitmap);
      }
      break;
    case kHuge8BitMask:
      if (NSEqualSizes(size, NSMakeSize(48, 48))) {
        handle = WBIconFamilyGet8BitMaskForBitmap(bitmap);
      }
      break;
    case kHuge1BitData:
    case kHuge1BitMask:
      if (NSEqualSizes(size, NSMakeSize(48, 48))) {
        handle = WBIconFamilyGet1BitDataAndMaskForBitmap(bitmap);
      }
      break;
      /******** Large *********/
    case kLarge32BitData: // 'il32' 32x32 32-bit RGB image
      if (NSEqualSizes(size, NSMakeSize(32, 32))) {
        handle = WBIconFamilyGet32BitDataForBitmap(bitmap);
      }
      break;
    case kLarge8BitData: // 'icl8' 32x32 8-bit indexed image data
      if (NSEqualSizes(size, NSMakeSize(32, 32))) {
        handle = WBIconFamilyGet8BitDataForBitmap(bitmap);
      }
      break;
    case kLarge4BitData: // 'icl4' 32x32 4-bit indexed image data
      if (NSEqualSizes(size, NSMakeSize(32, 32))) {
        handle = WBIconFamilyGet4BitDataForBitmap(bitmap);
      }
      break;
    case kLarge8BitMask: // 'l8mk' 32x32 8-bit alpha mask
      if (NSEqualSizes(size, NSMakeSize(32, 32))) {
        handle = WBIconFamilyGet8BitMaskForBitmap(bitmap);
      }
      break;
    case kLarge1BitData:
    case kLarge1BitMask: // 'ICN#' 32x32 1-bit alpha mask
      if (NSEqualSizes(size, NSMakeSize(32, 32))) {
        handle = WBIconFamilyGet1BitDataAndMaskForBitmap(bitmap);
      }
      break;
      /******** Small *********/
    case kSmall32BitData: // 'is32' 16x16 32-bit RGB image
      if (NSEqualSizes(size, NSMakeSize(16, 16))) {
        handle = WBIconFamilyGet32BitDataForBitmap(bitmap);
      }
      break;
    case kSmall8BitData: // 'ics8' 16x16 8-bit indexed image data
      if (NSEqualSizes(size, NSMakeSize(16, 16))) {
        handle = WBIconFamilyGet8BitDataForBitmap(bitmap);
      }
      break;
    case kSmall4BitData: // 'ics4' 16x16 4-bit indexed image data
      if (NSEqualSizes(size, NSMakeSize(16, 16))) {
        handle = WBIconFamilyGet4BitDataForBitmap(bitmap);
      }
      break;
    case kSmall8BitMask: // 's8mk' 16x16 8-bit alpha mask
      if (NSEqualSizes(size, NSMakeSize(16, 16))) {
        handle = WBIconFamilyGet8BitMaskForBitmap(bitmap);
      }
      break;
    case kSmall1BitData:
    case kSmall1BitMask: // 'ics#' 16x16 1-bit alpha mask
      if (NSEqualSizes(size, NSMakeSize(16, 16))) {
        handle = WBIconFamilyGet1BitDataAndMaskForBitmap(bitmap);
      }
      break;
      /******** Mini *********/
    case kMini8BitData: // 'icm8' 16x12 8-bit indexed image data
      if (NSEqualSizes(size, NSMakeSize(16, 12))) {
        handle = WBIconFamilyGet8BitDataForBitmap(bitmap);
      }
      break;
    case kMini4BitData: // 'icm4' 16x12 4-bit indexed image data
      if (NSEqualSizes(size, NSMakeSize(16, 12))) {
        handle = WBIconFamilyGet4BitDataForBitmap(bitmap);
      }
      break;
    case kMini1BitData:
    case kMini1BitMask: // 'icm#' 16x12 1-bit alpha mask
      if (NSEqualSizes(size, NSMakeSize(16, 12))) {
        handle = WBIconFamilyGet1BitDataAndMaskForBitmap(bitmap);
      }
      break;
    default:
      WBThrowException(NSInvalidArgumentException, @"Invalid element %@", NSFileTypeForHFSTypeCode(anElement));
  }

  if (handle == NULL) {
    DLog(@"Unable to retreive data from image.");
    return NO;
  }

  OSStatus err = SetIconFamilyData(wb_family, anElement, handle);
  DisposeHandle(handle);
  DLog(@"Set Icon FamilyElement: %@ => returns: %d", NSFileTypeForHFSTypeCode(anElement), err);
  return noErr == err;
}

- (NSImage *)imageWithAllRepresentations {
  id data = [[NSData alloc] initWithHandle:(Handle)wb_family];
  id image = [[NSImage alloc] initWithData:data];
  [data release];
  return (image) ? [image autorelease] : nil;
}

#pragma mark -
#pragma mark Set As Custom Icon
#pragma mark  ** At Path **
- (BOOL)setAsCustomIconAtPath:(NSString*)path {
  return [self setAsCustomIconAtPath:path withCompatibility:NO];
}

- (BOOL)setAsCustomIconAtPath:(NSString*)path withCompatibility:(BOOL)compat {
  return WBIconFamilySetIconAtPath(wb_family, (CFStringRef)[path stringByExpandingTildeInPath], compat);
}

#pragma mark ** For File **
- (BOOL)setAsCustomIconForFile:(NSString*)path {
  return [self setAsCustomIconForFile:path withCompatibility:NO];
}

- (BOOL)setAsCustomIconForFile:(NSString*)path withCompatibility:(BOOL)compat {
  FSRef fileRef;
  if ([[path stringByExpandingTildeInPath] getFSRef:&fileRef traverseLink:NO]) {
    return WBIconFamilySetFileIcon(&fileRef, wb_family, compat);
  }
  return NO;
}

#pragma mark ** For Directory **
- (BOOL)setAsCustomIconForDirectory:(NSString*)path {
  return [self setAsCustomIconForDirectory:path withCompatibility:NO];
}

- (BOOL)setAsCustomIconForDirectory:(NSString*)path withCompatibility:(BOOL)compat {
  FSRef fileRef;
  if ([[path stringByExpandingTildeInPath] getFSRef:&fileRef traverseLink:NO]) {
    return WBIconFamilySetFolderIcon(&fileRef, wb_family, compat);
  }
  return NO;
}

#pragma mark -
#pragma mark Remove Custom Icon
+ (BOOL)removeCustomIconAtPath:(NSString *)path {
  return WBIconFamilyRemoveIconAtPath((CFStringRef)[path stringByExpandingTildeInPath]);
}

#pragma mark -
#pragma mark Scaling Method
- (id)delegate {
  return wb_delegate;
}
- (void)setDelegate:(id)delegate {
  wb_delegate = delegate;
}

- (NSBitmapImageRep *)scaleImage:(NSImage *)anImage toSize:(NSSize)size {
  NSBitmapImageRep *bitmap = nil;
  if (WBDelegateHandle(wb_delegate, iconFamily:shouldScaleImage:toSize:)) {
    bitmap = [wb_delegate iconFamily:self shouldScaleImage:anImage toSize:size];
  }
//  if (!bitmap)
//    bitmap = WBImageResizeImage(anImage, size);
  return bitmap;
}

@end

#pragma mark -
#pragma mark Variants LowLevel Manipulation
static NSMutableArray *WBIconFamilyFindVariants(IconFamilyResource *rsrc) {
  id variants = [[NSMutableArray alloc] init];
  OSType rsrcType = WBIconFamilyResourceGetType(rsrc);

  WBIconFamilyIterator iterator;
  IconFamilyElement *elt = NULL;
  WBIconFamilyIteratorInit(&iterator, rsrc);
  while ((elt = WBIconFamilyIteratorNextElement(&iterator))) {
    OSType type = WBIconFamilyElementGetType(elt);
    if (WBIsIconVariantType(type)) {
      if (rsrcType == kIconFamilyType || type != kTileIconVariant) {
        [variants addObject:WBUInteger(type)];
      }
      [variants addObjectsFromArray:WBIconFamilyFindVariants((IconFamilyResource *)elt)];
    }
  }
  return [variants autorelease];
}

static BOOL WBIconFamilyContainsVariant(IconFamilyResource *rsrc, OSType variant) {
  WBIconFamilyIterator iterator;
  IconFamilyElement *elt = NULL;
  WBIconFamilyIteratorInit(&iterator, rsrc);
  while ((elt = WBIconFamilyIteratorNextElement(&iterator))) {
    OSType type = WBIconFamilyElementGetType(elt);
    if (WBIsIconVariantType(type)) {
      if (variant == type) {
        return YES;
      } else if (kTileIconVariant != variant) {
        return WBIconFamilyContainsVariant((IconFamilyResource *)elt, variant);
      }
    }
  }
  return NO;
}

static IconFamilyHandle WBIconFamilyCopyVariant(IconFamilyResource *rsrc, OSType variant) {
  IconFamilyHandle icon = nil;
  WBIconFamilyIterator iterator;
  IconFamilyElement *elt = NULL;
  WBIconFamilyIteratorInit(&iterator, rsrc);
  while ((elt = WBIconFamilyIteratorNextElement(&iterator))) {
    OSType type = WBIconFamilyElementGetType(elt);
    if (elt && WBIsIconVariantType(type)) {
      if (variant == type) {
        PtrToHand(elt, (Handle *)&icon, WBIconFamilyElementGetSize(elt));
        return icon;
      } else if (kTileIconVariant != variant) {
        icon = WBIconFamilyCopyVariant((IconFamilyResource *)elt, variant);
        if (icon) return icon;
      }
    }
  }
  return nil;
}

static BOOL WBIconFamilyRemoveVariant(IconFamilyResource *rsrc, OSType aVariant, IconFamilyHandle result) {
  if (!WBIconFamilyContainsVariant(rsrc, aVariant)) {
    return NO;
  }
  PtrAndHand((Handle)rsrc, (Handle)result, 8); // Copy header

  WBIconFamilyIterator iterator;
  IconFamilyElement *elt = NULL;
  WBIconFamilyIteratorInit(&iterator, rsrc);
  while ((elt = WBIconFamilyIteratorNextElement(&iterator))) {
    OSType type = WBIconFamilyElementGetType(elt);
    if (WBIsIconVariantType(type)) {
      if (aVariant == type) {
        id variants = [WBIconFamilyFindVariants((IconFamilyResource *)elt) objectEnumerator];
        OSType variant;
        while ((variant = [[variants nextObject] unsignedIntValue])) {
          if (variant != kTileIconVariant) { // On n'importe pas les Tiles (normalement ils ne sont pas ds le tableau).
            Handle tmp = (Handle)WBIconFamilyCopyVariant((IconFamilyResource *)elt, variant);
            if (tmp) {
              HandAndHand(tmp, (Handle)result);
              DisposeHandle(tmp);
            }
          }
        }
      } else if (aVariant != kTileIconVariant && WBIconFamilyContainsVariant(rsrc, aVariant)) { // On ne supprime les tiles des variants
                                                                                                // Si pas la rsrc à supprimer, on recupere la bon dans tmp;
        IconFamilyHandle tmp = (IconFamilyHandle)NewHandle(0);
        WBIconFamilyRemoveVariant((IconFamilyResource *)elt, aVariant, tmp);
        HandAndHand((Handle)tmp, (Handle)result);
        DisposeHandle((Handle)tmp);
      } else { // Ne contient pas la variante à supprimer
        PtrAndHand(elt, (Handle)result, WBIconFamilyElementGetSize(elt));
      }
    } else { // Si rsrc n'est pas une variante
      PtrAndHand(elt, (Handle)result, WBIconFamilyElementGetSize(elt));
    }
  }
  HLock((Handle)result);
  IconFamilyResource *resultRsrc = WBIconFamilyGetFamilyResource(result);
  WBIconFamilyResourceSetSize(resultRsrc, (SInt32)GetHandleSize((Handle)result));
  HUnlock((Handle)result);
  return YES;
}
