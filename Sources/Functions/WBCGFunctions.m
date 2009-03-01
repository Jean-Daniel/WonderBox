/*
 *  WBCGFunctions.c
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBCGFunctions.h)

#pragma mark -
void WBCGContextAddRoundRect(CGContextRef context, CGRect rect, CGFloat radius) {
  if (radius <= 0) {
    DCLog("Negative or nil radius -> fall back to rect.");
    CGContextAddRect(context, rect);
    return;
  } 
  
  CGFloat width = CGRectGetWidth(rect);
  CGFloat height = CGRectGetHeight(rect);
  CGFloat maxRadius = MIN(width, height) / 2;
  if (radius > maxRadius) {
    /* radius to big, use a smaller one */
    DCLog("radius to big -> adjust it.");
    radius = maxRadius;
  }
	
	// In order to draw a rounded rectangle, we will take advantage of the fact that
	// CGContextAddArcToPoint will draw straight lines past the start and end of the arc
	// in order to create the path from the current position and the destination position.
	
	// In order to create the 4 arcs correctly, we need to know the min, mid and max positions
	// on the x and y lengths of the given rectangle.
	CGFloat minx = CGRectGetMinX(rect), midx = CGRectGetMidX(rect), maxx = CGRectGetMaxX(rect);
	CGFloat miny = CGRectGetMinY(rect), midy = CGRectGetMidY(rect), maxy = CGRectGetMaxY(rect);
	
	// Next, we will go around the rectangle in the order given by the figure below.
	//       minx    midx    maxx
	// miny    2       3       4
	// midy    1       9       5
	// maxy    8       7       6
	// Which gives us a coincident start and end point, which is incidental to this technique, but still doesn't
	// form a closed path, so we still need to close the path to connect the ends correctly.
	// Thus we start by moving to point 1, then adding arcs through each pair of points that follows.
	// You could use a similar tecgnique to create any shape with rounded corners.
	
	// Start at 1
	CGContextMoveToPoint(context, minx, midy);
	// Add an arc through 2 to 3
	CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
	// Add an arc through 4 to 5
	CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
	// Add an arc through 6 to 7
	CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
	// Add an arc through 8 to 9
	CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
	// Close the path
	CGContextClosePath(context);
}

void WBCGPathAddRoundRect(CGMutablePathRef path, const CGAffineTransform *transform, CGRect rect, CGFloat radius) {
  // NOTE: At this point you may want to verify that your radius is no more than half
	// the width and height of your rectangle, as this technique degenerates for those cases.
  if (radius <= 0) {
    DCLog("Negative or nil radius -> fall back to rect.");
    CGPathAddRect(path, transform, rect);
    return;
  } 
  
  CGFloat width = CGRectGetWidth(rect);
  CGFloat height = CGRectGetHeight(rect);
  CGFloat maxRadius = MIN(width, height) / 2;
  if (radius > maxRadius) {
    /* radius to big, use a smaller one */
    DCLog("radius to big -> adjust it.");
    radius = maxRadius;
  }
  
  // In order to draw a rounded rectangle, we will take advantage of the fact that
	// CGContextAddArcToPoint will draw straight lines past the start and end of the arc
	// in order to create the path from the current position and the destination position.
	
	// In order to create the 4 arcs correctly, we need to know the min, mid and max positions
	// on the x and y lengths of the given rectangle.
	CGFloat minx = CGRectGetMinX(rect), midx = CGRectGetMidX(rect), maxx = CGRectGetMaxX(rect);
	CGFloat miny = CGRectGetMinY(rect), midy = CGRectGetMidY(rect), maxy = CGRectGetMaxY(rect);
	
	// Next, we will go around the rectangle in the order given by the figure below.
	//       minx    midx    maxx
	// miny    2       3       4
	// midy   1 9              5
	// maxy    8       7       6
	// Which gives us a coincident start and end point, which is incidental to this technique, but still doesn't
	// form a closed path, so we still need to close the path to connect the ends correctly.
	// Thus we start by moving to point 1, then adding arcs through each pair of points that follows.
	// You could use a similar tecgnique to create any shape with rounded corners.
	
	// Start at 1
	CGPathMoveToPoint(path, transform, minx, midy);
	// Add an arc through 2 to 3
	CGPathAddArcToPoint(path, transform, minx, miny, midx, miny, radius);
	// Add an arc through 4 to 5
	CGPathAddArcToPoint(path, transform, maxx, miny, maxx, midy, radius);
	// Add an arc through 6 to 7
	CGPathAddArcToPoint(path, transform, maxx, maxy, midx, maxy, radius);
	// Add an arc through 8 to 9
	CGPathAddArcToPoint(path, transform, minx, maxy, minx, midy, radius);
	// Close the path
	CGPathCloseSubpath(path);
}

