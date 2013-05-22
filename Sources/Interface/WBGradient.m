/*
 *  WBGradient.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBGradient.h>
#import <WonderBox/WBCGFunctions.h>

@interface WBGradientStep : NSObject {
  uint8_t _cnt;
  CGFloat _start, _end;
  WBInterpolationFunction *_fct;
  CGFloat _colorStart[5], _colorEnd[5];
}

static
void _WBGradientRelease(void *info);
static
void _WBGradientDrawStep(void * info, const CGFloat * in, CGFloat * out);
static
void _WBGradientDrawSteps(void * info, const CGFloat * in, CGFloat * out);

@property(nonatomic, readonly) CGFloat start, end;
@property(nonatomic, retain) WBInterpolationFunction *interpolation;

- (id)initWithComponents:(NSUInteger)count startColor:(const CGFloat *)startColor endColor:(const CGFloat *)endColor;
- (void)setRange:(CGFloat)start end:(CGFloat)end;

@end

static
WBInterpolationFunction *WBFunctionCreateFromDefinition(const WBInterpolationDefinition *def);

// MARK: -
@implementation WBGradientBuilder

- (id)init {
  return [self initWithColorSpace:nil];
}

- (id)initWithColorSpace:(NSColorSpace *)aColorSpace {
  if (self = [super init]) {
    if (!aColorSpace)
      aColorSpace = [NSColorSpace genericRGBColorSpace];
    CFIndex count = [aColorSpace numberOfColorComponents] + 1; // add one for alpha
    if (count < 2 || count > 5) {
      SPXLogError(@"WBGradient: Unsupported color space: %@", aColorSpace);
      spx_release(self);
      return nil;
    }
    _cs = spx_retain(aColorSpace);
    _steps = [[NSMutableArray alloc] init];
  }
  return self;
}

// MARK: Helpers
- (id)initWithStartingColor:(NSColor *)startingColor endingColor:(NSColor *)endingColor {
  if (self = [self initWithColorSpace:nil]) {
    [self addColorStop:1 startingColor:startingColor endingColor:endingColor interpolation:nil];
  }
  return self;
}

- (id)initWithStartingColor:(NSColor *)startingColor endingColor:(NSColor *)endingColor colorSpace:(NSColorSpace *)aColorSpace {
  if (self = [self initWithColorSpace:aColorSpace]) {
    [self addColorStop:1 startingColor:startingColor endingColor:endingColor interpolation:nil];
  }
  return self;
}

- (id)initWithStartingColor:(NSColor *)startingColor endingColor:(NSColor *)endingColor colorSpace:(NSColorSpace *)aColorSpace interpolation:(WBInterpolationFunction *)fct {
  if (self = [self initWithColorSpace:aColorSpace]) {
    [self addColorStop:1 startingColor:startingColor endingColor:endingColor interpolation:fct];
  }
  return self;
}

static inline
NSColorSpace *GetColorSpace(WBGradientColorSpace space) {
  switch (space) {
    case kWBGradientColorSpace_RGB:
      return [NSColorSpace genericRGBColorSpace];
    case kWBGradientColorSpace_Gray:
      return [NSColorSpace genericGrayColorSpace];
    default:
      SPXThrowException(NSInvalidArgumentException, @"Unsupported colorspace");
  }
}

- (id)initWithDefinition:(const WBGradientDefinition *)def {
  NSParameterAssert(def);
  if (self = [self initWithColorSpace:GetColorSpace(def->cs)]) {
    WBInterpolationFunction *base = WBFunctionCreateFromDefinition(&def->fct);

    CFIndex idx = 0;
    do {
      WBInterpolationFunction *fct = nil;
      const CGFloat *startColor = NULL, *endColor = NULL;
      if (kWBInterpolationTypeNull != def->stops[idx].fct.type) {
        startColor = def->stops[idx].startColor;
        endColor = def->stops[idx].endColor;
        if (kWBInterpolationTypeDefault == def->stops[idx].fct.type) {
          fct = base;
        } else
          fct = WBFunctionCreateFromDefinition(&def->stops[idx].fct);
      }

      [self addColorStop:def->stops[idx].location startingColorComponents:startColor endingColorComponents:endColor interpolation:fct];
    } while (def->stops[idx++].location < 1);
  }
  return self;
}

- (void)dealloc {
  spx_release(_steps);
  spx_release(_cs);
  spx_dealloc();
}

#pragma mark -
- (void)addColorStop:(CGFloat)location startingColor:(NSColor *)startColor endingColor:(NSColor *)endColor interpolation:(WBInterpolationFunction  *)fct {
  CGFloat start[5];
  // Start Color
  NSColor *color = [startColor colorUsingColorSpace:_cs];
  if (!color)
    SPXThrowException(NSInvalidArgumentException, @"cannot use %@ in gradient with color space %@", startColor, _cs);
  [color getComponents:start];
  // End color
  CGFloat end[5];
  color = [endColor colorUsingColorSpace:_cs];
  if (!color)
    SPXThrowException(NSInvalidArgumentException, @"cannot use %@ in gradient with color space %@", endColor, _cs);
  [color getComponents:end];

  [self addColorStop:location startingColorComponents:start endingColorComponents:end interpolation:fct];
}

- (void)addColorStop:(CGFloat)location startingColorComponents:(const CGFloat *)startColor endingColorComponents:(const CGFloat *)endColor
       interpolation:(WBInterpolationFunction *)fct {

  // Make sure the location is valid
  if (location > 1)
    SPXThrowException(NSInvalidArgumentException, @"location must be in the range ]0; 1]");

  WBGradientStep *last = [_steps lastObject];
  CGFloat start = last ? last.end : 0;
  if (location < start)
    SPXThrowException(NSInvalidArgumentException, @"overlapping color stop: %.2f < %.2f", location, start);

  // TODO: is !startColor || !endColor -> add empty colorStop.
  CFIndex cnt = [_cs numberOfColorComponents] + 1; // + one for alpha
  WBGradientStep *step = [[WBGradientStep alloc] initWithComponents:cnt startColor:startColor endColor:endColor];
  [step setRange:start end:location];
  step.interpolation = fct;
  [_steps addObject:step];
  spx_release(step);
}

// MARK: -
// MARK: Generator
- (CGFunctionRef)newFunction {
  if ([_steps count] == 0)
    SPXThrowException(NSInvalidArgumentException, @"cannot create empty shading");

  CFIndex components = [_cs numberOfColorComponents] + 1; // + one for alpha
  CGFloat input_value_range [2] = { 0, 1 }; // on input, value varying in [0; 1]
  CGFloat output_value_ranges [components * 2]; // on output, color components
  for (CFIndex idx = 0; idx < components; idx++) {
    output_value_ranges[idx * 2] = 0;
    output_value_ranges[idx * 2 + 1] = 1;
  }

  void *info = NULL;
  CGFunctionCallbacks callbacks = { 0, NULL, _WBGradientRelease };
  if ([_steps count] == 1) {
    info = (void *)SPXCFTypeBridgingRetain([_steps objectAtIndex:0]); // leak: Released by _WBGradientRelease
    callbacks.evaluate = _WBGradientDrawStep;
  } else {
    NSArray *steps = [_steps copy];
    info = (void *)SPXCFTypeBridgingRetain(steps); // leak: Released by _WBGradientRelease
    callbacks.evaluate = _WBGradientDrawSteps;
    spx_release(steps);
  }

  return CGFunctionCreate(info, 1, input_value_range, components, output_value_ranges, &callbacks);
}

// MARK: Shadings
- (CGShadingRef)newAxialShadingFrom:(CGPoint)from to:(CGPoint)to {
  CGFunctionRef fct = [self newFunction];
  CGShadingRef shading = CGShadingCreateAxial([_cs CGColorSpace], from, to, fct, (_extends & 1) != 0, (_extends & 2) != 0);
  CGFunctionRelease(fct);
  return shading;
}

- (CGShadingRef)newRadialShadingFrom:(CGPoint)from radius:(CGFloat)fromRadius
                                  to:(CGPoint)to radius:(CGFloat)toRadius {
  CGFunctionRef fct = [self newFunction];
  CGShadingRef shading = CGShadingCreateRadial([_cs CGColorSpace], from, fromRadius, to, toRadius, fct, (_extends & 1) != 0, (_extends & 2) != 0);
  CGFunctionRelease(fct);
  return shading;
}

// MARK: Layers
- (CGLayerRef)newLayerWithVerticalGradient:(CGSize)size scale:(BOOL)scaleToUserSpace context:(CGContextRef)aContext {
  return [self newLayerWithAxialGradient:size from:CGPointZero to:CGPointMake(0, size.height) scale:scaleToUserSpace context:aContext];
}
- (CGLayerRef)newLayerWithHorizontalGradient:(CGSize)size scale:(BOOL)scaleToUserSpace context:(CGContextRef)aContext {
  return [self newLayerWithAxialGradient:size from:CGPointZero to:CGPointMake(size.width, 0) scale:scaleToUserSpace context:aContext];
}

- (CGLayerRef)newLayerWithAxialGradient:(CGSize)size angle:(CGFloat)anAngle scale:(BOOL)scaleToUserSpace context:(CGContextRef)aContext {
  double angle = fmod(anAngle, 360);
  if (angle > 180) angle =  180 - angle;
  angle = angle * M_PI / 180;

  // normalize
  if (fequal(angle, -M_PI)) angle = M_PI;

  CGPoint p1, p2;
  if (fiszero(angle) || fequal(angle, M_PI)) {
    // Horizontal
    p1 = CGPointZero;
    p2 = CGPointMake(size.width, 0);
  } else if (fequal(angle, M_PI_2) || fequal(angle, -M_PI_2)) {
    // Vertical
    p1 = CGPointZero;
    p2 = CGPointMake(0, size.height);
  } else {
    p1 = CGPointZero;
    // simple affine resolution
    // f1(x) = ax + 0 (with a = tan(angle))
    // f2(x) = -x/a + b (orthogonal to first line)
    // resolve for f2(size.width) = size.height (so the gradient fills the whole layer).

    double a = fabs(tan(angle));
    double b = size.height + size.width/a;

    p2.x = (CGFloat)((a * b) / (a * a + 1)); // x = (a * b) / (a^2 + 1)
    p2.y = (CGFloat)(a * p2.x);              // y = a * x
  }

  // take care of orientation
  if (angle < -M_PI_2 || angle > M_PI_2) {
    // horizontal
    p1.x += size.width;
    p2.x = size.width - p2.x;
  }

  if (angle < 0) {
    // vertical
    p1.y += size.height;
    p2.y = size.height - p2.y;
  }

  return [self newLayerWithAxialGradient:size from:p1 to:p2 scale:scaleToUserSpace context:aContext];
}

- (CGLayerRef)newLayerWithAxialGradient:(CGSize)size from:(CGPoint)from to:(CGPoint)to scale:(BOOL)scaleToUserSpace context:(CGContextRef)aContext {
  CGShadingRef shading = [self newAxialShadingFrom:from to:to];
  if (!shading) return nil;

  CGLayerRef layer = WBCGLayerCreateWithContext(aContext, size, NULL, scaleToUserSpace);
  if (layer)
    CGContextDrawShading(CGLayerGetContext(layer), shading);
  CGShadingRelease(shading);

  return layer;
}

@end

// MARK: -
WBInterpolationFunction *WBFunctionCreateFromDefinition(const WBInterpolationDefinition *def) {
  if (!def) return nil;

  switch (def->type) {
    default:
      return nil;
    case kWBInterpolationTypeCallBack: {
      WBInterpolationCallBack cb = { NULL, def->value.cb, NULL };
      return spx_autorelease([[WBInterpolationFunction alloc] initWithCallBack:&cb]);
    }
    case kWBInterpolationTypeBezier:
      return spx_autorelease([[WBInterpolationFunction alloc] initWithControlPoints:def->value.bezier.points[0].x :def->value.bezier.points[0].y
                                                                                  :def->value.bezier.points[1].x :def->value.bezier.points[1].y
                                                                            length:def->value.bezier.length]);
  }
}

// MARK: -
@implementation WBGradientStep

@synthesize interpolation = _fct;
@synthesize start = _start, end = _end;

- (id)initWithComponents:(NSUInteger)count startColor:(const CGFloat *)startColor endColor:(const CGFloat *)endColor {
  NSParameterAssert(count > 0 && count <= 5);
  if (self = [super init]) {
    _cnt = (uint8_t)count;
    if (startColor)
      memcpy(_colorStart, startColor, _cnt * sizeof(CGFloat));
    if (endColor)
      memcpy(_colorEnd, endColor, _cnt * sizeof(CGFloat));
  }
  return self;
}

- (void)dealloc {
  spx_release(_fct);
  spx_dealloc();
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { start: %.2f, end: %.2f }",
          self.class, self, _start, _end];
}

- (void)setRange:(CGFloat)start end:(CGFloat)end {
  _start = start;
  _end = end;
}

- (NSComparisonResult)compare:(WBGradientStep *)aStep {
  if (!aStep)
    return NSOrderedDescending;

  if (_start > aStep->_start) return NSOrderedDescending;
  if (aStep->_start > _start) return NSOrderedAscending;
  return NSOrderedSame;
}

- (void)getColor:(CGFloat *)outColor atPoint:(CGFloat)input {
  if (input <= _start) {
    memcpy(outColor, _colorStart, _cnt * sizeof(CGFloat));
  } else if (input >= _end) {
    memcpy(outColor, _colorEnd, _cnt * sizeof(CGFloat));
  } else {
    // interpolate
    input = (input - _start) / (_end - _start);
    // clamp factor
    CGFloat factor = _fct ? MAX(MIN(1, [_fct valueForInput:input]), 0) : input;
    for (uint8_t k = 0; k < _cnt; k++)
      *outColor++ = _colorStart[k] - (_colorStart[k] - _colorEnd[k]) * factor;
  }
}

@end

void _WBGradientRelease(void *info) {
  SPXCFRelease(info);
}

void _WBGradientDrawStep(void * info, const CGFloat * in, CGFloat * out) {
  WBGradientStep *step = (__bridge WBGradientStep *)info;
  [step getColor:out atPoint:*in];
}

void _WBGradientDrawSteps(void * info, const CGFloat * in, CGFloat * out) {
  NSArray *steps = (__bridge NSArray *)info;

  CGFloat input = *in;
  WBGradientStep *first = nil;
  for (WBGradientStep *step in steps) {
    if (first) {
      // we already have a step, we just want to check if the next step start point overlap.
      if (step.start <= input)
        first = step;
      break;
    }
    if (input < step.end)
      first = step;
  }
  if (!first)
    first = [steps lastObject];

  [first getColor:out atPoint:input];
}
