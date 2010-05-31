/*
 *  WBInterpolationFunction.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBInterpolationFunction.h)
#import WBHEADER(WBClassCluster.h)

@interface _WBInterpolationFunctionCB : WBInterpolationFunction {
@private
  WBInterpolationCallBack wb_ctxt;
}

- (id)initWithCallBack:(WBInterpolationCallBack *)callback;

- (CGFloat)valueForInput:(CGFloat)input;

@end

@interface _WBInterpolationFunctionBezier : WBInterpolationFunction {
@private
  CGFloat wb_epsilon;
  WBBezierCurve wb_curve;
}

- (id)initWithControlPoints:(CGFloat)c1x :(CGFloat)c1y :(CGFloat)c2x :(CGFloat)c2y;

- (CGFloat)valueForInput:(CGFloat)input;

@end

WBClassCluster(WBInterpolationFunction)

@implementation WBClusterPlaceholder(WBInterpolationFunction) (WBPlaceholder)

- (id)initWithCallBack:(const WBInterpolationCallBack *)callback {
  return [[_WBInterpolationFunctionCB allocWithZone:[self zone]] initWithCallBack:callback];
}

- (id)initWithControlPoints:(CGFloat)c1x :(CGFloat)c1y :(CGFloat)c2x :(CGFloat)c2y {
  return [[_WBInterpolationFunctionBezier allocWithZone:[self zone]] initWithControlPoints:c1x :c1y :c2x :c2y];
}

- (id)initWithControlPoints:(CGFloat)c1x :(CGFloat)c1y :(CGFloat)c2x :(CGFloat)c2y length:(CGFloat)lengthHint {
  return [[_WBInterpolationFunctionBezier allocWithZone:[self zone]] initWithControlPoints:c1x :c1y :c2x :c2y length:lengthHint];
}

@end

@implementation WBInterpolationFunction

+ (WBInterpolationFunction *)circularInterpolation {
  return [[[self alloc] initWithCallBack:&WBInterpolationCallBackCircular] autorelease];
}
+ (WBInterpolationFunction *)sinusoidalInterpolation {
  return [[[self alloc] initWithCallBack:&WBInterpolationCallBackSin] autorelease];
}

- (id)initWithCallBack:(const WBInterpolationCallBack *)callback {
  return [super init];
}

- (id)initWithControlPoints:(CGFloat)c1x :(CGFloat)c1y :(CGFloat)c2x :(CGFloat)c2y {
  return [super init];
}

- (id)initWithControlPoints:(CGFloat)c1x :(CGFloat)c1y :(CGFloat)c2x :(CGFloat)c2y length:(CGFloat)lengthHint {
  return [super init];
}

- (CGFloat)valueForInput:(CGFloat)input {
  return input;
}

@end

#pragma mark -
@implementation _WBInterpolationFunctionCB

- (id)initWithCallBack:(WBInterpolationCallBack *)callback {
  NSParameterAssert(callback);
  if (self = [super initWithCallBack:callback]) {
    wb_ctxt = *callback;
  }
  return self;
}

- (void)dealloc {
  if (wb_ctxt.releaseInfo)
    wb_ctxt.releaseInfo(wb_ctxt.info);
  [super dealloc];
}

- (CGFloat)valueForInput:(CGFloat)input {
  return wb_ctxt.cb ? wb_ctxt.cb(input, wb_ctxt.info) : input;
}

@end


CGFloat WBInterpolationSin(CGFloat factor, void *info) {
  CGFloat sinus = sin(M_PI_2 * factor);
  return sinus * sinus;
}

CGFloat WBInterpolationCircular(CGFloat factor, void *info) {
  return sqrt(factor * (2 - factor));
}

const WBInterpolationCallBack WBInterpolationCallBackSin = {
	NULL, WBInterpolationSin, NULL,
};
const WBInterpolationCallBack WBInterpolationCallBackCircular = {
	NULL, WBInterpolationCircular, NULL,
};

#pragma mark -
@implementation _WBInterpolationFunctionBezier

- (id)initWithControlPoints:(CGFloat)c1x :(CGFloat)c1y :(CGFloat)c2x :(CGFloat)c2y {
  return [self initWithControlPoints:c1x :c1y :c2x :c2y length:0];
}

- (id)initWithControlPoints:(CGFloat)c1x :(CGFloat)c1y :(CGFloat)c2x :(CGFloat)c2y length:(CGFloat)lengthHint {
  if (self = [super initWithControlPoints:c1x :c1y :c2x :c2y length:lengthHint]) {
    wb_epsilon = WBBezierCurveEpsilonForDuration(lengthHint > 0 ? lengthHint : 10);
    WBBezierCurveInitialize(&wb_curve, CGPointZero, CGPointMake(c1x, c1y), CGPointMake(c2x, c2y), CGPointMake(1, 1));
  }
  return [super init];
}

- (CGFloat)valueForInput:(CGFloat)input {
  return WBBezierCurveSolve(&wb_curve, input, wb_epsilon);
}

@end

#pragma mark -
#pragma mark Bezier Implementation
/*
 B(t) = (1-t)^3 p0 + 3t(1-t)^2 c0 + 3t^2(1-t) c1 + t^3 p1
 B(t) = (p1 - p0 + 3c0 - 3c1)t^3 + (3p0 - 6c0 + 3c1)t^2 + (3c0 - 3p0)t + p0
 */