#define KAPPA 0.5522847498
void WBCGPathAddRoundRectWithRadius(CGMutablePathRef path, const CGAffineTransform *transform, CGRect rect, CGSize radius) {
  CGFloat x = CGRectGetMinX(rect);
  CGFloat y = CGRectGetMinY(rect);
  CGFloat width = CGRectGetWidth(rect);
  CGFloat height = CGRectGetHeight(rect);

  if (WBRealEquals(radius.width, radius.height)) {
    WBCGPathAddRoundRect(path, transform, rect, radius.width);
    return;
  }
  
  if (radius.width <= 0 || (radius.width * 2) > width) {
    DCLog("Invalid Radius Width.");
    radius.width = 0;
  }
  if (radius.height <= 0 || (radius.height * 2) > height) {
    DCLog("Invalid Radius Height.");
    radius.height = 0;
  }
  
  if (radius.width <= 0 && radius.height <= 0) {
    CGPathAddRect(path, transform, rect);
    return;
  }
  
  CGFloat lx = KAPPA * radius.width;
  CGFloat ly = KAPPA * radius.height;
  
  CGPathMoveToPoint(path, transform, x + radius.width, y);
  /* Bottom */
  CGPathAddLineToPoint(path, transform, CGRectGetMaxX(rect) - radius.width, y);
  /* Bottom right */
  CGPathAddCurveToPoint(path, transform, CGRectGetMaxX(rect) - radius.width + lx, y,
                        CGRectGetMaxX(rect), y + radius.height - ly, CGRectGetMaxX(rect), y + radius.height);
  /* Right */
  CGPathAddLineToPoint(path, transform, CGRectGetMaxX(rect), CGRectGetMaxY(rect) - radius.height);
  /* Top - Right */
  CGPathAddCurveToPoint(path, transform, CGRectGetMaxX(rect), CGRectGetMaxY(rect) - radius.height + ly,
                        CGRectGetMaxX(rect) - radius.width + lx, CGRectGetMaxY(rect), CGRectGetMaxX(rect) - radius.width, CGRectGetMaxY(rect));
  /* Top */
  CGPathAddLineToPoint(path, transform, x + radius.width, CGRectGetMaxY(rect));
  /* Top - Left */
  CGPathAddCurveToPoint(path, transform, x + radius.width - lx, CGRectGetMaxY(rect), 
                        x, CGRectGetMaxY(rect) - radius.height + ly, x, CGRectGetMaxY(rect) - radius.height);
  /* Left */
  CGPathAddLineToPoint(path, transform, x, y + radius.height);
  /* Bottom - Left */
  CGPathAddCurveToPoint(path, transform, x, y + radius.height - ly,
                        x + radius.width - lx, y, x + radius.width, y);
}

