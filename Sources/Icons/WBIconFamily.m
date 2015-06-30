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
#import <WonderBox/WBIconFamily.h>
#import <WonderBox/WBIconFunctions.h>

#import <WonderBox/WBFSFunctions.h>
#import <WonderBox/NSData+WonderBox.h>
// #import <WonderBox/WBImageFunctions.h>

#pragma mark -
static NSMutableArray *WBIconFamilyFindVariants(IconFamilyResource *rsrc);
static BOOL WBIconFamilyContainsVariant(IconFamilyResource *rsrc, OSType variant);
static IconFamilyHandle WBIconFamilyCopyVariant(IconFamilyResource *rsrc, OSType variant);
static BOOL WBIconFamilyRemoveVariant(IconFamilyResource *rsrc, OSType variant, IconFamilyHandle result);

#pragma mark -
@implementation WBIconFamily {
@private
  id wb_delegate;
  IconFamilyHandle wb_family;
}

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
  return [self initWithThumbnailsOfImage:anImage forElements:kWBSelectorAll];
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
    WBIconFamily *family = [WBIconFamily iconFamilyWithIconFamilyHandle:icon];
    DisposeHandle((Handle)icon);
    return family;
  }
  return nil;
}

- (BOOL)setIconFamilyVariant:(WBIconFamily *)aFamily forType:(OSType)aVariant {
  OSStatus err;
  if (!WBIsIconVariantType(aVariant)) {
    SPXThrowException(NSInvalidArgumentException, @"%@ isn't a valid Variant type", NSFileTypeForHFSTypeCode(aVariant));
  }
  if (!aFamily) {
    SPXThrowException(NSInvalidArgumentException, @"aFamily cannot be nil");
  }
  if ([self containsVariant:aVariant]) {
    if (![self removeVariant:aVariant]) {
      SPXDebug(@"Unable to remove old variant");
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
    SPXThrowException(NSInvalidArgumentException, @"iconfamily Handle cannot be nil");
  }
  if (nil != wb_family) {
    DisposeHandle((Handle)wb_family);
  }
  wb_family = newIconFamily;
  OSErr err = HandToHand((Handle *)&wb_family);
  if (noErr != err) {
    wb_family = nil;
    SPXThrowException(NSMallocException, @"Exception while copying Handle: %d", err);
  }
  WBIconFamilyResourceSetType(WBIconFamilyGetFamilyResource(wb_family), kIconFamilyType);
}

#pragma mark -
#pragma mark Write To File
- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)flag {
  NSData *data = [[NSData alloc] initWithHandle:(Handle)wb_family];
  BOOL wrote = [data writeToFile:path atomically:flag];
  [data release];
  return wrote;
}

