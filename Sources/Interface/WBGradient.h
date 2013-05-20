/*
 *  WBGradient.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBInterpolationFunction.h>

// Following macros and struct are not design to be setup at runtime, but at compile time.
// To create a gradient at runtime, it's easier to directly use the WBGradientBuilder class.
/* Set of macros and types for gradient creation */
typedef NS_ENUM(uint8_t, WBInterpolationType) {
  kWBInterpolationTypeNull     = 0,
  kWBInterpolationTypeLinear   = 1,
  kWBInterpolationTypeCallBack = 2,
  kWBInterpolationTypeBezier   = 3,
  kWBInterpolationTypeDefault  = 0xff,
};

typedef struct {
  WBInterpolationType type;
  union {
    struct {
      CGPoint points[2];
      CGFloat length;
    } bezier;
    WBInterpolationEvaluateCallBack cb;
  } value;
} WBInterpolationDefinition;

#define kWBInterpolationLinear { kWBInterpolationTypeLinear, {} }
#define kWBInterpolationDefault { kWBInterpolationTypeDefault, {} }
#define WBInterpolationCallBackDef(function) { kWBInterpolationTypeCallBack, { .cb = function } }
#define WBInterpolationBezierDef(x1, y1, x2, y2, l) { kWBInterpolationTypeBezier, { .bezier = { { { x1, y1 }, { x2, y2 } }, l } } }

@class WBInterpolationFunction;
typedef union _WBShadingColor {
  CGFloat components[5];
} WBShadingColor;

#define WBShadingColorRGB(r, g, b, a) { .components = {r, g, b, a, 0} }
#define WBShadingColorGray(w, a) { .components = { w, a, 0, 0, 0 } }

typedef NS_ENUM(uint8_t, WBGradientColorSpace) {
  kWBGradientColorSpace_RGB,
  kWBGradientColorSpace_Gray, // 1 means white
};

// definition's colors MUST match the colorspace.
typedef struct {
  WBGradientColorSpace cs;
  WBInterpolationDefinition fct; // Default Interpolation function. Must not be kWBInterpolationDefault
  struct {
    CGFloat location; // end location. Must be in ]0; 1]. Last step MUST have location set to 1
    WBShadingColor startColor;
    WBShadingColor endColor;
    WBInterpolationDefinition fct; // set to kWBInterpolationDefault to use default function
  } stops[];
} WBGradientDefinition;

WB_OBJC_EXPORT
@interface WBGradientBuilder : NSObject {
@private
  uint8_t _extends;
  NSColorSpace *_cs;
  NSMutableArray *_steps;
}

- (id)initWithColorSpace:(NSColorSpace *)aColorSpace; // designated

- (id)initWithDefinition:(const WBGradientDefinition *)definition;

// Simple gradient
- (id)initWithStartingColor:(NSColor *)startingColor endingColor:(NSColor *)endingColor;
- (id)initWithStartingColor:(NSColor *)startingColor endingColor:(NSColor *)endingColor colorSpace:(NSColorSpace *)aColorSpace;
- (id)initWithStartingColor:(NSColor *)startingColor endingColor:(NSColor *)endingColor colorSpace:(NSColorSpace *)aColorSpace interpolation:(WBInterpolationFunction *)fct;

- (void)addColorStop:(CGFloat)location startingColor:(NSColor *)aColor endingColor:(NSColor *)endColor
       interpolation:(WBInterpolationFunction  *)fct;

// Components must match color space used to create this gradient builder. If you are not sure what you are doing, use NSColor instead.
- (void)addColorStop:(CGFloat)location startingColorComponents:(const CGFloat *)startColor endingColorComponents:(const CGFloat *)endColor
       interpolation:(WBInterpolationFunction *)fct;

// output
- (CGFunctionRef)newFunction CF_RETURNS_RETAINED;

// All following methods conform to Cocoa Memory Management rule: methods that begin with new return a not-autoreleased object.
// caller MUST release it when over
- (CGShadingRef)newAxialShadingFrom:(CGPoint)from to:(CGPoint)to CF_RETURNS_RETAINED;

// caller MUST release it when over
- (CGShadingRef)newRadialShadingFrom:(CGPoint)from radius:(CGFloat)fromRadius
                                  to:(CGPoint)to radius:(CGFloat)toRadius CF_RETURNS_RETAINED;

// from bottom to top
- (CGLayerRef)newLayerWithVerticalGradient:(CGSize)size scale:(BOOL)scaleToUserSpace context:(CGContextRef)aContext CF_RETURNS_RETAINED;
// from left to right
- (CGLayerRef)newLayerWithHorizontalGradient:(CGSize)size scale:(BOOL)scaleToUserSpace context:(CGContextRef)aContext CF_RETURNS_RETAINED;

- (CGLayerRef)newLayerWithAxialGradient:(CGSize)size angle:(CGFloat)anAngle scale:(BOOL)scaleToUserSpace context:(CGContextRef)aContext CF_RETURNS_RETAINED;
- (CGLayerRef)newLayerWithAxialGradient:(CGSize)size from:(CGPoint)aPoint to:(CGPoint)endPoint scale:(BOOL)scaleToUserSpace context:(CGContextRef)aContext CF_RETURNS_RETAINED;

@end

