/*
 *  WBCGFunctions.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#if !defined(__WB_CG_FUNCTIONS_H)
#define __WB_CG_FUNCTIONS_H 1

#include <WonderBox/WBBase.h>
#include <WonderBox/WBGeometry.h>

#include <ApplicationServices/ApplicationServices.h>

__BEGIN_DECLS

// MARK: Shapes
WB_EXPORT
void WBCGContextAddRoundRect(CGContextRef context, CGRect rect, CGFloat radius);

WB_EXPORT
void WBCGPathAddRoundRect(CGMutablePathRef path, const CGAffineTransform *transform, CGRect rect, CGFloat radius);

WB_EXPORT
void WBCGContextAddRoundRectWithRadius(CGContextRef context, CGRect rect, CGSize radius);

WB_EXPORT
void WBCGPathAddRoundRectWithRadius(CGMutablePathRef path, const CGAffineTransform *transform, CGRect rect, CGSize radius);

WB_EXPORT
void WBCGContextAddStar(CGContextRef ctxt, CGPoint center, CFIndex sides, CGFloat radius, CGFloat internRadius);

WB_EXPORT
void WBCGPathAddStar(CGMutablePathRef path, const CGAffineTransform *transform, CGPoint center, CFIndex sides, CGFloat radius, CGFloat internRadius);

WB_EXPORT
void WBCGContextStrokeWaves(CGContextRef context, CGRect rect, CGFloat period);

/* Helpers */
WB_EXPORT
void WBCGContextStrokeLine(CGContextRef ctxt, CGFloat x, CGFloat y, CGFloat x2, CGFloat y2);

// MARK: Color Spaces
WB_INLINE
CGColorSpaceRef WBCGColorSpaceCreateGray(void) {
  return CGColorSpaceCreateWithName(kCGColorSpaceGenericGray);
}
WB_INLINE
CGColorSpaceRef WBCGColorSpaceCreateRGB(void) {
  return CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
}
WB_INLINE
CGColorSpaceRef WBCGColorSpaceCreateCMYK(void) {
  return CGColorSpaceCreateWithName(kCGColorSpaceGenericCMYK);
}

// MARK: Color
WB_EXPORT
CGColorRef WBCGColorCreateGray(CGFloat white, CGFloat alpha);
WB_EXPORT
CGColorRef WBCGColorCreateRGB(CGFloat red, CGFloat green, CGFloat blue, CGFloat alpha);
WB_EXPORT
CGColorRef WBCGColorCreateCMYK(CGFloat cyan, CGFloat magenta, CGFloat yellow, CGFloat black, CGFloat alpha);

// MARK: Layer
WB_EXPORT
CGImageRef WBCGLayerCreateImage(CGLayerRef layer);

// MARK: Images
/*!
 @param type The UTI (uniform type identifier) of the resulting image file.
 */
WB_EXPORT
bool WBCGImageWriteToURL(CGImageRef image, CFURLRef url, CFStringRef type);
WB_EXPORT
bool WBCGImageWriteToFile(CGImageRef image, CFStringRef file, CFStringRef type);
WB_EXPORT
CGImageRef WBCGImageCreateFromURL(CFURLRef url, CFDictionaryRef options);

WB_EXPORT
CFDataRef WBCGImageCopyTIFFRepresentation(CGImageRef anImage);

#if (__OBJC__)

@interface NSGraphicsContext (WBCGContextRef)
+ (CGContextRef)currentGraphicsPort;
@end

#endif

__END_DECLS

#endif /* __WB_CG_FUNCTIONS_H */