void WBCGContextAddRoundRectWithRadius(CGContextRef context, CGRect rect, CGSize radius) {
  CGFloat x = CGRectGetMinX(rect);
  CGFloat y = CGRectGetMinY(rect);
  CGFloat width = CGRectGetWidth(rect);
  CGFloat height = CGRectGetHeight(rect);
  
  if (WBRealEquals(radius.width, radius.height)) {
    WBCGContextAddRoundRect(context, rect, radius.width);
    return;
  }
  
  if (radius.width <= 0 || (radius.width * 2) > width) {
    DCLog("Invalid Radius Width.");
    radius.width = 0;
  }
  if (radius.height <= 0 || (radius.height * 2) > height) {
    DCLog("Invalid Radius Height.");
    radius.height = 0;
  }
  
  if (radius.width <= 0 && radius.height <= 0) {
    CGContextAddRect(context, rect);
    return;
  }
  
  CGFloat lx = KAPPA * radius.width;
  CGFloat ly = KAPPA * radius.height;
  
  CGContextMoveToPoint(context, x + radius.width, y);
  /* Bottom */
  CGContextAddLineToPoint(context, CGRectGetMaxX(rect) - radius.width, y);
  /* Bottom right */
  CGContextAddCurveToPoint(context, CGRectGetMaxX(rect) - radius.width + lx, y,
                           CGRectGetMaxX(rect), y + radius.height - ly, CGRectGetMaxX(rect), y + radius.height);
  /* Right */
  CGContextAddLineToPoint(context, CGRectGetMaxX(rect), CGRectGetMaxY(rect) - radius.height);
  /* Top - Right */
  CGContextAddCurveToPoint(context, CGRectGetMaxX(rect), CGRectGetMaxY(rect) - radius.height + ly,
                           CGRectGetMaxX(rect) - radius.width + lx, CGRectGetMaxY(rect), CGRectGetMaxX(rect) - radius.width, CGRectGetMaxY(rect));
  /* Top */
  CGContextAddLineToPoint(context, x + radius.width, CGRectGetMaxY(rect));
  /* Top - Left */
  CGContextAddCurveToPoint(context, x + radius.width - lx, CGRectGetMaxY(rect), 
                           x, CGRectGetMaxY(rect) - radius.height + ly,  x, CGRectGetMaxY(rect) - radius.height);
  /* Left */
  CGContextAddLineToPoint(context, x, y + radius.height);
  /* Bottom - Left */
  CGContextAddCurveToPoint(context, x, y + radius.height - ly,
                           x + radius.width - lx, y, x + radius.width, y);
}

#pragma mark Stars
void WBCGContextAddStar(CGContextRef ctxt, CGPoint center, CFIndex sides, CGFloat r, CGFloat ir) {
  check(sides >= 5);
  if (sides < 5) return;
  
  /* angles */
  CGFloat omega = M_PI_2;
  CGFloat delta = M_PI / sides;
  
  /* Internal rayon */
  if (ir <= 0)
    ir = r * sin(M_PI_2 - ((2 * M_PI) / sides)) / sin(M_PI_2 - delta);
  
  CGContextMoveToPoint(ctxt, center.x, center.y + r);
  omega -= delta;
  CGContextAddLineToPoint(ctxt, ir * cos(omega) + center.x, ir * sin(omega) + center.y);
  for (CFIndex idx = 0; idx < sides - 1; idx++) {
    omega -= delta;
    CGContextAddLineToPoint(ctxt, r * cos(omega) + center.x, r * sin(omega) + center.y);
    omega -= delta;
    CGContextAddLineToPoint(ctxt, ir * cos(omega) + center.x, ir * sin(omega) + center.y);
  }
}