void WBBezierCurveInitialize(WBBezierCurve *curve, CGPoint p0, CGPoint c0, CGPoint c1, CGPoint p1) {
  curve->ax = p1.x - p0.x + 3 * c0.x - 3 * c1.x;
  curve->ay = p1.y - p0.y + 3 * c0.y - 3 * c1.y;

  curve->bx = 3 * p0.x - 6 * c0.x + 3 * c1.x;
  curve->by = 3 * p0.y - 6 * c0.y + 3 * c1.y;

  curve->cx = 3 * c0.x - 3 * p0.x;
  curve->cy = 3 * c0.y - 3 * p0.y;

  curve->dx = p0.x;
  curve->dy = p0.y;
}


WB_INLINE
CGFloat __WBBezierCurveEvaluateX(const WBBezierCurve *c, CGFloat t) {
  return ((c->ax * t + c->bx) * t + c->cx) * t + c->dx;
}

WB_INLINE
CGFloat __WBBezierCurveEvaluateY(const WBBezierCurve *c, CGFloat t) {
  return ((c->ay * t + c->by) * t + c->cy) * t + c->dy;
}

WB_INLINE
CGFloat __WBBezierCurveDerivativeX(const WBBezierCurve *c, CGFloat t) {
  return (3 * c->ax * t + 2 * c->bx) * t + c->cx;
}

static
CGFloat _WBBezierCurveSolveT(const WBBezierCurve *curve, CGFloat x, CGFloat epsilon) {
  CGFloat t0, t1, t2;
  CGFloat x2;
  CGFloat d2;

  int i;
  // First try a few iterations of Newton's method -- normally very fast.
  for (t2 = x, i = 0; i < 8; i++) {
    x2 = __WBBezierCurveEvaluateX(curve, t2) - x;
    if (fabs(x2) < epsilon)
      return t2;
    d2 = __WBBezierCurveDerivativeX(curve, t2);
    if (fabs(d2) < 1e-6)
      break;
    t2 = t2 - x2 / d2;
  }

  // Fall back to the bisection method for reliability.
  t0 = 0.0;
  t1 = 1.0;
  t2 = x;

  if (t2 < t0)
    return t0;
  if (t2 > t1)
    return t1;

  while (t0 < t1) {
    x2 = __WBBezierCurveEvaluateX(curve, t2);
    if (fabs(x2 - x) < epsilon)
      return t2;
    if (x > x2)
      t0 = t2;
    else
      t1 = t2;
    t2 = (t1 - t0) * .5 + t0;
  }

  // Failure.
  return t2;
}

CGPoint WBBezierCurveEvaluate(const WBBezierCurve *curve, CGFloat t) {
  return CGPointMake(__WBBezierCurveEvaluateX(curve, t), __WBBezierCurveEvaluateY(curve, t));
}

CGFloat WBBezierCurveEvaluateX(const WBBezierCurve *c, CGFloat t) {
  return __WBBezierCurveEvaluateX(c, t);
}

CGFloat WBBezierCurveEvaluateY(const WBBezierCurve *c, CGFloat t) {
  return __WBBezierCurveEvaluateY(c, t);
}

CGFloat WBBezierCurveSolve(const WBBezierCurve *curve, CGFloat x, CGFloat epsilon) {
  return __WBBezierCurveEvaluateY(curve, _WBBezierCurveSolveT(curve, x, epsilon));
}
