/*
 *  WBGeometry.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#if !defined (__WB_GEOMETRY_H)
#define __WB_GEOMETRY_H 1

#include <WonderBox/WBBase.h>

#include <ApplicationServices/ApplicationServices.h>

__BEGIN_DECLS

#pragma mark -
WB_INLINE
CGSize WBMaxSizeForSizes(CGSize s1, CGSize s2) {
  CGSize s;
  s.width = s1.width < s2.width ? s2.width : s1.width;
  s.height = s1.height < s2.height ? s2.height : s1.height;
  return s;
}

WB_INLINE
CGSize WBMinSizeForSizes(CGSize s1, CGSize s2) {
  CGSize s;
  s.width = s1.width < s2.width ? s1.width : s2.width;
  s.height = s1.height < s2.height ? s1.height : s2.height;
  return s;
}


#pragma mark Scaling
enum {
  kWBScalingModeProportionallyFit = 0, // default
  kWBScalingModeProportionallyFill,
  kWBScalingModeProportionallyFitDown,
  kWBScalingModeProportionallyFillDown,
  kWBScalingModeAxesIndependently,
  kWBScalingModeNone,
};
typedef uint32_t WBScalingMode;

enum {
  kWBRectAlignCenter = 0,
  kWBRectAlignTop,
  kWBRectAlignTopLeft,
  kWBRectAlignTopRight,
  kWBRectAlignLeft,
  kWBRectAlignBottom,
  kWBRectAlignBottomLeft,
  kWBRectAlignBottomRight,
  kWBRectAlignRight
};
typedef uint32_t WBRectAlignment;

WB_EXPORT
CGRect WBRectAlignToRect(CGRect alignee, CGRect aligner, WBRectAlignment mode);

WB_INLINE
CGSize WBSizeScale(CGSize source, CGFloat xScale, CGFloat yScale) {
  return CGSizeMake(source.width * xScale, source.height * yScale);
}

WB_EXPORT
CGSize WBSizeScaleToSize(CGSize source, CGSize dest, WBScalingMode mode);

WB_INLINE
CGRect WBRectScale(CGRect inRect, CGFloat xScale, CGFloat yScale) {
  inRect.size = WBSizeScale(inRect.size, xScale, yScale);
  return inRect;
}

WB_INLINE
CGRect WBRectScaleToSize(CGRect source, CGSize size, WBScalingMode mode) {
  source.size = WBSizeScaleToSize(source.size, size, mode);
  return source;
}

WB_INLINE
CGRect WBRectScaleToRect(CGRect source, CGRect dest, WBScalingMode mode, WBRectAlignment align) {
  return WBRectAlignToRect(WBRectScaleToSize(source, dest.size, mode), dest, align);
}

WB_INLINE
CGRect WBSizeScaleToRect(CGSize source, CGRect dest, WBScalingMode mode, WBRectAlignment align) {
  CGRect result = CGRectZero;
  result.size = WBSizeScaleToSize(source, dest.size, mode);
  return WBRectAlignToRect(result, dest, align);
}

#pragma mark -
WB_EXPORT
CGSize WBCGContextGetUserSpaceScaleFactor(CGContextRef ctxt);
WB_EXPORT
void WBCGContextSetLinePixelWidth(CGContextRef context, CGFloat width);

WB_INLINE
CGRect WBCGContextIntegralPixelRect(CGContextRef aContext, CGRect aRect) {
  aRect = CGContextConvertRectToDeviceSpace(aContext, aRect);
  aRect = CGRectIntegral(aRect);
  return CGContextConvertRectToUserSpace(aContext, aRect);
}

WB_INLINE
CGFloat WBCGPointRoundToPixel(CGFloat point, CGFloat factor, CGFloat shift) {
  return (round(point * factor) + shift) / factor;
}
WB_INLINE
CGFloat WBCGPointFloorToPixel(CGFloat point, CGFloat factor, CGFloat shift) {
  return (floor(point * factor) + shift) / factor;
}
WB_INLINE
CGFloat WBCGPointCeilToPixel(CGFloat point, CGFloat factor, CGFloat shift) {
  return (ceil(point * factor) + shift) / factor;
}

WB_INLINE
CGRect WBCGRectRoundIntegral(CGRect aRect, CGFloat factor) {
  return CGRectMake(round(aRect.origin.x * factor) / factor,
                    round(aRect.origin.y * factor) / factor,
                    round(aRect.size.width * factor) / factor,
                    round(aRect.size.height * factor) / factor);
}


#if (__OBJC__)

#import <Cocoa/Cocoa.h>

WB_INLINE
CGFloat WBWindowUserSpaceScaleFactor(NSWindow *window) {
  return window ? [window backingScaleFactor] : 1;
}

WB_INLINE
CGFloat WBScreenUserSpaceScaleFactor(NSScreen *screen) {
  return screen ? [screen backingScaleFactor] : 1;
}

#endif

__END_DECLS

#endif /* __WB_GEOMETRY_H */