#pragma mark -
#pragma mark Elements Manipulation
- (NSData *)dataForIconFamilyElement:(OSType)anElement {
  NSData *data = nil;
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
    /* 1024 x 1024 */
    case kIconServices1024PixelDataARGB:
      size = NSMakeSize(1024, 1024);
      samples = WBIconFamilyBitmapDataFor32BitData(data, size, planes);
      break;
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
    case kHuge8BitMask:
      useAlpha = NO;
      size = NSMakeSize(48, 48);
      samples = WBIconFamilyBitmapDataFor8BitMask(data, size, planes);
      break;

      /* Large */
    case kLarge32BitData:
      size = NSMakeSize(32, 32);
      samples = WBIconFamilyBitmapDataFor32BitData(data, size, planes);
      break;
    case kLarge8BitMask:
      useAlpha = NO;
      size = NSMakeSize(32, 32);
      samples = WBIconFamilyBitmapDataFor8BitMask(data, size, planes);
      break;

      /* Small */
    case kSmall32BitData:
      size = NSMakeSize(16, 16);
      samples = WBIconFamilyBitmapDataFor32BitData(data, size, planes);
      break;
    case kSmall8BitMask:
      useAlpha = NO;
      size = NSMakeSize(16, 16);
      samples = WBIconFamilyBitmapDataFor8BitMask(data, size, planes);
      break;

    default:
      SPXThrowException(NSInvalidArgumentException, @"Unsupported Element type: %@", NSFileTypeForHFSTypeCode(anElement));
  }
  if (samples > 0) {
    if (useAlpha && samples == 3) {
      if (alpha && WBIconFamilyBitmapDataFor8BitMask(alpha, size, planes + samples))
        samples++;
    } else if (!useAlpha && samples == 4) {
      free(planes[3]);
      samples = 3;
    }
    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:planes
                                                                       pixelsWide:size.width
                                                                       pixelsHigh:size.height
                                                                    bitsPerSample:8
                                                                  samplesPerPixel:samples
                                                                         hasAlpha:(samples == 4)
                                                                         isPlanar:YES
                                                                   colorSpaceName:NSDeviceRGBColorSpace
                                                                     bitmapFormat:(samples == 4) ? NSAlphaNonpremultipliedBitmapFormat : 0
                                                                      bytesPerRow:size.width
                                                                     bitsPerPixel:8];
    if (!bitmap) {
      for (NSUInteger i = 0; i < samples; i++) {
        free(planes[i]);
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
    case kIconServices1024PixelDataARGB:
      selector = kWBSelector1024ARGB;
      break;
      /* 512 x 512 */
    case kIconServices512PixelDataARGB:
      selector = kWBSelector512ARGB;
      break;
    case kIconServices256PixelDataARGB: // 'ic08' 256x256 32-bits ARGB image
      selector = kWBSelector256ARGB;
      break;
      /******** Thumbnail *********/
    case kThumbnail32BitData: // 'it32' 128x128 32-bit ARGB image
      selector = kWBSelector128Data;
      break;
    case kThumbnail8BitMask: // 't8mk' 128x128 8-bit alpha mask
      selector = kWBSelector128Mask;
      break;
      /******** Huge *********/
    case kHuge32BitData: // 'ih32' 48x48 32-bit RGB image
      selector = kWBSelector48Data;
      break;
    case kHuge8BitMask:
      selector = kWBSelector48Mask;
      break;
      /******** Large *********/
    case kLarge32BitData: // 'il32' 32x32 32-bit RGB image
      selector = kWBSelector32Data;
      break;
    case kLarge8BitMask: // 'l8mk' 32x32 8-bit alpha mask
      selector = kWBSelector32Mask;
      break;
      /******** Small *********/
    case kSmall32BitData: // 'is32' 16x16 32-bit RGB image
      selector = kWBSelector16Data;
      break;
    case kSmall8BitMask: // 's8mk' 16x16 8-bit alpha mask
      selector = kWBSelector16Mask;
      break;
    default:
      SPXThrowException(NSInvalidArgumentException, @"Invalid element %@", NSFileTypeForHFSTypeCode(anElement));
  }
  return [self setIconFamilyElements:selector fromImage:anImage] > 0;
}

