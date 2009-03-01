/*
 *  WBGeometry.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#if !defined (__WBGEOMETRY_H)
#define __WBGEOMETRY_H 1

#pragma mark -
WB_INLINE
CGSize WBMaxSizeForSizes(CGSize s1, CGSize s2) {
  CGSize s;
  s.width = MAX(s1.width, s2.width);
  s.height = MAX(s1.height, s2.height);
  return s;
}

WB_INLINE
CGSize WBMinSizeForSizes(CGSize s1, CGSize s2) {
  CGSize s;
  s.width = MIN(s1.width, s2.width);
  s.height = MIN(s1.height, s2.height);
  return s;
}


#pragma mark Scaling
enum {
  kWBScalingModeProportionallyFit, // default
  kWBScalingModeProportionallyFill,
  kWBScalingModeProportionallyFitDown,
  kWBScalingModeProportionallyFillDown,
  kWBScalingModeAxesIndependently,
  kWBScalingModeNone,
};
typedef NSUInteger WBScalingMode;

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
typedef NSUInteger WBRectAlignement;

WB_EXPORT
CGRect WBRectAlignToRect(CGRect alignee, CGRect aligner, WBRectAlignement mode);

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
CGRect WBRectScaleToRect(CGRect source, CGRect dest, WBScalingMode mode, WBRectAlignement align) {
  return WBRectAlignToRect(WBRectScaleToSize(source, dest.size, mode), dest, align);
}

WB_INLINE
CGRect WBSizeScaleToRect(CGSize source, CGRect dest, WBScalingMode mode, WBRectAlignement align) {
  CGRect result = CGRectZero;
  result.size = WBSizeScaleToSize(source, dest.size, mode);
  return WBRectAlignToRect(result, dest, align);
}

#pragma mark -
WB_EXPORT
CGFloat WBCGContextGetUserSpaceScaleFactor(CGContextRef ctxt);
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

WB_INLINE
CGFloat WBWindowUserSpaceScaleFactor(NSWindow *window) {
  return window ? [window userSpaceScaleFactor] : 1;
}

WB_INLINE
CGFloat WBScreenUserSpaceScaleFactor(NSScreen *screen) {
  return screen ? [screen userSpaceScaleFactor] : 1;
}

#endif

#endif /* __WBGEOMETRY_H */