void WBCGPathAddStar(CGMutablePathRef path, const CGAffineTransform *transform, CGPoint center, CFIndex sides, CGFloat r, CGFloat ir) {
  check(sides >= 5);
  if (sides < 5) return;
  
  /* angles */
  CGFloat omega = M_PI_2;
  CGFloat delta = M_PI / sides;
  
  /* Internal rayon */
  if (ir <= 0)
    ir = r * sin(M_PI_2 - ((2 * M_PI) / sides)) / sin(M_PI_2 - delta);
  
  CGPathMoveToPoint(path, transform, center.x, center.y + r);
  omega -= delta;
  CGPathAddLineToPoint(path, transform, ir * cos(omega) + center.x, ir * sin(omega) + center.y);
  for (CFIndex idx = 0; idx < sides - 1; idx++) {
    omega -= delta;
    CGPathAddLineToPoint(path, transform, r * cos(omega) + center.x, r * sin(omega) + center.y);
    omega -= delta;
    CGPathAddLineToPoint(path, transform, ir * cos(omega) + center.x, ir * sin(omega) + center.y);
  }
}

#pragma mark Waves
void WBCGContextStrokeWaves(CGContextRef context, CGRect rect, CGFloat period) {
  CGContextSaveGState(context);
  CGContextClipToRect(context,rect);
  
  CGFloat width = CGRectGetMaxX(rect);
  CGFloat height = CGRectGetHeight(rect);
  
  CGFloat step = pi * height / (2 * period);
  CGFloat delta = period * step;
  
  CGFloat end, center, middle;
  middle = CGRectGetMidY(rect);
  end = CGRectGetMinX(rect) - 3 * step/2.;

  CGContextBeginPath(context);
  /* Move to x, mid y */
  CGContextMoveToPoint(context, end, middle);
  
  while (end < width) {
    center = end + step;
    end = center + step;
    CGContextAddCurveToPoint (context,
                              center, middle + delta,
                              center, middle - delta,
                              end, middle);
  }
  
  CGContextStrokePath(context);
  /* Clear path data */
  CGContextBeginPath(context);
  CGContextRestoreGState(context);
}

void WBCGContextStrokeLine(CGContextRef ctxt, CGFloat x, CGFloat y, CGFloat x2, CGFloat y2) {
  CGPoint p[] = {
    CGPointMake(x, y),
    CGPointMake(x2, y2),
  };
  CGContextStrokeLineSegments(ctxt, p, 2);
}

#pragma mark Colors Spaces
CGColorSpaceRef WBCGColorSpaceCreateGray(void) {
  return CGColorSpaceCreateWithName(kCGColorSpaceGenericGray);
}

CGColorSpaceRef WBCGColorSpaceCreateRGB(void) {
  return CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
}

CGColorSpaceRef WBCGColorSpaceCreateCMYK(void) {
  return CGColorSpaceCreateWithName(kCGColorSpaceGenericCMYK);
}

#pragma mark Colors
CGColorRef WBCGColorCreateGray(CGFloat white, CGFloat alpha) {
  CGColorRef color = NULL;
  CGColorSpaceRef space = WBCGColorSpaceCreateGray();
  if (space) {
    CGFloat gray[] = {white, alpha};
    color = CGColorCreate(space, gray);
    CGColorSpaceRelease(space);
  }
  return color;
}

CGColorRef WBCGColorCreateRGB(CGFloat red, CGFloat green, CGFloat blue, CGFloat alpha) {
  CGColorRef color = NULL;
  CGColorSpaceRef space = WBCGColorSpaceCreateRGB();
  if (space) {
    CGFloat rgba[] = {red, green, blue, alpha};
    color = CGColorCreate(space, rgba);
    CGColorSpaceRelease(space);
  }
  return color;
}

CGColorRef WBCGColorCreateCMYK(CGFloat cyan, CGFloat magenta, CGFloat yellow, CGFloat black, CGFloat alpha) {
  CGColorRef color = NULL;
  CGColorSpaceRef space = WBCGColorSpaceCreateCMYK();
  if (space) {
    CGFloat cmyka[] = {cyan, magenta, yellow, black, alpha};
    color = CGColorCreate(space, cmyka);
    CGColorSpaceRelease(space);
  }
  return color;
}

