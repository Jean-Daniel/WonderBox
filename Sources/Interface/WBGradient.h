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

// Folowing macros and struxt are not design to be setup at runtime, but at compile time.
// To create a gradient at runtime, it's easier to directly use the WBGradientBuilder class.
/* Set of macros and types for gradient creation */
enum {
  kWBInterpolationTypeLinear   = 0,
  kWBInterpolationTypeCallBack = 1,
  kWBInterpolationTypeBezier   = 2,
  kWBInterpolationTypeDefault  = 0xff,
};

typedef struct {
  uint8_t type;
  union {
    struct {
      CGPoint points[2];
      CGFloat length;
    } bezier;
    WBInterpolationEvaluateCallBack cb;
  } value;
} WBInterpolationDefinition;

#define kWBInterpolationLinear { 0, { .cb = NULL } }
#define kWBInterpolationDefault { kWBInterpolationTypeDefault, { .cb = NULL } }
#define WBInterpolationCallBackDef(function) { kWBInterpolationTypeCallBack, { .cb = function } }
#define WBInterpolationBezierDef(x1, y1, x2, y2, l) { kWBInterpolationTypeBezier, { .bezier = { { { x1, y1 }, { x2, y2 } }, l } } }

@class WBInterpolationFunction;
typedef union _WBShadingColor {
  CGFloat rgba[4];
  CGFloat grayscale[2];
} WBShadingColor;

#define WBShadingColorRGB(r, g, b, a) { .rgba = {r, g, b, a} }
#define WBShadingColorGray(w, a) { .grayscale = { w, a } }

typedef struct {
  NSUInteger count; // count of steps
  WBInterpolationDefinition fct; // Default Interpolation function
  struct {
    CGFloat start;
    WBShadingColor startColor;
    CGFloat end;
    WBShadingColor endColor;
    WBInterpolationDefinition fct; // set to kWBInterpolationDefault to use default function
  } steps[];
} WBGradientDefinition;

/*!
 @class WBGradientBuilder

 */
WB_OBJC_EXPORT
@interface WBGradientBuilder : NSObject {
@private
  uint8_t wb_extends;
  NSColorSpace *wb_cs;
  NSMutableArray *wb_steps;
}

// Colorspace MUST match definition
- (id)initWithColorSpace:(NSColorSpace *)aColorSpace definition:(const WBGradientDefinition *)definition;

// Simple gradient
- (id)initWithStartingColor:(NSColor *)startingColor endingColor:(NSColor *)endingColor;
- (id)initWithStartingColor:(NSColor *)startingColor endingColor:(NSColor *)endingColor interpolation:(WBInterpolationFunction *)fct;
- (id)initWithStartingColor:(NSColor *)startingColor endingColor:(NSColor *)endingColor interpolation:(WBInterpolationFunction *)fct colorSpace:(NSColorSpace *)aColorSpace;

- (id)init;
- (id)initWithColorSpace:(NSColorSpace *)aColorSpace; // designated

- (void)addStepFrom:(CGFloat)value components:(const CGFloat *)startColor
                 to:(CGFloat)endValue components:(const CGFloat *)endColor
      interpolation:(WBInterpolationFunction *)fct;

- (void)addStepFrom:(CGFloat)value color:(NSColor *)aColor
                 to:(CGFloat)endValue color:(NSColor *)endColor
      interpolation:(WBInterpolationFunction  *)fct;

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

