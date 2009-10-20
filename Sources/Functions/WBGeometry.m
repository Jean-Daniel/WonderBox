/*
 *  WBGeometry.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBGeometry.h)

CGSize WBSizeScaleToSize(CGSize source, CGSize dest, WBScalingMode mode) {
  if (source.width <= 0 || source.height <= 0) return CGSizeZero;
  
  switch (mode) {
    default:
    case kWBScalingModeNone:
      return source;
    case kWBScalingModeAxesIndependently:
      return dest;
      
    case kWBScalingModeProportionallyFitDown:
      // if destination size > source size, do not scale.
      if (source.width <= dest.width && source.height <= dest.height)
        return source;
      // else, scale down
    case kWBScalingModeProportionallyFit:
    {
      CGFloat ratio = MIN(dest.width / source.width, dest.height / source.height);
      return WBSizeScale(source, ratio, ratio);
    }
      
    case kWBScalingModeProportionallyFillDown:
      // if destination size > movie size, do not scale.
      if (source.width <= dest.width || source.height <= dest.height)
        return source;
      // else, scale up
    case kWBScalingModeProportionallyFill:
    {
      CGFloat ratio = MAX(dest.width / source.width, dest.height / source.height);
      return WBSizeScale(source, ratio, ratio);
    }
  }
}

/// Align rectangles
//
//  Args:
//    alignee - rect to be aligned
//    aligner - rect to be aligned to
//    alignment - alignment to be applied to alignee based on aligner
CGRect WBRectAlignToRect(CGRect alignee, CGRect aligner, WBRectAlignment alignment) {
  switch (alignment) {
    case kWBRectAlignTop:
      alignee.origin.x = aligner.origin.x + (aligner.size.width * .5 - alignee.size.width * .5);
      alignee.origin.y = aligner.origin.y + aligner.size.height - alignee.size.height;
      break;
      
    case kWBRectAlignTopLeft:
      alignee.origin.x = aligner.origin.x;
      alignee.origin.y = aligner.origin.y + aligner.size.height - alignee.size.height;
      break;
      
    case kWBRectAlignTopRight:
      alignee.origin.x = aligner.origin.x + aligner.size.width - alignee.size.width;
      alignee.origin.y = aligner.origin.y + aligner.size.height - alignee.size.height;
      break;
      
    case kWBRectAlignLeft:
      alignee.origin.x = aligner.origin.x;
      alignee.origin.y = aligner.origin.y + (aligner.size.height * .5 - alignee.size.height * .5);
      break;
      
    case kWBRectAlignBottomLeft:
      alignee.origin.x = aligner.origin.x;
      alignee.origin.y = aligner.origin.y;
      break;
      
    case kWBRectAlignBottom:
      alignee.origin.x = aligner.origin.x + (aligner.size.width * .5 - alignee.size.width * .5);
      alignee.origin.y = aligner.origin.y;
      break;
      
    case kWBRectAlignBottomRight:
      alignee.origin.x = aligner.origin.x + aligner.size.width - alignee.size.width;
      alignee.origin.y = aligner.origin.y;
      break;
      
    case kWBRectAlignRight:
      alignee.origin.x = aligner.origin.x + aligner.size.width - alignee.size.width;
      alignee.origin.y = aligner.origin.y + (aligner.size.height * .5 - alignee.size.height * .5);
      break;
      
    default:
    case kWBRectAlignCenter:
      alignee.origin.x = aligner.origin.x + (aligner.size.width * .5 - alignee.size.width * .5);
      alignee.origin.y = aligner.origin.y + (aligner.size.height * .5 - alignee.size.height * .5);
      break;
  }
  return alignee;
}

#pragma mark -
CGFloat WBCGContextGetUserSpaceScaleFactor(CGContextRef ctxt) {
  CGAffineTransform trans = CGContextGetUserSpaceToDeviceSpaceTransform(ctxt);
  return ABS(trans.a);
}

void WBCGContextSetLinePixelWidth(CGContextRef context, CGFloat width) {
  CGAffineTransform space = CGContextGetUserSpaceToDeviceSpaceTransform(context);
  if (!CGAffineTransformIsIdentity(space)) {
    space = CGAffineTransformInvert(space);
    width = CGSizeApplyAffineTransform(CGSizeMake(width, 0), space).width;
  }
  
  CGContextSetLineWidth(context, width);
}

@implementation NSGraphicsContext (WBCGContextRef)

+ (CGContextRef)currentGraphicsPort {
  return [[self currentContext] graphicsPort];
}

@end