#pragma mark Layer
CGLayerRef WBCGLayerCreateWithContext(CGContextRef ctxt, CGSize size, CFDictionaryRef auxiliaryInfo, bool scaleToUserSpace) {
  CGFloat factor = 1;
  if (scaleToUserSpace) {
    factor = WBCGContextGetUserSpaceScaleFactor(ctxt);
    size.width *= factor;
    size.height *= factor;
  }
  CGLayerRef layer = CGLayerCreateWithContext(ctxt, size, auxiliaryInfo);
  if (layer && scaleToUserSpace) {
    CGContextRef lctxt = CGLayerGetContext(layer);
    CGContextScaleCTM(lctxt, factor, factor);
  }
  return layer;
}

CGLayerRef WBCGLayerCreateWithAxialShading(CGContextRef ctxt, CGSize size, bool scaleToUserSpace, CGPoint start, CGPoint end,
                                           CGFunctionEvaluateCallback callback, const void *userInfo) {
  CGShadingRef shading = WBCGShadingCreateAxial(start, end, callback, userInfo);
  CGLayerRef layer = WBCGLayerCreateWithContext(ctxt, size, NULL, scaleToUserSpace);
  if (layer)
    CGContextDrawShading(CGLayerGetContext(layer), shading);
  CGShadingRelease(shading);
  
  return layer;
}

CGLayerRef WBCGLayerCreateWithVerticalShading(CGContextRef ctxt, CGSize size, bool scaleToUserSpace,
                                              CGFunctionEvaluateCallback callback, const void *userInfo) {
  /* draw top to bottom */
  CGPoint start = CGPointMake(0, size.height), end = CGPointMake(0, 0);
  return WBCGLayerCreateWithAxialShading(ctxt, size, scaleToUserSpace, start, end, callback, userInfo);
}

CGLayerRef WBCGLayerCreateWithHorizontalShading(CGContextRef ctxt, CGSize size, bool scaleToUserSpace,
                                                CGFunctionEvaluateCallback callback, const void *userInfo) {
  /* draws left to right */
  CGPoint start = CGPointMake(0, 0), end = CGPointMake(size.width, 0);
  return WBCGLayerCreateWithAxialShading(ctxt, size, scaleToUserSpace, start, end, callback, userInfo);
}

CGImageRef WBCGLayerCreateImage(CGLayerRef layer) {
  CGImageRef result = NULL;
  CGSize size = CGLayerGetSize(layer);
  CGColorSpaceRef space = WBCGColorSpaceCreateRGB();
  CGContextRef bitmap = CGBitmapContextCreate(malloc(size.width * size.height * sizeof(UInt32)), size.width, size.height, 8, size.width * sizeof(UInt32), space, kCGImageAlphaPremultipliedLast);
  if (bitmap) {
    CGContextDrawLayerInRect(bitmap, CGRectMake(0, 0, size.width, size.height), layer);
    result = CGBitmapContextCreateImage(bitmap);
    CGContextRelease(bitmap);
  }
  CGColorSpaceRelease(space);
  return result;
}

#pragma mark Shading
static
CGFunctionRef _WBCGCreateShadingFunction(CGFunctionEvaluateCallback callback, CGColorSpaceRef colorspace, const void *ctxt, UInt32 *count) {
  size_t components = 1 + CGColorSpaceGetNumberOfComponents(colorspace);
  CGFloat input_value_range [2] = { 0, 1 };
  CGFloat output_value_ranges [components * 2];
  for (NSUInteger idx = 0; idx < components; idx++) {
    output_value_ranges[idx * 2] = 0;
    output_value_ranges[1 + idx * 2] = 1;
  }
  
  if (count) *count = (UInt32)components;
  CGFunctionCallbacks callbacks = { 0, callback, NULL };
  return CGFunctionCreate((void *)ctxt, 1, input_value_range, components, output_value_ranges, &callbacks);
}

