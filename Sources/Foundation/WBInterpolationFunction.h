//
//  WBInterpolationFunction.h
//  NeoLab
//
//  Created by Jean-Daniel Dupas on 18/04/09.
//  Copyright 2009 Ninsight. All rights reserved.
//

typedef CGFloat (*WBInterpolationEvaluateCallBack)(CGFloat input, void *info);
typedef void (*WBInterpolationReleaseInfoCallBack)(void *info);

typedef struct _WBInterpolationCallBackContext {
  void *info;
  WBInterpolationEvaluateCallBack cb;
  WBInterpolationReleaseInfoCallBack releaseInfo;
} WBInterpolationCallBack;
  
WB_EXPORT const WBInterpolationCallBack const WBInterpolationCallBackSin;
WB_EXPORT const WBInterpolationCallBack const WBInterpolationCallBackCircular;

WB_EXPORT CGFloat WBInterpolationSin(CGFloat factor, void *info);
WB_EXPORT CGFloat WBInterpolationCircular(CGFloat factor, void *info);

WB_CLASS_EXPORT
@interface WBInterpolationFunction : NSObject {
@private
  
}

// Calback based
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
CGFloat WBBezierCurveEpsilonForDuration(CGFloat duration) {
  return 1.0 / (200.0 * duration);
}
