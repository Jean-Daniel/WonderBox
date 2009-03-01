/*
 *  WBQTVisualContext.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
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
- (void)setWorkingColorSpaceName:(CFStringRef)cgColorSpaceName;

- (CGColorSpaceRef)outputColorSpace;
- (void)setOutputColorSpace:(CGColorSpaceRef)aColorspace;
- (void)setOutputColorSpaceName:(CFStringRef)cgColorSpaceName;

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