CGShadingRef WBCGShadingCreateAxial(CGPoint start, CGPoint end, CGFunctionEvaluateCallback callback, const void *ctxt) {
  CGColorSpaceRef colorspace = WBCGColorSpaceCreateRGB();
  CGFunctionRef function = _WBCGCreateShadingFunction(callback, colorspace, ctxt, NULL);
  
  CGShadingRef shading = CGShadingCreateAxial(colorspace, start, end, function, false, false);
  
  CGColorSpaceRelease(colorspace);
  CGFunctionRelease(function);
  
  return shading;
}

CGShadingRef WBCGShadingCreateRadial(CGPoint start, CGFloat startr, CGPoint end, CGFloat endr, CGFunctionEvaluateCallback callback, const void *ctxt) {
  CGColorSpaceRef colorspace = WBCGColorSpaceCreateRGB();
  CGFunctionRef function = _WBCGCreateShadingFunction(callback, colorspace, ctxt, NULL);
  
  CGShadingRef shading = CGShadingCreateRadial(colorspace, start, startr, end, endr, function, false, false);
  
  CGColorSpaceRelease(colorspace);
  CGFunctionRelease(function);
  
  return shading;
}

CGFloat WBCGShadingSinFactorFunction(CGFloat factor) {
  CGFloat sinus = sin(M_PI_2 * factor);
  return sinus * sinus;
}
CGFloat WBCGShadingCircularFactorFunction(CGFloat factor) {
  return sqrt(factor * (2 - factor));
}

void WBCGShadingSimpleShadingFunction(void *pinfo, const CGFloat *in, CGFloat *out) {
  CGFloat v;
  WBCGSimpleShadingInfo *ctxt = pinfo;
  
  v = ctxt->fct ? ctxt->fct(*in) : *in;
  for (NSUInteger k = 0; k < 4; k++) {
    *out++ = ctxt->start[k] - (ctxt->start[k] - ctxt->end[k]) * v;
  }
}

void WBCGShadingMultiShadingFunction(void *pinfo, const CGFloat *in, CGFloat *out) {
  CGFloat v, shift = 0;
  WBCGMultiShadingInfo *ctxt = (WBCGMultiShadingInfo *)pinfo;
  
  v = *in;
  for (NSUInteger idx = 0; idx < ctxt->count; idx++) {
    if (v <= ctxt->steps[idx].end) {
      CGFloat factor = (v - shift) / (ctxt->steps[idx].end - shift);
      if (ctxt->steps[idx].fct) factor = ctxt->steps[idx].fct(factor);
      for (NSUInteger k = 0; k < 4; k++) {
        *out++ = ctxt->steps[idx].rgba[k] + (ctxt->steps[idx].rgba2[k] - ctxt->steps[idx].rgba[k]) * factor;
      }
      return;
    } else {
      shift = ctxt->steps[idx].end;
    }
  }
  DCLog("Oops, what am i doing here?");
}

#pragma mark Images
CGImageRef WBCGImageCreateFromURL(CFURLRef url, CFDictionaryRef options) {
  CGImageRef img = NULL;
  CGImageSourceRef src = CGImageSourceCreateWithURL(url, options);
  if (src) {
    img = CGImageSourceCreateImageAtIndex(src, 0, NULL);
    CFRelease(src);
  }
  return img;
}

bool WBCGImageWriteToURL(CGImageRef image, CFURLRef url, CFStringRef type) {
  bool result = false;
  CGImageDestinationRef dest = CGImageDestinationCreateWithURL(url, type, 1, NULL);
  if (dest) {
    CGImageDestinationAddImage(dest, image, NULL);
    result = CGImageDestinationFinalize(dest);
    CFRelease(dest);
  }
  return result;
}

bool WBCGImageWriteToFile(CGImageRef image, CFStringRef file, CFStringRef type) {
  bool result = false;
  CFURLRef url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, file, kCFURLPOSIXPathStyle, FALSE);
  if (url) {
    result = WBCGImageWriteToURL(image, url, type);
    CFRelease(url);
  }
  return result;
}
