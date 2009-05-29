/*
 *  WBCGFunctions.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#if !defined(__WBCG_FUNCTIONS_H)
#define __WBCG_FUNCTIONS_H 1

#include <ApplicationServices/ApplicationServices.h>
#import WBHEADER(WBGeometry.h)

#pragma mark Shapes
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

#pragma mark Color Spaces
WB_EXPORT
CGColorSpaceRef WBCGColorSpaceCreateGray(void);
WB_EXPORT
CGColorSpaceRef WBCGColorSpaceCreateRGB(void);
WB_EXPORT
CGColorSpaceRef WBCGColorSpaceCreateCMYK(void);

#pragma mark Color
WB_EXPORT
CGColorRef WBCGColorCreateGray(CGFloat white, CGFloat alpha);
WB_EXPORT
CGColorRef WBCGColorCreateRGB(CGFloat red, CGFloat green, CGFloat blue, CGFloat alpha);
WB_EXPORT
CGColorRef WBCGColorCreateCMYK(CGFloat cyan, CGFloat magenta, CGFloat yellow, CGFloat black, CGFloat alpha);

#pragma mark Layer
WB_EXPORT
CGLayerRef WBCGLayerCreateWithContext(CGContextRef ctxt, CGSize size, CFDictionaryRef auxiliaryInfo, bool scaleToUserSpace);

WB_EXPORT
CGImageRef WBCGLayerCreateImage(CGLayerRef layer);

#pragma mark Images
/*!
 @param type The UTI (uniform type identifier) of the resulting image file.
 */
WB_EXPORT
bool WBCGImageWriteToURL(CGImageRef image, CFURLRef url, CFStringRef type);
WB_EXPORT
bool WBCGImageWriteToFile(CGImageRef image, CFStringRef file, CFStringRef type);
WB_EXPORT 
CGImageRef WBCGImageCreateFromURL(CFURLRef url, CFDictionaryRef options);


#endif /* __WBCGFUNCTIONS_H */