- (NSUInteger)setIconFamilyElements:(WBIconFamilySelector)selector fromImage:(NSImage *)anImage {
  id bitmap = nil;
  NSUInteger count = 0;
  /* 512 x 512 */
  if (selector & kWBSelector1024ARGB) {
    bitmap = [self scaleImage:anImage toSize:NSMakeSize(1024, 1024)];
    count += [self setIconFamilyElement:kIconServices1024PixelDataARGB fromBitmap:bitmap] ? 1 : 0;
  }
  /* 512 x 512 */
  if (selector & kWBSelector512ARGB) {
    bitmap = [self scaleImage:anImage toSize:NSMakeSize(512, 512)];
    count += [self setIconFamilyElement:kIconServices512PixelDataARGB fromBitmap:bitmap] ? 1 : 0;
  }
  /* 256 x 256 */
  if (selector & kWBSelector256ARGB) {
    bitmap = [self scaleImage:anImage toSize:NSMakeSize(256, 256)];
    count += [self setIconFamilyElement:kIconServices256PixelDataARGB fromBitmap:bitmap] ? 1 : 0;
  }
  /* Thumbnails */
  if (selector & kWBSelector128) {
    bitmap = [self scaleImage:anImage toSize:NSMakeSize(128, 128)];
    if (selector & kWBSelector128Data) count += [self setIconFamilyElement:kThumbnail32BitData fromBitmap:bitmap] ? 1 : 0;
    if (selector & kWBSelector128Mask) count += [self setIconFamilyElement:kThumbnail8BitMask fromBitmap:bitmap] ? 1 : 0;
  }

  if (selector & kWBSelector48) {
    bitmap = [self scaleImage:anImage toSize:NSMakeSize(48, 48)];
    if (selector & kWBSelector48Data) count += [self setIconFamilyElement:kHuge32BitData fromBitmap:bitmap] ? 1 : 0;
    if (selector & kWBSelector48Mask) count += [self setIconFamilyElement:kHuge8BitMask fromBitmap:bitmap] ? 1 : 0;
  }

  if (selector & kWBSelector32) {
    bitmap = [self scaleImage:anImage toSize:NSMakeSize(32, 32)];
    if (selector & kWBSelector32Data) count += [self setIconFamilyElement:kLarge32BitData fromBitmap:bitmap] ? 1 : 0;
    if (selector & kWBSelector32Mask) count += [self setIconFamilyElement:kLarge8BitMask fromBitmap:bitmap] ? 1 : 0;
  }

  if (selector & kWBSelector16) {
    bitmap = [self scaleImage:anImage toSize:NSMakeSize(16, 16)];
    if (selector & kWBSelector16Data) count += [self setIconFamilyElement:kSmall32BitData fromBitmap:bitmap] ? 1 : 0;
    if (selector & kWBSelector16Mask) count += [self setIconFamilyElement:kSmall8BitMask fromBitmap:bitmap] ? 1 : 0;
  }

  return count;
}

- (BOOL)setIconFamilyElement:(OSType)anElement fromBitmap:(NSBitmapImageRep *)bitmap {
  NSSize size = NSMakeSize([bitmap pixelsWide], [bitmap pixelsHigh]);
  Handle handle = nil;
  switch (anElement) {
      /* 1024 x 1024 */
    case kIconServices1024PixelDataARGB:
      if (NSEqualSizes(size, NSMakeSize(1024, 1024))) {
        handle = WBIconFamilyGet32BitDataForBitmap(bitmap);
      }
      break;
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
    case kHuge8BitMask:
      if (NSEqualSizes(size, NSMakeSize(48, 48))) {
        handle = WBIconFamilyGet8BitMaskForBitmap(bitmap);
      }
      break;
      /******** Large *********/
    case kLarge32BitData: // 'il32' 32x32 32-bit RGB image
      if (NSEqualSizes(size, NSMakeSize(32, 32))) {
        handle = WBIconFamilyGet32BitDataForBitmap(bitmap);
      }
      break;
    case kLarge8BitMask: // 'l8mk' 32x32 8-bit alpha mask
      if (NSEqualSizes(size, NSMakeSize(32, 32))) {
        handle = WBIconFamilyGet8BitMaskForBitmap(bitmap);
      }
      break;
      /******** Small *********/
    case kSmall32BitData: // 'is32' 16x16 32-bit RGB image
      if (NSEqualSizes(size, NSMakeSize(16, 16))) {
        handle = WBIconFamilyGet32BitDataForBitmap(bitmap);
      }
      break;
    case kSmall8BitMask: // 's8mk' 16x16 8-bit alpha mask
      if (NSEqualSizes(size, NSMakeSize(16, 16))) {
        handle = WBIconFamilyGet8BitMaskForBitmap(bitmap);
      }
      break;
    default:
      SPXThrowException(NSInvalidArgumentException, @"Invalid element %@", NSFileTypeForHFSTypeCode(anElement));
  }

  if (handle == NULL) {
    SPXDebug(@"Unable to retreive data from image.");
    return NO;
  }

  OSStatus err = SetIconFamilyData(wb_family, anElement, handle);
  DisposeHandle(handle);
  SPXDebug(@"Set Icon FamilyElement: %@ => returns: %d", NSFileTypeForHFSTypeCode(anElement), err);
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
  if (SPXDelegateHandle(wb_delegate, iconFamily:shouldScaleImage:toSize:)) {
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
        [variants addObject:@(type)];
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
