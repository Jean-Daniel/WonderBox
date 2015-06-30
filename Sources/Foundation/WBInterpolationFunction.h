/*
 *  WBInterpolationFunction.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBBase.h>

#import <Foundation/Foundation.h>

typedef CGFloat (*WBInterpolationEvaluateCallBack)(CGFloat input, void *info);
typedef void (*WBInterpolationReleaseInfoCallBack)(void *info);

typedef struct _WBInterpolationCallBackContext {
  void *info;
  WBInterpolationEvaluateCallBack cb;
  WBInterpolationReleaseInfoCallBack releaseInfo;
} WBInterpolationCallBack;

WB_EXPORT const WBInterpolationCallBack WBInterpolationCallBackSin;
WB_EXPORT const WBInterpolationCallBack WBInterpolationCallBackCircular;

WB_EXPORT CGFloat WBInterpolationSin(CGFloat factor, void *info);
WB_EXPORT CGFloat WBInterpolationCircular(CGFloat factor, void *info);

WB_OBJC_EXPORT
@interface WBInterpolationFunction : NSObject {
@private

}

+ (WBInterpolationFunction *)circularInterpolation;
+ (WBInterpolationFunction *)sinusoidalInterpolation;

// Callback based
- (id)initWithCallBack:(const WBInterpolationCallBack *)callback;

// Bezier
- (id)initWithControlPoints:(CGFloat)c1x :(CGFloat)c1y :(CGFloat)c2x :(CGFloat)c2y;
- (id)initWithControlPoints:(CGFloat)c1x :(CGFloat)c1y :(CGFloat)c2x :(CGFloat)c2y length:(CGFloat)lengthHint;

- (CGFloat)valueForInput:(CGFloat)input;

@end

#pragma mark -
#pragma mark Cubic Bezier Curve
typedef struct _WBBezierCurve {
  CGFloat ax, ay;
  CGFloat bx, by;
  CGFloat cx, cy;
  CGFloat dx, dy;
} WBBezierCurve;

WB_EXPORT
void WBBezierCurveInitialize(WBBezierCurve *curve, CGPoint p0, CGPoint c0, CGPoint c1, CGPoint p1);

WB_EXPORT
CGPoint WBBezierCurveEvaluate(const WBBezierCurve *curve, CGFloat t);

WB_EXPORT
CGFloat WBBezierCurveEvaluateX(const WBBezierCurve *curve, CGFloat t);
WB_EXPORT
CGFloat WBBezierCurveEvaluateY(const WBBezierCurve *curve, CGFloat t);

WB_EXPORT
CGFloat WBBezierCurveSolve(const WBBezierCurve *curve, CGFloat x, CGFloat epsilon);

WB_INLINE
CGFloat WBBezierCurveEpsilonForDuration(CGFloat duration) { return 1 / (200 * duration); }
