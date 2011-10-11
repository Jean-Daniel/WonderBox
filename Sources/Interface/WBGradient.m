/*
 *  WBGradient.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBGradient.h)
#import WBHEADER(WBCGFunctions.h)

@interface WBGradientStep : NSObject {
  uint8_t wb_cnt;
  CGFloat wb_start, wb_end;
  WBInterpolationFunction *wb_fct;
  CGFloat wb_cStart[5], wb_cEnd[5];
}

static
void _WBGradientRelease(void *info);
static
void _WBGradientDrawStep(void * info, const CGFloat * in, CGFloat * out);
static
void _WBGradientDrawSteps(void * info, const CGFloat * in, CGFloat * out);

@property(nonatomic) CGFloat start, end;
@property(nonatomic, retain) WBInterpolationFunction *interpolation;

- (id)initWithComponents:(NSUInteger)count;

- (void)setStartColor:(const CGFloat *)aColor;
- (void)setEndColor:(const CGFloat *)aColor;

@end


@interface WBInterpolationFunction (WBGradientExtensions)

+ (id)functionFromDefinition:(const WBInterpolationDefinition *)def;

@end

@implementation WBGradientBuilder

- (id)init {
  return [self initWithColorSpace:nil];
}

- (id)initWithColorSpace:(NSColorSpace *)aColorSpace {
  if (self = [super init]) {
    wb_cs = wb_retain(aColorSpace ? : [NSColorSpace genericRGBColorSpace]);
    NSUInteger count = (NSUInteger)[wb_cs numberOfColorComponents] + 1; // add one for alpha
    if (count < 2 || count > 5) {
      WBLogError(@"WBGradient: Unsupported color space: %@", wb_cs);
      wb_release(self);
      return nil;
    }
    wb_steps = [[NSMutableArray alloc] init];
  }
  return self;
}

// MARK: Helpers
- (id)initWithStartingColor:(NSColor *)startingColor endingColor:(NSColor *)endingColor {
  if (self = [self initWithColorSpace:nil]) {
    [self addStepFrom:0 color:startingColor to:1 color:endingColor interpolation:nil];
  }
  return self;
}

- (id)initWithStartingColor:(NSColor *)startingColor endingColor:(NSColor *)endingColor interpolation:(WBInterpolationFunction *)fct {
  if (self = [self initWithColorSpace:nil]) {
    [self addStepFrom:0 color:startingColor to:1 color:endingColor interpolation:fct];
  }
  return self;
}

- (id)initWithStartingColor:(NSColor *)startingColor endingColor:(NSColor *)endingColor interpolation:(WBInterpolationFunction *)fct colorSpace:(NSColorSpace *)aColorSpace {
  if (self = [self initWithColorSpace:aColorSpace]) {
    [self addStepFrom:0 color:startingColor to:1 color:endingColor interpolation:fct];
  }
  return self;
}

- (id)initWithColorSpace:(NSColorSpace *)aColorSpace definition:(const WBGradientDefinition *)def {
  if (self = [self initWithColorSpace:aColorSpace]) {
    WBInterpolationFunction *base = [WBInterpolationFunction functionFromDefinition:&def->fct];

    for (NSUInteger idx = 0; idx < def->count; idx++) {
      WBInterpolationFunction *fct;
      if (kWBInterpolationTypeDefault == def->steps[idx].fct.type)
        fct = base;
      else
        fct = [WBInterpolationFunction functionFromDefinition:&def->steps[idx].fct];

      [self addStepFrom:def->steps[idx].start components:def->steps[idx].startColor.rgba
                     to:def->steps[idx].end components:def->steps[idx].endColor.rgba
          interpolation:fct];
    }
  }
  return self;
}

- (void)dealloc {
  wb_release(wb_steps);
  wb_release(wb_cs);
  wb_dealloc();
}

#pragma mark -
- (void)wb_checkLocation:(CGFloat)start end:(CGFloat)end {
  if (start >= end)
    WBThrowException(NSInvalidArgumentException, @"invalid range. 'start' must be less than 'end'");

  if (start < 0 || start >= 1)
    WBThrowException(NSInvalidArgumentException, @"start must be in the range [0; 1[");
  if (end <= 0 || end > 1)
    WBThrowException(NSInvalidArgumentException, @"end must be in the range ]0; 1]");

  for (WBGradientStep *step in wb_steps) {
    // if (start >= step.end || end <= step.start) continue;
    if (start < step.end && end > step.start)
      WBThrowException(NSInvalidArgumentException, @"overlapping step: [%.2f; %.2f] and [%.2f; %.2f[", start, end, step.start, step.end);
  }
}

- (void)addStepFrom:(CGFloat)startLocation color:(NSColor *)startColor
                 to:(CGFloat)endLocation color:(NSColor *)endColor interpolation:(WBInterpolationFunction  *)fct {
  CGFloat start[5], end[5];
  // Start Color
  NSColor *color = [startColor colorUsingColorSpace:wb_cs];
  if (!color)
    WBThrowException(NSInvalidArgumentException, @"cannot use %@ in gradient with color space %@", startColor, wb_cs);
  [color getComponents:start];
  // End color
  color = [endColor colorUsingColorSpace:wb_cs];
  if (!color)
    WBThrowException(NSInvalidArgumentException, @"cannot use %@ in gradient with color space %@", endColor, wb_cs);
  [color getComponents:end];

  [self addStepFrom:startLocation components:start
                 to:endLocation components:end interpolation:fct];
}

- (void)addStepFrom:(CGFloat)startLocation components:(const CGFloat *)startColor
                 to:(CGFloat)endLocation components:(const CGFloat *)endColor interpolation:(WBInterpolationFunction *)fct {
  [self wb_checkLocation:startLocation end:endLocation];

  NSUInteger cnt = (NSUInteger)[wb_cs numberOfColorComponents] + 1; // + one for alpha
  WBGradientStep *step = [[WBGradientStep alloc] initWithComponents:cnt];
  [step setStartColor:startColor];
  [step setEndColor:endColor];
  step.start = startLocation;
  step.end = endLocation;
  step.interpolation = fct;
  [wb_steps addObject:step];
  wb_release(step);
}

// MARK: -
// MARK: Generator
- (CGFunctionRef)newFunction {
  if ([wb_steps count] == 0)
    WBThrowException(NSInvalidArgumentException, @"cannot create empty shading");

  size_t components = (NSUInteger)[wb_cs numberOfColorComponents] + 1; // + one for alpha
  CGFloat input_value_range [2] = { 0, 1 }; // on input, value varying in [0; 1]
  CGFloat output_value_ranges [components * 2]; // on output, color components
  for (NSUInteger idx = 0; idx < components; idx++) {
    output_value_ranges[idx * 2] = 0;
    output_value_ranges[idx * 2 + 1] = 1;
  }

  void *info = NULL;
  CGFunctionCallbacks callbacks = { 0, NULL, _WBGradientRelease };
  if ([wb_steps count] == 1) {
    info = (void *)CFRetain(WBNSToCFType([wb_steps objectAtIndex:0])); // leak: Released by _WBGradientRelease
    callbacks.evaluate = _WBGradientDrawStep;
  } else {
    info = (void *)CFRetain(WBNSToCFType([wb_steps sortedArrayUsingSelector:@selector(compare:)])); // leak: Released by _WBGradientRelease
    callbacks.evaluate = _WBGradientDrawSteps;
  }

  return CGFunctionCreate(info, 1, input_value_range, components, output_value_ranges, &callbacks);
}

// MARK: Shadings
- (CGShadingRef)newAxialShadingFrom:(CGPoint)from to:(CGPoint)to {
  CGFunctionRef fct = [self newFunction];
  CGShadingRef shading = CGShadingCreateAxial([wb_cs CGColorSpace], from, to, fct, (wb_extends & 1) != 0, (wb_extends & 2) != 0);
  CGFunctionRelease(fct);
  return shading;
}

- (CGShadingRef)newRadialShadingFrom:(CGPoint)from radius:(CGFloat)fromRadius
                                     to:(CGPoint)to radius:(CGFloat)toRadius {
  CGFunctionRef fct = [self newFunction];
  CGShadingRef shading = CGShadingCreateRadial([wb_cs CGColorSpace], from, fromRadius, to, toRadius, fct, (wb_extends & 1) != 0, (wb_extends & 2) != 0);
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

@implementation WBInterpolationFunction (WBGradientExtensions)

+ (id)functionFromDefinition:(const WBInterpolationDefinition *)def {
  if (!def) return nil;

  switch (def->type) {
    case kWBInterpolationTypeCallBack: {
      WBInterpolationCallBack cb = { NULL, def->value.cb, NULL };
      return wb_autorelease([[WBInterpolationFunction alloc] initWithCallBack:&cb]);
    }
    case kWBInterpolationTypeBezier:
      return wb_autorelease([[WBInterpolationFunction alloc] initWithControlPoints:def->value.bezier.points[0].x :def->value.bezier.points[0].y
                                                                                  :def->value.bezier.points[1].x :def->value.bezier.points[1].y
                                                                            length:def->value.bezier.length]);
  }
  return nil;
}

@end

@implementation WBGradientStep

@synthesize start = wb_start, end = wb_end;
@synthesize interpolation = wb_fct;

- (id)initWithComponents:(NSUInteger)count {
  NSParameterAssert(count > 0 && count <= 5);
  if (self = [super init]) {
    wb_cnt = (uint8_t)count;
  }
  return self;
}

- (void)dealloc {
  wb_release(wb_fct);
  wb_dealloc();
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { start: %.2f, end: %.2f }",
          self.class, self, wb_start, wb_end];
}

- (NSComparisonResult)compare:(WBGradientStep *)aStep {
  if (wb_start > aStep.start) return NSOrderedDescending;
  if (aStep.start > wb_start) return NSOrderedAscending;
  return NSOrderedSame;
}

- (void)setStartColor:(const CGFloat *)aColor {
  memcpy(wb_cStart, aColor, wb_cnt * sizeof(CGFloat));
}

- (void)setEndColor:(const CGFloat *)aColor {
  memcpy(wb_cEnd, aColor, wb_cnt * sizeof(CGFloat));
}

- (void)getColor:(CGFloat *)outColor atPoint:(CGFloat)input {
  if (input <= wb_start) {
    memcpy(outColor, wb_cStart, wb_cnt * sizeof(CGFloat));
  } else if (input >= wb_end) {
    memcpy(outColor, wb_cEnd, wb_cnt * sizeof(CGFloat));
  } else {
    // interpolate
    input = (input - wb_start) / (wb_end - wb_start);
    // clamp factor
    CGFloat factor = wb_fct ? WB_MAX(WB_MIN(1, [wb_fct valueForInput:input]), 0) : input;

    for (NSUInteger k = 0; k < wb_cnt; k++)
      *outColor++ = wb_cStart[k] - (wb_cStart[k] - wb_cEnd[k]) * factor;
  }
}

@end

void _WBGradientRelease(void *info) {
  WBCFRelease(info);
}

void _WBGradientDrawStep(void * info, const CGFloat * in, CGFloat * out) {
  WBGradientStep *step = (__bridge WBGradientStep *)info;
  [step getColor:out atPoint:*in];
}

void _WBGradientDrawSteps(void * info, const CGFloat * in, CGFloat * out) {
  NSArray *steps = WBCFToNSArray(info);

  CGFloat input = *in;
  WBGradientStep *first = nil;
  for (WBGradientStep *step in steps) {
    if (first) {
      // we already have a step, we just want to check if the next step start point overrlap.
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

