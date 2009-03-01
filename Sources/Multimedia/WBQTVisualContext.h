/*
 *  WBQTVisualContext.h
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

#include <QuickTime/QuickTime.h>

enum {
  kWBQTPixelBufferContext = 1,
  kWBQTOpenGLTextureContext,
};
typedef NSUInteger WBQTVisualContextType;

@interface WBQTVisualContext : NSObject {
@private
  id __weak wb_delegate;
  //pthread_mutex_t wb_lock;
  QTVisualContextRef wb_ctxt;
}

- (id)initWithQuickTimeContext:(QTVisualContextRef)aContext; // designated
- (id)initWithPixelBufferAttributes:(CFDictionaryRef)attributes;

- (id)initWithOpenGLContext:(CGLContextObj)aContext;
- (id)initWithOpenGLContext:(CGLContextObj)aContext pixelFormat:(CGLPixelFormatObj)aFormat attributes:(CFDictionaryRef)attrs;

- (WBQTVisualContextType)type;
- (QTVisualContextRef)quickTimeContext;

- (CFTypeRef)attributeForKey:(CFStringRef)aKey;
- (CFTypeRef)attributeForKey:(CFStringRef)aKey error:(OSStatus *)error;
- (OSStatus)setAttribute:(CFTypeRef)anAttribute forKey:(CFStringRef)aKey;

/* convenient */
- (CGColorSpaceRef)workingColorSpace;
- (void)setWorkingColorSpace:(CGColorSpaceRef)aColorspace;
// force to link on Graphic frameworks…
//- (void)setWorkingColorSpaceName:(CFStringRef)cgColorSpaceName;

- (CGColorSpaceRef)outputColorSpace;
- (void)setOutputColorSpace:(CGColorSpaceRef)aColorspace;
//- (void)setOutputColorSpaceName:(CFStringRef)cgColorSpaceName;

/* image generation */
- (BOOL)isNewImageAvailableForTime:(const CVTimeStamp *)timeStamp;
- (CVImageBufferRef)copyImageForTime:(const CVTimeStamp *)timeStamp;
- (CVImageBufferRef)copyImageForTime:(const CVTimeStamp *)timeStamp allocator:(CFAllocatorRef)allocator error:(OSStatus *)error;

- (void)task WB_OBSOLETE;
- (void)reclaimResources;

- (id)delegate;
- (void)setDelegate:(id)aDelegate;

@end

@protocol WBQTVisualContextDelegate

@required
- (void)visualContext:(WBQTVisualContext *)ctxt imageIsAvailable:(CVImageBufferRef)anImage time:(const CVTimeStamp *)timeStamp;

@end
